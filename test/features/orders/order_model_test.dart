import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';

import 'order_test_fixtures.dart';

void main() {
  group('OrderModel.fromJson', () {
    test('reads the order and maps it to the entity', () {
      final order = OrderModel.fromJson(orderJson()).toEntity();

      expect(order.id, 'o1');
      expect(order.orderNumber, 'JM-1001');
      expect(order.status, OrderStatus.placed);
      expect(order.isPickup, isFalse);
      expect(order.branch?.nameFor('ar'), 'السالمية');
      expect(order.address?.summary, 'Salmiya, 3, 12, 7');
      expect(order.address?.location?.lat, 29.33);
      expect(order.lines.single.nameFor('en'), 'Basmati rice');
      expect(order.itemCount, 2);
      expect(order.totalKd, 3.5);
      expect(order.payment.method, OrderPaymentMethod.cod);
      expect(order.loyalty.pointsEarned, 35);
    });

    test('reads who placed it; a nameless or missing customer is none', () {
      Map<String, dynamic> withCustomer(Object? customer) =>
          orderJson()..['customer'] = customer;

      final customer = OrderModel.fromJson(
        withCustomer(const <String, dynamic>{
          'name': 'Ahmed Al-Fahad',
          'phone': '+96550001111',
          'email': 'ahmed@example.com',
        }),
      ).toEntity().customer;
      expect(customer?.name, 'Ahmed Al-Fahad');
      expect(customer?.phone, '+96550001111');
      expect(customer?.email, 'ahmed@example.com');

      expect(
        OrderModel.fromJson(
          withCustomer(const <String, dynamic>{'name': '  ', 'phone': '1'}),
        ).toEntity().customer,
        isNull,
      );
      expect(
        OrderModel.fromJson(withCustomer('Ahmed')).toEntity().customer,
        isNull,
      );
      expect(OrderModel.fromJson(orderJson()).toEntity().customer, isNull);
    });

    test('drops a timeline row without a date, keeps the rest', () {
      final order = OrderModel.fromJson(orderJson()).toEntity();

      expect(order.statusTimeline, hasLength(1));
      expect(order.statusTimeline.single.status, OrderStatus.placed);
    });

    test('throws without an id or an order number', () {
      expect(
        () => OrderModel.fromJson(const <String, dynamic>{'status': 'placed'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('an unknown status maps to `other` and is not terminal', () {
      final order = OrderModel.fromJson(orderJson(status: 'teleporting'))
          .toEntity();

      expect(order.status, OrderStatus.other);
      expect(order.isTerminal, isFalse);
      expect(order.canCancel, isFalse);
      expect(order.group, OrderStatusGroup.inProgress);
    });

    test('a staff cancellation reason outside the app maps to `other`', () {
      final order = OrderModel.fromJson(
        orderJson(
          status: 'cancelled',
          cancellation: <String, dynamic>{
            'reason': 'fraud_suspected',
            'cancelledBy': 'staff',
            'cancelledAt': '2026-09-21T10:00:00.000Z',
            'note': 'flagged',
          },
        ),
      ).toEntity();

      expect(order.cancellation?.reason, OrderCancellationReason.other);
      expect(order.cancellation?.cancelledBy, OrderCancelledBy.staff);
      expect(order.cancellation?.byCustomer, isFalse);
      expect(order.group, OrderStatusGroup.cancelled);
    });

    test('picking and delivery details come through', () {
      final order = OrderModel.fromJson(
        orderJson(
          status: 'out_for_delivery',
          picking: <String, dynamic>{
            'picker': <String, dynamic>{'_id': 'u1', 'name': 'Sara'},
            'startedAt': '2026-09-21T09:05:00.000Z',
            'unavailableLines': <Map<String, dynamic>>[
              <String, dynamic>{'lineKey': 'l9'},
            ],
            'substitutedLines': <Map<String, dynamic>>[
              <String, dynamic>{
                'lineKey': 'l1',
                'product': <String, dynamic>{
                  'name': <String, dynamic>{'en': 'Jasmine rice', 'ar': 'أرز'},
                },
              },
            ],
          },
          delivery: <String, dynamic>{
            'driver': <String, dynamic>{'_id': 'd1', 'name': 'Ali'},
            'pickedUpAt': '2026-09-21T09:30:00.000Z',
            'attempts': <Map<String, dynamic>>[
              <String, dynamic>{
                'at': '2026-09-21T10:00:00.000Z',
                'outcome': 'failed',
              },
            ],
            'lastFailureReason': 'customer_absent',
          },
        ),
      ).toEntity();

      expect(order.picking?.pickerName, 'Sara');
      expect(order.picking?.hasChanges, isTrue);
      expect(order.picking?.unavailableLineKeys, <String>['l9']);
      expect(
        order.picking?.substitutions.single.productNameFor('en'),
        'Jasmine rice',
      );
      expect(order.delivery?.driverName, 'Ali');
      expect(order.delivery?.hasFailure, isTrue);
      expect(
        order.delivery?.lastFailureReason,
        DeliveryFailureReason.customerAbsent,
      );
    });

    test('reorderItems carries every paid line with its variant', () {
      final order = OrderModel.fromJson(
        orderJson(
          lines: <Map<String, dynamic>>[
            orderLineJson(),
            orderLineJson(
              key: 'l2',
              productId: 'p2',
              variantId: 'v1',
              quantity: 1,
            ),
          ],
        ),
      ).toEntity();

      final items = order.reorderItems;

      expect(items, hasLength(2));
      expect(items.last.productId, 'p2');
      expect(items.last.variantId, 'v1');
      expect(items.last.quantity, 1);
      // The reorder flight carries the first paid line's photo.
      expect(order.reorderImage, order.lines.first.image);
      expect(
        OrderModel.fromJson(orderJson(lines: const <Map<String, dynamic>>[]))
            .toEntity()
            .reorderImage,
        isEmpty,
      );
    });

    test('the status decides cancel, review and the tracking step', () {
      OrderModel placed(String status) =>
          OrderModel.fromJson(orderJson(status: status));

      expect(placed('confirmed').toEntity().canCancel, isTrue);
      expect(placed('ready').toEntity().canCancel, isFalse);
      expect(placed('delivered').toEntity().canReview, isTrue);
      expect(placed('delivered').toEntity().isTerminal, isTrue);
      expect(placed('out_for_delivery').toEntity().progressStep, 4);
      expect(placed('cancelled').toEntity().progressStep, isNull);
    });
  });
}
