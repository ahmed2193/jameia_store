// The category tabs of a collection page: loaded once, reloaded on a
// language switch (the tabs on screen stay meanwhile), kept silently on a
// failure and asked again on reconnect, a stale reply dropped — plus the
// tab ⇄ category-slug mapping the page reads.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_listing_category_tabs_usecase.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/listing_tabs_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/listing_tabs_state.dart';

const CatalogCategoryEntity _snacks = CatalogCategoryEntity(
  id: 'c1',
  slug: 'snacks',
  name: 'Snacks & Chocolate',
);
const CatalogCategoryEntity _iceCream = CatalogCategoryEntity(
  id: 'c2',
  slug: 'ice-cream',
  name: 'Ice Cream',
);

const CatalogProductQuery _bestSellers = CatalogProductQuery(
  collectionSlug: 'best-sellers',
);

/// Replies released by the test, in any order.
class _GatedTabs implements GetListingCategoryTabsUseCase {
  final List<GetListingCategoryTabsParams> requests = [];
  final List<Completer<Either<Failure, List<CatalogCategoryEntity>>>> calls =
      [];

  @override
  Future<Either<Failure, List<CatalogCategoryEntity>>> call(
    GetListingCategoryTabsParams params,
  ) {
    requests.add(params);
    final completer = Completer<Either<Failure, List<CatalogCategoryEntity>>>();
    calls.add(completer);
    return completer.future;
  }
}

class _StubTabs implements GetListingCategoryTabsUseCase {
  _StubTabs(this.reply);

  final Either<Failure, List<CatalogCategoryEntity>> reply;
  final List<GetListingCategoryTabsParams> requests = [];

  @override
  Future<Either<Failure, List<CatalogCategoryEntity>>> call(
    GetListingCategoryTabsParams params,
  ) async {
    requests.add(params);
    return reply;
  }
}

void main() {
  group('ListingTabsCubit', () {
    late _StubTabs stub;

    blocTest<ListingTabsCubit, ListingTabsState>(
      'loads the tabs of its list',
      build: () {
        stub = _StubTabs(const Right([_snacks, _iceCream]));
        return ListingTabsCubit(stub, query: _bestSellers);
      },
      act: (cubit) => cubit.load(),
      expect: () => const [
        ListingTabsState(status: ListingTabsStatus.loading),
        ListingTabsState(
          status: ListingTabsStatus.loaded,
          categories: [_snacks, _iceCream],
        ),
      ],
      verify: (_) => expect(stub.requests, const [
        GetListingCategoryTabsParams(query: _bestSellers),
      ]),
    );

    blocTest<ListingTabsCubit, ListingTabsState>(
      'a failure keeps the tabs on screen',
      build: () => ListingTabsCubit(
        _StubTabs(const Left(NetworkFailure())),
        query: _bestSellers,
      ),
      seed: () => const ListingTabsState(
        status: ListingTabsStatus.loaded,
        categories: [_snacks, _iceCream],
      ),
      act: (cubit) => cubit.load(),
      expect: () => const [
        ListingTabsState(
          status: ListingTabsStatus.loading,
          categories: [_snacks, _iceCream],
        ),
        ListingTabsState(
          status: ListingTabsStatus.failed,
          categories: [_snacks, _iceCream],
        ),
      ],
      verify: (cubit) => expect(cubit.state.showsTabs, isTrue),
    );

    blocTest<ListingTabsCubit, ListingTabsState>(
      'reconnect asks again after a failure, never after a load',
      build: () {
        stub = _StubTabs(const Right([_snacks, _iceCream]));
        return ListingTabsCubit(stub, query: _bestSellers);
      },
      seed: () => const ListingTabsState(status: ListingTabsStatus.failed),
      act: (cubit) async {
        await cubit.onReconnected();
        await cubit.onReconnected();
      },
      expect: () => const [
        ListingTabsState(status: ListingTabsStatus.loading),
        ListingTabsState(
          status: ListingTabsStatus.loaded,
          categories: [_snacks, _iceCream],
        ),
      ],
      verify: (_) => expect(stub.requests, hasLength(1)),
    );

    blocTest<ListingTabsCubit, ListingTabsState>(
      'a reload keeps the tabs on screen until the new ones arrive',
      build: () => ListingTabsCubit(
        _StubTabs(const Right([_iceCream, _snacks])),
        query: _bestSellers,
      ),
      seed: () => const ListingTabsState(
        status: ListingTabsStatus.loaded,
        categories: [_snacks, _iceCream],
      ),
      act: (cubit) => cubit.load(),
      expect: () => const [
        ListingTabsState(
          status: ListingTabsStatus.loading,
          categories: [_snacks, _iceCream],
        ),
        ListingTabsState(
          status: ListingTabsStatus.loaded,
          categories: [_iceCream, _snacks],
        ),
      ],
    );

    test('drops the reply of an older load', () async {
      final gated = _GatedTabs();
      final cubit = ListingTabsCubit(gated, query: _bestSellers);
      addTearDown(cubit.close);

      unawaited(cubit.load());
      unawaited(cubit.load());
      gated.calls[1].complete(const Right([_iceCream, _snacks]));
      await Future<void>.delayed(Duration.zero);
      gated.calls[0].complete(const Right([_snacks]));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.categories, const [_iceCream, _snacks]);
      expect(cubit.state.status, ListingTabsStatus.loaded);
    });

    test('a reply after the page closed is ignored', () async {
      final gated = _GatedTabs();
      final cubit = ListingTabsCubit(gated, query: _bestSellers);
      unawaited(cubit.load());
      await cubit.close();

      gated.calls.single.complete(const Right([_snacks, _iceCream]));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ListingTabsStatus.loading);
    });
  });

  group('ListingTabsState', () {
    const tabs = ListingTabsState(
      status: ListingTabsStatus.loaded,
      categories: [_snacks, _iceCream],
    );

    test('shows tabs only for two categories or more', () {
      expect(tabs.showsTabs, isTrue);
      expect(const ListingTabsState(categories: [_snacks]).showsTabs, isFalse);
      expect(const ListingTabsState().showsTabs, isFalse);
    });

    test('tab 0 is "All", then one tab per category', () {
      expect(tabs.tabOf(null), 0);
      expect(tabs.tabOf('snacks'), 1);
      expect(tabs.tabOf('ice-cream'), 2);
      expect(tabs.tabOf('gone'), 0, reason: 'a slug with no tab reads All');

      expect(tabs.slugAt(0), isNull);
      expect(tabs.slugAt(1), 'snacks');
      expect(tabs.slugAt(2), 'ice-cream');
      expect(tabs.slugAt(3), isNull);
    });

    test('knows which scopes its tabs can show', () {
      expect(tabs.hasTabFor(null), isTrue);
      expect(tabs.hasTabFor('ice-cream'), isTrue);
      expect(tabs.hasTabFor('gone'), isFalse);
      expect(
        const ListingTabsState(categories: [_snacks]).hasTabFor('snacks'),
        isFalse,
        reason: 'one category shows no tabs at all',
      );
    });
  });
}
