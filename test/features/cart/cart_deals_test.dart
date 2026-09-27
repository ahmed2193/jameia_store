// The basket bars' domain facts (delivery quote, pre-discount total), the
// deals view built from the live cart shapes, the deals repository's
// queries and the deals sheet's cubit (selection, reuse, stale replies).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/models/category_model.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/data/repositories/cart_deals_repository_impl.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_offers_view.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/get_deal_products_usecase.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_deals_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_deals_state.dart';

import '../../core/data/catalog_test_fakes.dart';
import 'cart_test_fixtures.dart';

const String _dairyId = '6aa5ffb85233feadc5c41513';

CartLineEntity testLine({int quantity = 1}) => CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: quantity,
);

/// The live guest cart with 3 eggs (2026-09-26): free delivery and the dairy
/// offer earned, 10% and the summer offer still ahead.
final CartEntity _threeEggs = CartEntity(
  itemCount: 3,
  lines: [testLine(quantity: 3)],
  appliedOffers: const [
    CartAppliedOfferEntity(
      offerId: 'of-free-delivery',
      name: 'Free delivery over 5 KWD',
      reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
    ),
    CartAppliedOfferEntity(
      offerId: 'of-dairy',
      name: '2 KWD off dairy (3 items)',
      discountFils: 2000,
      reward: OfferRewardEntity(
        type: OfferRewardType.fixedDiscount,
        amountFils: 2000,
      ),
    ),
  ],
  offerProgress: const [
    CartOfferProgressEntity(
      offerId: 'of-ten',
      name: '10% off over 15 KWD',
      kind: OfferProgressKind.subtotal,
      currentValue: 6750,
      targetValue: 15000,
      remainingValue: 8250,
      reward: OfferRewardEntity(
        type: OfferRewardType.percentageDiscount,
        percent: 10,
      ),
    ),
  ],
  totals: const CartTotalsEntity(
    subtotalFils: 6750,
    offerDiscountFils: 2000,
    discountFils: 2000,
    freeDelivery: true,
    totalFils: 4750,
  ),
);

/// The live guest cart with 1 egg: nothing earned yet, the dairy offer
/// counts a category.
final CartEntity _oneEgg = CartEntity(
  itemCount: 1,
  lines: [testLine()],
  offerProgress: const [
    CartOfferProgressEntity(
      offerId: 'of-free-delivery',
      name: 'Free delivery over 5 KWD',
      kind: OfferProgressKind.subtotal,
      currentValue: 2250,
      targetValue: 5000,
      remainingValue: 2750,
      reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
    ),
    CartOfferProgressEntity(
      offerId: 'of-dairy',
      name: '2 KWD off dairy (3 items)',
      kind: OfferProgressKind.category,
      currentValue: 1,
      targetValue: 3,
      remainingValue: 2,
      contextId: _dairyId,
      contextName: 'Dairy & Eggs',
    ),
  ],
  totals: const CartTotalsEntity(
    subtotalFils: 2250,
    deliveryFeeFils: 650,
    totalFils: 2900,
    baseDeliveryFeeFils: 650,
  ),
);

class _ScriptedCatalog extends FakeCatalogRemoteDataSource {
  final List<CatalogProductQuery> queries = [];

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) async => [
    const CategoryModel(id: _dairyId, slug: 'dairy-eggs', name: 'Dairy & Eggs'),
  ];

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    queries.add(query);
    return const ProductsPageModel(
      items: [ProductModel(id: 'eggs', slug: 'fresh-eggs-30', name: 'Eggs')],
      total: 1,
      page: 1,
      limit: 30,
      hasMore: false,
    );
  }

}

/// Replies when the test says so, per call.
class _GatedDeals implements GetDealProductsUseCase {
  final List<GetDealProductsParams> requests = [];
  final List<Completer<Either<Failure, List<CatalogProductEntity>>>> calls =
      [];

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> call(
    GetDealProductsParams params,
  ) {
    requests.add(params);
    final completer = Completer<Either<Failure, List<CatalogProductEntity>>>();
    calls.add(completer);
    return completer.future;
  }
}

