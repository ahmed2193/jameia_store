// The checkout repositories: DTO → entity per method, and every
// AppException a datasource throws mapped to its Failure (never thrown on).
// Plus the rail datasource's short cache and in-flight sharing.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/models/loyalty_program_model.dart';
import 'package:jameia_mart/src/core/data/models/offer_model.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/data/datasources/checkout_rail_data_source.dart';
import 'package:jameia_mart/src/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:jameia_mart/src/features/checkout/data/datasources/delivery_remote_data_source.dart';
import 'package:jameia_mart/src/features/checkout/data/models/branch_model.dart';
import 'package:jameia_mart/src/features/checkout/data/models/delivery_selection_model.dart';
import 'package:jameia_mart/src/features/checkout/data/models/delivery_slot_model.dart';
import 'package:jameia_mart/src/features/checkout/data/models/store_rules_model.dart';
import 'package:jameia_mart/src/features/checkout/data/repositories/checkout_catalog_repository_impl.dart';
import 'package:jameia_mart/src/features/checkout/data/repositories/checkout_repository_impl.dart';

import '../../core/data/catalog_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';

/// What a datasource throws for the failure table.
const Map<String, (AppException, Type)> _thrown = {
  'a server refusal': (
    ServerException('nope', statusCode: 500, code: 'SERVER_ERROR'),
    ServerFailure,
  ),
  'no connection': (NoInternetConnectionException(), NetworkFailure),
  'an unreadable payload': (ParsingException(), ParsingFailure),
};

class _Checkout implements CheckoutRemoteDataSource {
  AppException? error;

  @override
  Future<StoreRulesModel> getStoreRules() async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return const StoreRulesModel(
      storeName: 'Jm3eia',
      codEnabled: false,
      defaultMethod: 'wallet',
      loyalty: LoyaltyProgramModel(
        enabled: true,
        redemptionPerPoint: 1,
        minRedeemPoints: 100,
      ),
      proFreeDelivery: true,
      maintenanceMode: true,
      maintenanceMessage: 'Back soon',
    );
  }

  @override
  Future<OrderModel> placeOrder(Map<String, dynamic> body) =>
      throw UnimplementedError();
}

class _Delivery implements DeliveryRemoteDataSource {
  AppException? error;

  Never _throw() => throw error!;

  @override
  Future<List<BranchModel>> getBranches() async {
    if (error != null) _throw();
    return const <BranchModel>[
      BranchModel(id: 'b1', name: 'Salmiya', pickup: true),
    ];
  }

  @override
  Future<List<DeliverySlotDayModel>> getSlots() async {
    if (error != null) _throw();
    return const <DeliverySlotDayModel>[];
  }

  @override
  Future<DeliverySelectionModel> selectAddress(String addressId) async {
    if (error != null) _throw();
    throw UnimplementedError();
  }

  @override
  Future<DeliverySelectionModel> selectBranch(String branchId) async {
    if (error != null) _throw();
    throw UnimplementedError();
  }
}

class _Catalog extends FakeCatalogRemoteDataSource {
  AppException? error;
  int productReads = 0;
  Completer<void>? gate;

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    productReads++;
    final wait = gate;
    if (wait != null) await wait.future;
    final thrown = error;
    if (thrown != null) throw thrown;
    return ProductsPageModel(
      items: const <ProductModel>[
        ProductModel(
          id: 'p1',
          slug: 'rice',
          name: 'Rice',
          price: 600,
          compareAt: 800,
        ),
      ],
      total: 1,
      page: page,
      limit: limit,
      hasMore: false,
    );
  }

  @override
  Future<List<OfferModel>> getOffers() async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return const <OfferModel>[
      OfferModel(
        id: 'o1',
        name: 'Free delivery over 5 KWD',
        rewardType: 'free_delivery',
        stackable: true,
        branchIds: <String>['b1'],
      ),
    ];
  }

}

