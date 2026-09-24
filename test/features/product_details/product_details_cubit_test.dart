// ProductDetailCubit (load / 404 / selection bounds / reload keeps the
// selection) and ProductReviewsCubit (paging + stale replies).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_variant_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_reviews.dart';
import 'package:jameia_mart/src/features/product_details/domain/usecases/get_product_detail_usecase.dart';
import 'package:jameia_mart/src/features/product_details/domain/usecases/get_product_reviews_usecase.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_detail_state.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_reviews_cubit.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_reviews_state.dart';

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

class _StubGetDetail implements GetProductDetailUseCase {
  _StubGetDetail(this.reply);

  Either<Failure, ProductDetail> reply;

  @override
  Future<Either<Failure, ProductDetail>> call(
    GetProductDetailParams params,
  ) async => reply;
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
        slug: 'milk',
        preview: _milkCard,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading)
            .having((s) => s.preview, 'preview', _milkCard),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loaded)
            .having((s) => s.selectedVariantId, 'variant', 'v1')
            .having((s) => s.canAdd, 'canAdd', isTrue)
            .having((s) => s.maxQuantity, 'max', 2),
      ],
    );

    blocTest<ProductDetailCubit, ProductDetailState>(
      'an unknown slug is "not found", any other failure is an error',
      build: () => ProductDetailCubit(
        _StubGetDetail(
          const Left(ServerFailure('Product not found', statusCode: 404)),
        ),
        slug: 'nope',
      ),
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.error)
            .having((s) => s.isNotFound, 'isNotFound', isTrue),
      ],
    );

    test('quantity stays inside 1..stock; a new variant restarts it', () async {
      final cubit = ProductDetailCubit(
        _StubGetDetail(const Right(_milk)),
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

    test(
      'a reload keeps the selection; a failed reload keeps the page',
      () async {
        final getDetail = _StubGetDetail(const Right(_milk));
        final cubit = ProductDetailCubit(getDetail, slug: 'milk');
        await cubit.load();
        cubit.selectVariant('v2');

        await cubit.load();
        expect(cubit.state.selectedVariantId, 'v2');

        getDetail.reply = const Left(NetworkFailure('offline'));
        await cubit.load();

        expect(cubit.state.status, ProductDetailStatus.loaded);
        expect(cubit.state.detail, _milk);
        expect(cubit.state.failure, isA<NetworkFailure>());
        await cubit.close();
      },
    );
  });

  group('ProductReviewsCubit', () {
    test('pages, merges and stops at the end', () async {
      final gate = _GatedGetReviews();
      final cubit = ProductReviewsCubit(gate, slug: 'rice');

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
      final cubit = ProductReviewsCubit(gate, slug: 'rice');
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
      final cubit = ProductReviewsCubit(gate, slug: 'rice');

      final first = cubit.load();
      gate.calls[0].complete(const Left(ServerFailure('boom')));
      await first;
      expect(cubit.state.status, ProductReviewsStatus.error);
      expect(cubit.state.failure, isA<ServerFailure>());

      final retry = cubit.load();
      gate.calls[1].complete(Right(_reviewsPage(1, ['a'], hasMore: false)));
      await retry;

      expect(cubit.state.status, ProductReviewsStatus.loaded);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });
  });
}
