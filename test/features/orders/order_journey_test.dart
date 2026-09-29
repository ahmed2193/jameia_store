import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_fulfillment_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_progress_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_eta.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_journey.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_line_changes.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_timeline.dart';

OrderEntity _order(
  OrderStatus status, {
  FulfillmentMode mode = FulfillmentMode.delivery,
  OrderPickingEntity? picking,
  OrderDeliveryEntity? delivery,
  OrderCancellationEntity? cancellation,
  OrderDeliverySlotEntity? slot,
  int? etaMinutes = 40,
  DateTime? createdAt,
  List<OrderStatusEvent> timeline = const [],
  OrderPlaceEntity? branch,
}) => OrderEntity(
  id: 'o1',
  orderNumber: 'HX-1',
  status: status,
  fulfillmentMode: mode,
  picking: picking,
  delivery: delivery,
  cancellation: cancellation,
  deliverySlot: slot,
  etaMinutes: etaMinutes,
  createdAt: createdAt ?? DateTime(2026, 9, 28, 20, 2),
  statusTimeline: timeline,
  branch: branch,
);

void main() {
  group('OrderJourney', () {
    test('placed and confirmed are the received stage, in progress', () {
      for (final status in [OrderStatus.placed, OrderStatus.confirmed]) {
        final journey = OrderJourney.of(_order(status));
        expect(journey.stage, OrderStage.received);
        expect(journey.inProgress, isTrue);
        expect(journey.filledSegments, 0);
      }
      expect(
        OrderJourney.of(_order(OrderStatus.confirmed)).headlineKey,
        'orders.journey_confirmed',
      );
    });

    test('picking names the picker when there is one', () {
      final anonymous = OrderJourney.of(_order(OrderStatus.picking));
      expect(anonymous.stage, OrderStage.packing);
      expect(anonymous.detailKey, 'orders.journey_packing_detail');
      expect(anonymous.detailName, isEmpty);

      final named = OrderJourney.of(
        _order(
          OrderStatus.picking,
          picking: const OrderPickingEntity(pickerName: 'Ahmed'),
        ),
      );
      expect(named.detailKey, 'orders.journey_packing_by');
      expect(named.detailName, 'Ahmed');
      expect(named.filledSegments, 1);
    });

    test('ready: packed and waiting (delivery), ready for pickup (pickup)', () {
      final delivery = OrderJourney.of(_order(OrderStatus.ready));
      expect(delivery.stage, OrderStage.packing);
      expect(delivery.stageComplete, isTrue);
      expect(delivery.inProgress, isFalse);
      expect(delivery.filledSegments, 2);
      expect(delivery.headlineKey, 'orders.journey_packed');

      final pickup = OrderJourney.of(
        _order(
          OrderStatus.ready,
          mode: FulfillmentMode.pickup,
          branch: const OrderPlaceEntity(id: 'b1', nameEn: 'Salmiya'),
        ),
      );
      expect(pickup.stage, OrderStage.onTheWay);
      expect(pickup.headlineKey, 'orders.journey_ready_pickup');
      expect(pickup.detailKey, 'orders.journey_ready_pickup_at');
      expect(pickup.stageLabelKey, 'orders.stage_ready_pickup');
      expect(pickup.pickup, isTrue);
    });

    test('out for delivery names the driver', () {
      final journey = OrderJourney.of(
        _order(
          OrderStatus.outForDelivery,
          delivery: const OrderDeliveryEntity(driverName: 'Khaled'),
        ),
      );
      expect(journey.stage, OrderStage.onTheWay);
      expect(journey.detailKey, 'orders.journey_on_the_way_by');
      expect(journey.detailName, 'Khaled');
      expect(journey.filledSegments, 2);
      expect(journey.stageLabelKey, 'orders.stage_on_the_way');
    });

    test('delivered fills every segment; a pickup order is picked up', () {
      final delivered = OrderJourney.of(_order(OrderStatus.delivered));
      expect(delivered.tone, OrderJourneyTone.done);
      expect(delivered.filledSegments, OrderJourney.stageCount);
      expect(delivered.inProgress, isFalse);
      expect(delivered.headlineKey, 'orders.journey_delivered');

      final pickedUp = OrderJourney.of(
        _order(OrderStatus.delivered, mode: FulfillmentMode.pickup),
      );
      expect(pickedUp.headlineKey, 'orders.journey_picked_up');
      expect(pickedUp.stageLabelKey, 'orders.stage_picked_up');
    });

    test('a failed delivery asks for attention with its reason', () {
      final journey = OrderJourney.of(
        _order(
          OrderStatus.deliveryFailed,
          delivery: const OrderDeliveryEntity(
            lastFailureReason: DeliveryFailureReason.customerAbsent,
          ),
        ),
      );
      expect(journey.tone, OrderJourneyTone.attention);
      expect(journey.stage, OrderStage.onTheWay);
      expect(journey.inProgress, isFalse);
      // The stage it stopped at is marked, in the attention colour.
      expect(journey.filledSegments, 3);
      expect(journey.detailReasonKey, 'orders.failure_customer_absent');
    });

    test('cancelled leaves the journey and says who cancelled', () {
      final byYou = OrderJourney.of(
        _order(
          OrderStatus.cancelled,
          cancellation: const OrderCancellationEntity(
            cancelledBy: OrderCancelledBy.customer,
          ),
        ),
      );
      expect(byYou.isOnJourney, isFalse);
      expect(byYou.stageIndex, isNull);
      expect(byYou.filledSegments, 0);
      expect(byYou.detailKey, 'orders.cancelled_by_you');

      final byStore = OrderJourney.of(_order(OrderStatus.cancelled));
      expect(byStore.detailKey, 'orders.cancelled_by_store');
      expect(byStore.tone, OrderJourneyTone.stopped);
    });
  });

  group('OrderEta', () {
    final placed = DateTime(2026, 9, 28, 20, 2);

    test('the estimate is rounded up and counted down against now', () {
      final order = _order(OrderStatus.picking, createdAt: placed);
      // 20:02 + 40 min = 20:42 → 20:45.
      final early = OrderEta.of(order, DateTime(2026, 9, 28, 20, 10));
      expect(early.kind, OrderEtaKind.arriving);
      expect(early.at, DateTime(2026, 9, 28, 20, 45));
      expect(early.minutesLeft, 35);

      final close = OrderEta.of(order, DateTime(2026, 9, 28, 20, 44, 30));
      expect(close.minutesLeft, 1);
    });

    test('past the estimate and still moving: late', () {
      final eta = OrderEta.of(
        _order(OrderStatus.outForDelivery, createdAt: placed),
        DateTime(2026, 9, 28, 20, 50),
      );
      expect(eta.kind, OrderEtaKind.late);
      expect(eta.isLate, isTrue);
      expect(eta.at, DateTime(2026, 9, 28, 20, 45));
      expect(eta.minutesLeft, isNull);
    });

    test('a booked window wins over the estimate', () {
      const slot = OrderDeliverySlotEntity(
        templateId: 't1',
        date: '2026-09-29',
        start: '18:00',
        end: '19:00',
      );
      final eta = OrderEta.of(
        _order(OrderStatus.confirmed, slot: slot),
        DateTime(2026, 9, 28, 21),
      );
      expect(eta.kind, OrderEtaKind.window);
      expect(eta.slot, slot);
    });

    test('pickup: ready around; nothing left once it is ready', () {
      final packing = OrderEta.of(
        _order(
          OrderStatus.picking,
          mode: FulfillmentMode.pickup,
          createdAt: placed,
        ),
        DateTime(2026, 9, 28, 20, 10),
      );
      expect(packing.kind, OrderEtaKind.readyAround);

      final ready = OrderEta.of(
        _order(
          OrderStatus.ready,
          mode: FulfillmentMode.pickup,
          createdAt: placed,
        ),
        DateTime(2026, 9, 28, 20, 10),
      );
      expect(ready.kind, OrderEtaKind.none);
    });

    test('delivered: when, and how long it took', () {
      final eta = OrderEta.of(
        _order(
          OrderStatus.delivered,
          createdAt: placed,
          delivery: OrderDeliveryEntity(
            deliveredAt: DateTime(2026, 9, 28, 20, 41),
          ),
        ),
        DateTime(2026, 9, 28, 22),
      );
      expect(eta.kind, OrderEtaKind.delivered);
      expect(eta.at, DateTime(2026, 9, 28, 20, 41));
      expect(eta.took, const Duration(minutes: 39));
    });

    test('delivered without a delivery block falls back to the timeline', () {
      final at = DateTime(2026, 9, 28, 20, 38);
      final eta = OrderEta.of(
        _order(
          OrderStatus.delivered,
          createdAt: placed,
          timeline: [
            OrderStatusEvent(at: placed, status: OrderStatus.placed),
            OrderStatusEvent(at: at, status: OrderStatus.delivered),
          ],
        ),
        DateTime(2026, 9, 28, 22),
      );
      expect(eta.at, at);
    });

    test('cancelled: when; no estimate or no time: nothing', () {
      final cancelledAt = DateTime(2026, 9, 28, 20, 5);
      expect(
        OrderEta.of(
          _order(
            OrderStatus.cancelled,
            cancellation: OrderCancellationEntity(cancelledAt: cancelledAt),
          ),
          DateTime(2026, 9, 28, 21),
        ),
        OrderEta(kind: OrderEtaKind.cancelled, at: cancelledAt),
      );
      expect(
        OrderEta.of(
          _order(OrderStatus.placed, etaMinutes: null),
          DateTime(2026, 9, 28, 21),
        ),
        OrderEta.none,
      );
      expect(
        OrderEta.of(
          _order(OrderStatus.deliveryFailed),
          DateTime(2026, 9, 28, 21),
        ),
        OrderEta.none,
      );
    });

    test('roundUp keeps a time on the boundary, lifts any other', () {
      expect(
        OrderEta.roundUp(DateTime(2026, 1, 1, 8, 45)),
        DateTime(2026, 1, 1, 8, 45),
      );
      expect(
        OrderEta.roundUp(DateTime(2026, 1, 1, 8, 45, 1)),
        DateTime(2026, 1, 1, 8, 50),
      );
      expect(
        OrderEta.roundUp(DateTime(2026, 1, 1, 8, 58)),
        DateTime(2026, 1, 1, 9),
      );
    });
  });

  group('OrderTimeline', () {
    test('oldest first, repeats told once, unknown statuses left out', () {
      final t0 = DateTime(2026, 9, 28, 20);
      final timeline = OrderTimeline.of(
        _order(
          OrderStatus.picking,
          timeline: [
            OrderStatusEvent(
              at: t0.add(const Duration(minutes: 5)),
              status: OrderStatus.picking,
            ),
            OrderStatusEvent(at: t0, status: OrderStatus.placed),
            OrderStatusEvent(
              at: t0.add(const Duration(minutes: 1)),
              status: OrderStatus.confirmed,
            ),
            OrderStatusEvent(
              at: t0.add(const Duration(minutes: 2)),
              status: OrderStatus.confirmed,
            ),
            OrderStatusEvent(
              at: t0.add(const Duration(minutes: 3)),
              status: OrderStatus.other,
            ),
          ],
        ),
      );
      expect(timeline.events.map((event) => event.status), [
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.picking,
      ]);
      expect(timeline.events[1].at, t0.add(const Duration(minutes: 1)));
    });
  });

  group('OrderLineChanges', () {
    test('marks unavailable and substituted lines by key', () {
      final changes = OrderLineChanges.of(
        const OrderPickingEntity(
          unavailableLineKeys: ['l1', 'l2'],
          substitutions: [
            OrderSubstitutionEntity(lineKey: 'l2', productNameEn: 'Oat milk'),
          ],
        ),
      );
      expect(changes.outcomeOf('l1'), OrderLineOutcome.unavailable);
      expect(changes.outcomeOf('l2'), OrderLineOutcome.substituted);
      expect(changes.substitutionOf('l2')?.productNameEn, 'Oat milk');
      expect(changes.outcomeOf('l3'), OrderLineOutcome.kept);
      expect(changes.isEmpty, isFalse);
    });

    test('no picking, or picking without changes: nothing', () {
      expect(OrderLineChanges.of(null), OrderLineChanges.empty);
      expect(
        OrderLineChanges.of(const OrderPickingEntity(pickerName: 'A')),
        OrderLineChanges.empty,
      );
      expect(OrderLineChanges.empty.isEmpty, isTrue);
    });
  });
}