void main() {
  group('CheckoutRepositoryImpl', () {
    late _Delivery delivery;
    late _Checkout checkout;
    late CheckoutRepositoryImpl repository;

    setUp(() {
      delivery = _Delivery();
      checkout = _Checkout();
      repository = CheckoutRepositoryImpl(delivery, checkout);
    });

    test('getStoreRules maps the store fields', () async {
      final rules = (await repository.getStoreRules()).getOrElse(
        () => throw StateError('failed'),
      );

      expect(rules.storeName, 'Jm3eia');
      expect(rules.codEnabled, isFalse);
      expect(rules.defaultPaymentMethod, OrderPaymentMethod.wallet);
      expect(rules.loyalty.minRedeemPoints, 100);
      expect(rules.loyalty.canRedeem(100), isTrue);
      expect(rules.proFreeDelivery, isTrue);
      expect(rules.maintenance, isTrue);
      expect(rules.maintenanceMessage, 'Back soon');
    });

    test('getBranches maps the rows', () async {
      final branches = (await repository.getBranches()).getOrElse(
        () => throw StateError('failed'),
      );

      expect(branches.single.id, 'b1');
      expect(branches.single.supportsPickup, isTrue);
    });

    for (final MapEntry(key: name, value: (error, failure))
        in _thrown.entries) {
      test('$name becomes a ${failure.toString()}', () async {
        checkout.error = error;
        delivery.error = error;

        final rules = await repository.getStoreRules();
        final branches = await repository.getBranches();
        final slots = await repository.getDeliverySlots();

        for (final result in <Object?>[
          rules.fold((f) => f, (_) => null),
          branches.fold((f) => f, (_) => null),
          slots.fold((f) => f, (_) => null),
        ]) {
          expect(result.runtimeType, failure);
        }
      });
    }
  });

  group('CheckoutCatalogRepositoryImpl', () {
    late _Catalog catalog;
    late CheckoutCatalogRepositoryImpl repository;

    setUp(() {
      catalog = _Catalog();
      repository = CheckoutCatalogRepositoryImpl(
        CheckoutRailDataSourceImpl(catalog, FakeLocaleProvider('en')),
        catalog,
      );
    });

    test('getRailProducts maps the products', () async {
      final products = (await repository.getRailProducts(limit: 20))
          .getOrElse(() => throw StateError('failed'));

      expect(products.single.id, 'p1');
      expect(products.single.hasListPrice, isTrue);
    });

    test('getStoreOffers maps the offers', () async {
      final offers = (await repository.getStoreOffers()).getOrElse(
        () => throw StateError('failed'),
      );

      expect(offers.single.id, 'o1');
      expect(offers.single.rewardType, OfferRewardType.freeDelivery);
      expect(offers.single.availableAt('b1'), isTrue);
      expect(offers.single.availableAt('b2'), isFalse);
    });

    for (final MapEntry(key: name, value: (error, failure))
        in _thrown.entries) {
      test('$name becomes a ${failure.toString()}', () async {
        catalog.error = error;

        final rail = await repository.getRailProducts(limit: 20);
        final offers = await repository.getStoreOffers();

        expect(rail.fold((f) => f, (_) => null).runtimeType, failure);
        expect(offers.fold((f) => f, (_) => null).runtimeType, failure);
      });
    }
  });

  group('CheckoutRailDataSourceImpl', () {
    late _Catalog catalog;
    late FakeLocaleProvider locale;
    late DateTime clock;
    late CheckoutRailDataSourceImpl rail;

    setUp(() {
      catalog = _Catalog();
      locale = FakeLocaleProvider('en');
      clock = DateTime(2026, 9, 26, 12);
      rail = CheckoutRailDataSourceImpl(catalog, locale, now: () => clock);
    });

    test('a reopen within the window reuses the read; a language switch, '
        'another limit or an expired window ask again', () async {
      await rail.getRailPage(limit: 20);
      await rail.getRailPage(limit: 20);
      expect(catalog.productReads, 1);

      locale.languageCode = 'ar';
      await rail.getRailPage(limit: 20);
      expect(catalog.productReads, 2);

      await rail.getRailPage(limit: 10);
      expect(catalog.productReads, 3);

      clock = clock.add(
        CheckoutRailDataSourceImpl.railTtl + const Duration(seconds: 1),
      );
      await rail.getRailPage(limit: 10);
      expect(catalog.productReads, 4);
    });

    test('readers during a read share it; a late reply still serves the '
        'next open', () async {
      final gate = Completer<void>();
      catalog.gate = gate;

      final first = rail.getRailPage(limit: 20);
      final second = rail.getRailPage(limit: 20);
      gate.complete();
      await Future.wait(<Future<ProductsPageModel>>[first, second]);
      expect(catalog.productReads, 1);

      catalog.gate = null;
      await rail.getRailPage(limit: 20);
      expect(catalog.productReads, 1);
    });

    test('a failed read is not kept', () async {
      catalog.error = const NoInternetConnectionException();
      await expectLater(
        rail.getRailPage(limit: 20),
        throwsA(isA<NoInternetConnectionException>()),
      );

      catalog.error = null;
      final page = await rail.getRailPage(limit: 20);
      expect(page.items.single.id, 'p1');
      expect(catalog.productReads, 2);
    });
  });
}
