// ProductDetailCubit (load / 404 / selection bounds / reload keeps the
// selection / a saved copy at once / reconnect) and ProductReviewsCubit
// (paging + stale replies + reconnect).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_variant_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_reviews.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/get_product_offer_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/get_product_reviews_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/watch_product_detail_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/watch_product_reviews_usecase.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_detail_state.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_reviews_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_reviews_state.dart';

import '../../core/data/snapshot_test_fakes.dart';

const _milkCard = CatalogProductEntity(
  id: 'milk',
  slug: 'milk',
  name: 'Milk',
  type: CatalogProductType.variant,
  stock: 10,
);

const _milk = ProductDetail(
  product: _milkCard,
  variants: [
    CatalogVariantEntity(id: 'gone', name: '0.5 L', priceFils: 300),
    CatalogVariantEntity(id: 'v1', name: '1 L', priceFils: 499, stock: 2),
    CatalogVariantEntity(id: 'v2', name: '2 L', priceFils: 899, stock: 5),
  ],
);

/// The product read: [saved] (when set and not forced), then [reply].
class _StubGetDetail implements WatchProductDetailUseCase {
  _StubGetDetail(this.reply, {this.saved});

  Either<Failure, ProductDetail> reply;
  ProductDetail? saved;
  final List<bool> reads = [];

  @override
  Stream<DataSnapshot<ProductDetail>> call(WatchProductDetailParams params) {
    reads.add(params.forceRefresh);
    return networkRead(
      Future.value(reply),
      saved: params.forceRefresh ? null : saved,
    );
  }
}

class _StubGetOffer implements GetProductOfferUseCase {
  const _StubGetOffer([this.reply = const Right(null)]);

  final Either<Failure, OfferEntity?> reply;

  @override
  Future<Either<Failure, OfferEntity?>> call(
    GetProductOfferParams params,
  ) async => reply;
}

const _noOffer = _StubGetOffer();

/// The first reviews page, served by [_GatedGetReviews] like every page.
class _WatchReviewsFromGet implements WatchProductReviewsUseCase {
  const _WatchReviewsFromGet(this._get);

  final GetProductReviewsUseCase _get;

  @override
  Stream<DataSnapshot<ProductReviews>> call(WatchProductReviewsParams params) =>
      networkRead(
        _get(
          GetProductReviewsParams(
            slug: params.slug,
            page: 1,
            limit: params.limit,
          ),
        ),
      );
}

class _GatedGetReviews implements GetProductReviewsUseCase {
  final List<GetProductReviewsParams> requests = [];
  final List<Completer<Either<Failure, ProductReviews>>> calls = [];

  @override
  Future<Either<Failure, ProductReviews>> call(GetProductReviewsParams params) {
    requests.add(params);
    final completer = Completer<Either<Failure, ProductReviews>>();
    calls.add(completer);
    return completer.future;
  }
}

ProductReviews _reviewsPage(
  int page,
  List<String> ids, {
  required bool hasMore,
}) => ProductReviews(
  reviews: [
    for (final id in ids)
      ProductReview(id: id, rating: 5, createdAt: DateTime.utc(2026, 9)),
  ],
  page: page,
  hasMore: hasMore,
  total: 4,
  ratingAverage: 4.5,
  ratingCount: 4,
);