void main() {
  group('basket bar facts', () {
    test('delivery quote: free, the fee, or nothing to say', () {
      expect(_threeEggs.deliveryQuoteFils, 0);
      expect(_oneEgg.deliveryQuoteFils, 650);
      expect(_oneEgg.deliveryQuoteKd, 0.65);
      // The live empty cart says freeDelivery: true — the bar is hidden then.
      expect(
        const CartEntity(totals: CartTotalsEntity(freeDelivery: true))
            .deliveryQuoteFils,
        isNull,
      );
      final pickup = CartEntity(
        fulfillmentMode: FulfillmentMode.pickup,
        lines: [testLine()],
      );
      expect(pickup.deliveryQuoteFils, isNull);
      final unquoted = CartEntity(lines: [testLine()]);
      expect(unquoted.deliveryQuoteFils, isNull);
    });

    test('the struck total is the total before its discounts', () {
      expect(_threeEggs.totals.totalBeforeDiscountFils, 6750);
      expect(_threeEggs.totals.totalBeforeDiscountKd, 6.75);
      expect(_oneEgg.totals.totalBeforeDiscountFils, isNull);
    });
  });

  group('CartOffersView', () {
    test('earned first, then the ones ahead, in the server order', () {
      final view = CartOffersView.of(_threeEggs);

      expect(view.deals.map((d) => d.offerId), [
        'of-free-delivery',
        'of-dairy',
        'of-ten',
      ]);
      expect(view.deals.first.applied, isTrue);
      expect(view.deals[1].savedKd, 2);
      expect(view.hasEarned, isTrue);
      expect(view.next?.offerId, 'of-ten');
      expect(view.initial?.offerId, 'of-ten');
      expect(view.allEarned, isFalse);
    });

    test('a category offer still ahead names its category', () {
      final view = CartOffersView.of(_oneEgg);

      expect(view.hasEarned, isFalse);
      expect(view.next?.remainingKd, 2.75);
      expect(view.deals.first.categoryId, isNull, reason: 'subtotal offer');
      expect(view.deals.last.categoryId, _dairyId);
      expect(view.byId('of-dairy')?.contextName, 'Dairy & Eggs');
    });

    test('every offer earned: the best deal; none at all: empty', () {
      final done = CartOffersView.of(
        CartEntity(
          lines: [testLine()],
          appliedOffers: _threeEggs.appliedOffers,
          offerProgress: const [
            // A reached row the server may still list is not "ahead".
            CartOfferProgressEntity(
              offerId: 'of-late',
              name: 'Late',
              targetValue: 1,
              currentValue: 1,
            ),
          ],
        ),
      );
      expect(done.allEarned, isTrue);
      expect(done.next, isNull);
      expect(done.initial?.offerId, 'of-free-delivery');
      expect(done.deals.last.categoryId, isNull, reason: 'earned');

      expect(CartOffersView.of(CartEntity.empty).isEmpty, isTrue);
      expect(CartOffersView.of(CartEntity.empty).allEarned, isFalse);
    });
  });

  group('CartDealsRepositoryImpl', () {
    test('a category offer lists that category, the rest what is on sale',
        () async {
      final catalog = _ScriptedCatalog();
      final repository = CartDealsRepositoryImpl(catalog);

      final dairy = await repository.getDealProducts(
        categoryId: _dairyId,
        limit: 30,
      );
      await repository.getDealProducts(limit: 30);
      await repository.getDealProducts(categoryId: 'unknown', limit: 30);

      expect(dairy.getOrElse(() => const []).single.slug, 'fresh-eggs-30');
      expect(catalog.queries[0].categorySlug, 'dairy-eggs');
      expect(catalog.queries[0].onSaleOnly, isFalse);
      expect(catalog.queries[0].inStockOnly, isTrue);
      expect(catalog.queries[0].sort, CatalogProductSort.discount);
      for (final query in catalog.queries.skip(1)) {
        expect(query.categorySlug, isNull);
        expect(query.onSaleOnly, isTrue);
        expect(query.inStockOnly, isTrue);
      }
    });

    test('a transport failure becomes a Failure', () async {
      final repository = CartDealsRepositoryImpl(_FailingCatalog());

      final result = await repository.getDealProducts(limit: 30);

      expect(result.isLeft(), isTrue);
    });
  });

  group('CartDealsCubit', () {
    const eggs = CatalogProductEntity(id: 'eggs', slug: 'eggs', name: 'Eggs');
    const milk = CatalogProductEntity(id: 'milk', slug: 'milk', name: 'Milk');
    final view = CartOffersView.of(_oneEgg);

    blocTest<CartDealsCubit, CartDealsState>(
      'opens on the next deal to unlock and lists what is on sale',
      build: () {
        final gate = _GatedDeals();
        scheduleMicrotask(() => gate.calls.single.complete(const Right([eggs])));
        return CartDealsCubit(gate);
      },
      act: (cubit) => cubit.open(view),
      expect: () => [
        const CartDealsState(
          selectedOfferId: 'of-free-delivery',
          status: CartDealsStatus.loading,
        ),
        const CartDealsState(
          selectedOfferId: 'of-free-delivery',
          status: CartDealsStatus.loaded,
          products: [eggs],
        ),
      ],
    );

    test('a category card asks for its category; going back reuses', () async {
      final gate = _GatedDeals();
      final cubit = CartDealsCubit(gate);

      final opening = cubit.open(view);
      gate.calls[0].complete(const Right([eggs]));
      await opening;

      final dairy = cubit.select(view.byId('of-dairy')!);
      expect(gate.requests.last.categoryId, _dairyId);
      gate.calls[1].complete(const Right([milk]));
      await dairy;
      expect(cubit.state.products, [milk]);

      await cubit.select(view.byId('of-free-delivery')!);
      expect(gate.requests, hasLength(2), reason: 'read in this opening');
      expect(cubit.state.products, [eggs]);
      await cubit.close();
    });

    test('a slow reply for a card already left is dropped', () async {
      final gate = _GatedDeals();
      final cubit = CartDealsCubit(gate);

      final opening = cubit.open(view);
      final dairy = cubit.select(view.byId('of-dairy')!);
      gate.calls[1].complete(const Right([milk]));
      await dairy;
      gate.calls[0].complete(const Right([eggs]));
      await opening;

      expect(cubit.state.selectedOfferId, 'of-dairy');
      expect(cubit.state.products, [milk]);
      await cubit.close();
    });

    test('an error keeps the card; retry asks again; reopen reads afresh',
        () async {
      final gate = _GatedDeals();
      final cubit = CartDealsCubit(gate);

      final opening = cubit.open(view);
      gate.calls[0].complete(const Left(NetworkFailure('offline')));
      await opening;
      expect(cubit.state.status, CartDealsStatus.error);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.selectedOfferId, 'of-free-delivery');

      final retry = cubit.retry();
      gate.calls[1].complete(const Right([eggs]));
      await retry;
      expect(cubit.state.status, CartDealsStatus.loaded);
      expect(cubit.state.failure, isNull);

      final again = cubit.open(view);
      expect(gate.requests, hasLength(3), reason: 'a new opening reads');
      gate.calls[2].complete(const Right([eggs]));
      await again;
      await cubit.close();
    });
  });
}

class _FailingCatalog extends _ScriptedCatalog {
  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) => throw const NoInternetConnectionException();
}
