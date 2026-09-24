import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/locale_provider.dart';
import 'package:jameia_mart/src/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:jameia_mart/src/features/checkout/data/datasources/delivery_remote_data_source.dart';
import 'package:jameia_mart/src/features/checkout/data/mappers/checkout_mapper.dart';

import '../../core/network/network_test_fakes.dart';
import '../orders/order_test_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  DeliveryRemoteDataSourceImpl buildDelivery(
    FakeHttpClientAdapter transport, {
    String language = 'en',
  }) {
    adapter = transport;
    return DeliveryRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
      FakeLocaleProvider(language),
    );
  }

  RequestOptions request() => adapter.requests.single;
  Map<String, dynamic> body() =>
      jsonDecode(jsonEncode(request().data)) as Map<String, dynamic>;

  test('getBranches reads data[] and keeps the services flags', () async {
    final dataSource = buildDelivery(
      FakeHttpClientAdapter(
        (_, _) => okBody(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'b1',
              'name': 'Salmiya',
              'code': 'SLM',
              'address': 'Block 3',
              'lat': 29.33,
              'lng': 48.07,
              'services': <String, dynamic>{
                'delivery': true,
                'pickup': true,
                'express': false,
              },
              'minOrder': 2000,
              'etaMinutes': 40,
            },
            <String, dynamic>{'name': 'no id'}, // skipped
          ],
        }),
      ),
    );

    final branches = (await dataSource.getBranches()).toEntities();

    expect(request().path, '/v1/delivery/branches');
    expect(branches, hasLength(1));
    expect(branches.single.supportsPickup, isTrue);
    expect(branches.single.supportsExpress, isFalse);
    expect(branches.single.location?.lng, 48.07);
    expect(branches.single.minOrderKd, 2.0);
  });

  test('getSlots groups the windows by day', () async {
    final dataSource = buildDelivery(
      FakeHttpClientAdapter(
        (_, _) => okBody(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'date': '2026-09-22',
              'label': 'Tomorrow',
              'slots': <Map<String, dynamic>>[
                <String, dynamic>{
                  'templateId': 't1',
                  'date': '2026-09-22',
                  'start': '10:00',
                  'end': '12:00',
                  'label': '10:00 – 12:00',
                  'capacity': 10,
                  'booked': 8,
                  'remaining': 2,
                  'available': true,
                },
                <String, dynamic>{
                  'templateId': 't2',
                  'date': '2026-09-22',
                  'remaining': 0,
                  'available': false,
                },
              ],
            },
          ],
        }),
      ),
    );

    final days = (await dataSource.getSlots()).toEntities();

    expect(request().path, '/v1/delivery/slots');
    expect(days.single.slots, hasLength(2));
    expect(days.single.hasBookableSlot, isTrue);
    expect(days.single.slots.first.isSelectable, isTrue);
    expect(days.single.slots.last.isBookable, isFalse);
  });

  test('select-address POSTs the address and returns the pricing', () async {
    final dataSource = buildDelivery(
      FakeHttpClientAdapter(
        (_, _) => okBody(<String, dynamic>{
          'mode': 'delivery',
          'addressId': 'a1',
          'addressLabel': 'Home',
          'branchId': 'b1',
          'branchName': 'Salmiya',
          'zoneId': 'z1',
          'zoneName': 'Block 3',
          'deliveryFee': 500,
          'minOrder': 2000,
          'etaMinutes': 45,
        }),
      ),
    );

    final selection = (await dataSource.selectAddress('a1')).toEntity();

    expect(request().method, 'POST');
    expect(request().path, '/v1/delivery/select-address');
    expect(body()['addressId'], 'a1');
    expect(selection.isPickup, isFalse);
    expect(selection.deliveryFeeKd, 0.5);
    expect(selection.zoneName, 'Block 3');
  });

  test('select-branch POSTs the branch and comes back as pickup', () async {
    final dataSource = buildDelivery(
      FakeHttpClientAdapter(
        (_, _) => okBody(<String, dynamic>{
          'mode': 'pickup',
          'branchId': 'b1',
          'branchName': 'Salmiya',
          'address': 'Block 3, Street 1',
          'deliveryFee': 0,
          'minOrder': 0,
          'etaMinutes': 20,
        }),
      ),
    );

    final selection = (await dataSource.selectBranch('b1')).toEntity();

    expect(request().path, '/v1/delivery/select-branch');
    expect(body()['branchId'], 'b1');
    expect(selection.isPickup, isTrue);
    expect(selection.branchAddress, 'Block 3, Street 1');
  });

  test(
    'placeOrder POSTs the body to /v1/orders and parses the order',
    () async {
      adapter = FakeHttpClientAdapter((_, _) => okBody(orderJson()));
      final dataSource = CheckoutRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );

      final order = await dataSource.placeOrder(<String, dynamic>{
        'paymentMethod': 'cod',
      });

      expect(request().method, 'POST');
      expect(request().path, '/v1/orders');
      expect(body()['paymentMethod'], 'cod');
      expect(order.orderNumber, 'JM-1001');
    },
  );

  test('branches are cached per language and re-read after a switch', () async {
    var calls = 0;
    final transport = FakeHttpClientAdapter((_, _) {
      calls++;
      return okBody(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'_id': 'b1', 'name': 'Salmiya'},
        ],
      });
    });
    final locale = _MutableLocale('en');
    final dataSource = DeliveryRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
      locale,
    );

    await dataSource.getBranches();
    await dataSource.getBranches();
    expect(calls, 1, reason: 'the second open reads the cached rows');

    locale.languageCode = 'ar';
    await dataSource.getBranches();
    expect(calls, 2, reason: 'names are resolved by Accept-Language');
  });

  test('branches are re-read once the cache window passed', () async {
    var calls = 0;
    var now = DateTime(2026);
    final transport = FakeHttpClientAdapter((_, _) {
      calls++;
      return okBody(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'_id': 'b1', 'name': 'Salmiya'},
        ],
      });
    });
    final dataSource = DeliveryRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
      FakeLocaleProvider('en'),
      now: () => now,
    );

    await dataSource.getBranches();
    now = now.add(DeliveryRemoteDataSourceImpl.branchesTtl * 2);
    await dataSource.getBranches();

    expect(calls, 2);
  });
}

class _MutableLocale implements LocaleProvider {
  _MutableLocale(this.languageCode);

  @override
  String languageCode;
}