void main() {
  group('ProductDetailCubit', () {
    blocTest<ProductDetailCubit, ProductDetailState>(
      'loads and pre-selects the first variant that can be bought',
      build: () => ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
        _noOffer,
        slug: 'milk',
        preview: _milkCard,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', LoadPhase.loading)
            .having((s) => s.preview, 'preview', _milkCard),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', LoadPhase.loaded)
            .having((s) => s.selectedVariantId, 'variant', 'v1')
            .having((s) => s.canAdd, 'canAdd', isTrue)
            .having((s) => s.maxQuantity, 'max', 2),
      ],
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      'an unknown slug is "not found", any other failure is an error',
      build: () => ProductDetailCubit(
        _StubGetDetail(const Left(NotFoundFailure('Product not found'))),
        _noOffer,
        slug: 'nope',
      ),
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', LoadPhase.error)
            .having((s) => s.isNotFound, 'isNotFound', isTrue),
      ],
    );

    test('quantity stays inside 1..stock; a new variant restarts it', () async {
      final cubit = ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
        _noOffer,
        slug: 'milk',
      );
      await cubit.load();

      cubit
        ..decrement()
        ..increment()
        ..increment()
        ..increment();
      expect(cubit.state.quantity, 2); // v1 has 2 in stock

      cubit.selectVariant('gone'); // unavailable: ignored
      expect(cubit.state.selectedVariantId, 'v1');

      cubit.selectVariant('v2');
      expect(cubit.state.quantity, 1);
      expect(cubit.state.maxQuantity, 5);
      await cubit.close();
    });

    test('"only N left" follows the stock of the selection', () async {
      final cubit = ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
        _noOffer,
        slug: 'milk',
      );
      expect(cubit.state.lowStockLeft, isNull, reason: 'nothing loaded');
      await cubit.load();

      expect(cubit.state.lowStockLeft, 2); // v1: 2 left
      cubit.selectVariant('v2');
      expect(cubit.state.lowStockLeft, 5); // exactly the threshold
      await cubit.close();

      // Plenty in stock, or none at all: no note.
      const plenty = ProductDetail(
        product: CatalogProductEntity(
          id: 'rice',
          slug: 'rice',
          name: 'Rice',
          priceFils: 1250,
          stock: ProductDetailState.lowStockThreshold + 1,
        ),
      );
      const soldOut = ProductDetail(
        product: CatalogProductEntity(
          id: 'salt',
          slug: 'salt',
          name: 'Salt',
          priceFils: 150,
        ),
      );
      for (final detail in [plenty, soldOut]) {
        final other = ProductDetailCubit(
          _StubGetDetail(Right(detail)),
          _noOffer,
          slug: detail.product.slug,
        );
        await other.load();
        expect(other.state.lowStockLeft, isNull);
        await other.close();
      }
    });

    test(
      'a reload keeps the selection; a failed reload keeps the page',
      () async {
        final getDetail = _StubGetDetail(const Right(_milk));
        final cubit = ProductDetailCubit(getDetail, _noOffer, slug: 'milk');
        await cubit.load();
        cubit.selectVariant('v2');

        await cubit.load();
        expect(cubit.state.selectedVariantId, 'v2');

        getDetail.reply = const Left(NetworkFailure('offline'));
        await cubit.load();

        expect(cubit.state.status, LoadPhase.loaded);
        expect(cubit.state.detail, _milk);
        expect(cubit.state.failure, isA<NetworkFailure>());
        await cubit.close();
      },
    );

    test('the promo tag follows the product; a failure leaves none', () async {
      const offer = OfferEntity(
        id: 'of-dairy',
        name: '2 KWD off dairy (3 items)',
        triggerType: OfferTriggerType.categoryQuantity,
      );
      final cubit = ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
        const _StubGetOffer(Right(offer)),
        slug: 'milk',
      );
      await cubit.load();
      expect(cubit.state.promo, offer);
      await cubit.close();

      final failing = ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
        const _StubGetOffer(Left(NetworkFailure('offline'))),
        slug: 'milk',
      );
      await failing.load();
      expect(failing.state.status, LoadPhase.loaded);
      expect(failing.state.failure, isNull, reason: 'the page never fails');
      expect(failing.state.promo, isNull);
      await failing.close();
    });
  });

  group('ProductReviewsCubit', () {
    test('pages, merges and stops at the end', () async {
      final gate = _GatedGetReviews();
      final cubit = ProductReviewsCubit(
        _WatchReviewsFromGet(gate),
        gate,
        slug: 'rice',
      );

      final first = cubit.load();
      gate.calls[0].complete(Right(_reviewsPage(1, ['a', 'b'], hasMore: true)));
      await first;
      final more = cubit.loadMore();
      expect(cubit.state.isLoadingMore, isTrue);
      unawaited(cubit.loadMore()); // re-entry while loading: ignored
      gate.calls[1].complete(
        Right(_reviewsPage(2, ['b', 'c'], hasMore: false)),
      );
      await more;

      expect(gate.requests.map((r) => r.page), [1, 2]);
      expect(
        [for (final r in cubit.state.reviews.reviews) r.id],
        ['a', 'b', 'c'],
      );
      expect(cubit.state.canLoadMore, isFalse);
      await cubit.close();
    });

    test('a page of the previous list is dropped after a reload', () async {
      final gate = _GatedGetReviews();
      final cubit = ProductReviewsCubit(
        _WatchReviewsFromGet(gate),
        gate,
        slug: 'rice',
      );
      final first = cubit.load();
      gate.calls[0].complete(Right(_reviewsPage(1, ['a'], hasMore: true)));
      await first;

      final more = cubit.loadMore();
      final reload = cubit.load();
      gate.calls[2].complete(Right(_reviewsPage(1, ['x'], hasMore: true)));
      await reload;
      gate.calls[1].complete(Right(_reviewsPage(2, ['stale'], hasMore: false)));
      await more;

      expect([for (final r in cubit.state.reviews.reviews) r.id], ['x']);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });

    test('a failed first load is the section error; retry recovers', () async {
      final gate = _GatedGetReviews();
      final cubit = ProductReviewsCubit(
        _WatchReviewsFromGet(gate),
        gate,
        slug: 'rice',
      );

      final first = cubit.load();
      gate.calls[0].complete(const Left(ServerFailure('boom')));
      await first;
      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<ServerFailure>());

      final retry = cubit.load();
      gate.calls[1].complete(Right(_reviewsPage(1, ['a'], hasMore: false)));
      await retry;

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('reconnect: a stale first page asks again once; a failed "show '
        'more" is tried again', () async {
      final gate = _GatedGetReviews();
      final cubit = ProductReviewsCubit(
        _WatchReviewsFromGet(gate),
        gate,
        slug: 'rice',
      );
      final first = cubit.load();
      gate.calls[0].complete(Right(_reviewsPage(1, ['a'], hasMore: true)));
      await first;

      final more = cubit.loadMore();
      gate.calls[1].complete(const Left(NetworkFailure()));
      await more;
      expect(cubit.state.loadMoreFailed, isTrue);

      final retried = cubit.onReconnected();
      gate.calls[2].complete(Right(_reviewsPage(2, ['b'], hasMore: false)));
      await retried;

      expect(gate.requests.map((r) => r.page), [1, 2, 2]);
      expect([for (final r in cubit.state.reviews.reviews) r.id], ['a', 'b']);
      await cubit.onReconnected();
      expect(gate.calls, hasLength(3), reason: 'nothing stale or failed');
      await cubit.close();
    });
  });

  group('ProductDetailCubit offline', () {
    test('a saved product paints at once, then the server\'s', () async {
      final getDetail = _StubGetDetail(const Right(_milk), saved: _milk);
      final cubit = ProductDetailCubit(getDetail, _noOffer, slug: 'milk');
      final states = <ProductDetailState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load();
      await subscription.cancel();

      final loaded = states.where((s) => s.isLoaded).toList();
      expect(loaded.first.freshness.fromCache, isTrue);
      expect(cubit.state.load.freshness.isStale, isFalse);
      await cubit.close();
    });

    test('offline with a saved copy: the page stays, stale; reconnect '
        'asks once', () async {
      final getDetail = _StubGetDetail(
        const Left(NetworkFailure()),
        saved: _milk,
      );
      final cubit = ProductDetailCubit(getDetail, _noOffer, slug: 'milk');
      await cubit.load();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.detail, _milk);
      expect(cubit.state.load.freshness.isStale, isTrue);
      expect(cubit.state.load.freshness.refreshFailed, isTrue);

      getDetail.reply = const Right(_milk);
      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);
      expect(getDetail.reads, [false, true]);
      expect(cubit.state.load.freshness.isStale, isFalse);
      await cubit.close();
    });

    test('nothing saved + offline: the error keeps its reason and the '
        'preview; "not found" is never asked again', () async {
      final getDetail = _StubGetDetail(const Left(NetworkFailure()));
      final cubit = ProductDetailCubit(
        getDetail,
        _noOffer,
        slug: 'milk',
        preview: _milkCard,
      );
      await cubit.load();
      cubit.setImageIndex(1);

      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.preview, _milkCard);

      getDetail.reply = const Left(NotFoundFailure('Product not found'));
      await cubit.onReconnected();
      expect(cubit.state.isNotFound, isTrue);
      await cubit.onReconnected();
      expect(getDetail.reads, [false, true], reason: 'a 404 stays');
      await cubit.close();
    });
  });
}
