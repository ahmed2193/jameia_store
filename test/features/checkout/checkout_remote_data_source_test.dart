// `GET /v1/init` → the store rules checkout obeys, parsed from the live
// shape (`node .claude/skills/hero-api-integration/scripts/openapi_route.js
// init`): store fields only, cached per language for a few minutes.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:hero_mart/src/features/checkout/data/mappers/store_rules_mapper.dart';
import 'package:hero_mart/src/features/checkout/data/models/store_rules_model.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';

import '../../core/network/network_test_fakes.dart';

Map<String, dynamic> _init({
  String name = 'Hero',
  bool codEnabled = true,
  String? defaultMethod = 'cod',
  bool maintenance = false,
  bool withUser = true,
}) => <String, dynamic>{
  'store': <String, dynamic>{
    'name': name,
    'tagline': 'Your co-op',
    'maintenanceMode': maintenance,
    'maintenanceMessage': maintenance ? 'Back at 6 PM' : '',
    'payment': <String, dynamic>{
      'codEnabled': codEnabled,
      'onlinePaymentsEnabled': false,
      'defaultMethod': ?defaultMethod,
    },
    'loyalty': <String, dynamic>{
      'enabled': true,
      'pointsPerKwd': 10,
      'redemptionPerPoint': 1,
      'minRedeemPoints': 100,
      'pointsExpireMonths': 12,
      'welcomeBonusPoints': 100,
      'profileBonusPoints': 50,
    },
    'pro': <String, dynamic>{
      'enabled': true,
      'perks': <String, dynamic>{
        'freeDelivery': true,
        'pointsMultiplier': 2,
        'discountPercent': 5,
      },
    },
  },
  'user': withUser
      ? <String, dynamic>{
          '_id': 'c1',
          'wallet': 4500,
          'loyaltyPoints': 900,
          'pro': <String, dynamic>{'active': true},
        }
      : null,
  'cart': <String, dynamic>{'offers': <Object?>[]},
};

class _Clock {
  DateTime now = DateTime(2026, 9, 26, 10);
  DateTime call() => now;
}

void main() {
  late FakeHttpClientAdapter adapter;

  CheckoutRemoteDataSourceImpl build(
    FakeHttpClientAdapter transport, {
    FakeLocaleProvider? locale,
    _Clock? clock,
  }) {
    adapter = transport;
    return CheckoutRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
      locale ?? FakeLocaleProvider('en'),
      now: clock?.call,
    );
  }

  test('GET /v1/init → the store rules', () async {
    final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(_init())));

    final rules = (await dataSource.getStoreRules()).toEntity();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/v1/init');
    expect(rules.storeName, 'Hero');
    expect(rules.codEnabled, isTrue);
    expect(rules.defaultPaymentMethod, OrderPaymentMethod.cod);
    expect(rules.loyalty.enabled, isTrue);
    expect(rules.loyalty.minRedeemPoints, 100);
    expect(rules.loyalty.redemptionPerPoint, 1);
    expect(rules.proFreeDelivery, isTrue);
    expect(rules.maintenance, isFalse);
  });

  test('cash off, maintenance and its message are read', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody(_init(codEnabled: false, maintenance: true)),
      ),
    );

    final rules = (await dataSource.getStoreRules()).toEntity();

    expect(rules.codEnabled, isFalse);
    expect(rules.maintenance, isTrue);
    expect(rules.maintenanceMessage, 'Back at 6 PM');
  });

  test('a default method the order route does not take means cash', () {
    final rules = StoreRulesModel.fromInitJson(_init(defaultMethod: 'knet'))
        .toEntity();

    expect(rules.defaultPaymentMethod, OrderPaymentMethod.cod);
    expect(
      StoreRulesModel.fromInitJson(_init(defaultMethod: 'wallet'))
          .toEntity()
          .defaultPaymentMethod,
      OrderPaymentMethod.wallet,
    );
  });

  test('missing blocks fall back to the defaults', () {
    expect(
      StoreRulesModel.fromInitJson(const <String, dynamic>{}).toEntity(),
      CheckoutStoreRules.unknown,
    );
    final bare = StoreRulesModel.fromInitJson(const <String, dynamic>{
      'store': <String, dynamic>{'name': 'Hero'},
    }).toEntity();
    expect(bare.storeName, 'Hero');
    expect(bare.codEnabled, isTrue);
    expect(bare.proFreeDelivery, isFalse);
    expect(bare.loyalty.enabled, isFalse);
  });

  test('no user.* field is kept (the session owns them)', () {
    final withUser = StoreRulesModel.fromInitJson(_init()).toEntity();
    final guest = StoreRulesModel.fromInitJson(_init(withUser: false))
        .toEntity();

    expect(withUser, guest);
  });

  test('cached per language for 5 minutes', () async {
    var calls = 0;
    final locale = FakeLocaleProvider('en');
    final clock = _Clock();
    final dataSource = build(
      FakeHttpClientAdapter((_, _) {
        calls++;
        return okBody(_init(name: calls.isOdd ? 'Hero' : 'جميعة'));
      }),
      locale: locale,
      clock: clock,
    );

    await dataSource.getStoreRules();
    await dataSource.getStoreRules();
    expect(calls, 1, reason: 'the second open reads the cached rules');

    locale.languageCode = 'ar';
    final arabic = await dataSource.getStoreRules();
    expect(calls, 2, reason: 'the store name is localized');
    expect(arabic.storeName, 'جميعة');

    clock.now = clock.now.add(CheckoutRemoteDataSourceImpl.rulesTtl);
    await dataSource.getStoreRules();
    expect(calls, 3, reason: 'the cache lasts 5 minutes');
  });
}
