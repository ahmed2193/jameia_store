// The category tabs of a collection page: every top-level category is probed
// with the list's own query (one row, only the total is read), roots with
// products are kept in tree order, a failed probe drops only its root, at
// most four probes run at once and a failed tree read fails the call.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/shop/domain/repositories/catalog_browse_repository.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_listing_category_tabs_usecase.dart';

CatalogCategoryEntity _root(String slug, {int sortOrder = 0}) =>
    CatalogCategoryEntity(
      id: 'id-$slug',
      slug: slug,
      name: slug,
      sortOrder: sortOrder,
    );

/// Snacks → Ice cream → Dairy → Bakery, plus a child of Snacks that must
/// never be probed (a parent's list already includes it).
final CatalogCategoryTree _tree = CatalogCategoryTree([
  _root('snacks'),
  _root('ice-cream', sortOrder: 1),
  _root('dairy', sortOrder: 2),
  _root('bakery', sortOrder: 3),
  const CatalogCategoryEntity(
    id: 'id-chips',
    slug: 'chips',
    name: 'chips',
    parentId: 'id-snacks',
  ),
]);

CatalogProductsPage _total(int total) => CatalogProductsPage(
  products: const [],
  page: 1,
  hasMore: total > 1,
  total: total,
);

/// Scripted catalogue: the tree, a total (or a failure) per category slug,
/// and — when [gated] — probes that wait until the test releases them.
class _ProbeRepository implements CatalogBrowseRepository {
  _ProbeRepository({
    required this.tree,
    this.totals = const {},
    this.gated = false,
  });

  final Either<Failure, CatalogCategoryTree> tree;
  final Map<String, Either<Failure, CatalogProductsPage>> totals;
  final bool gated;

  final List<({CatalogProductQuery query, int page, int limit})> probes = [];
  final List<Completer<void>> gates = [];
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) async => tree;

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    probes.add((query: query, page: page, limit: limit));
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    if (gated) {
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
    } else {
      await Future<void>.delayed(Duration.zero);
    }
    inFlight--;
    return totals[query.categorySlug] ?? Right(_total(0));
  }
}

List<String> _slugs(List<CatalogCategoryEntity> categories) => [
  for (final category in categories) category.slug,
];

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  const bestSellers = CatalogProductQuery(
    collectionSlug: 'best-sellers',
    categorySlug: 'stale-scope',
    inStockOnly: true,
  );

  test('keeps the roots with products, in tree order', () async {
    final repository = _ProbeRepository(
      tree: Right(_tree),
      totals: {
        'snacks': Right(_total(12)),
        'ice-cream': Right(_total(3)),
        'bakery': Right(_total(1)),
      },
    );

    final result = await GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );

    expect(_slugs(result.getOrElse(() => const [])), [
      'snacks',
      'ice-cream',
      'bakery',
    ]);
  });

  test(
    'probes each root once with the list query, one row of page 1',
    () async {
      final repository = _ProbeRepository(tree: Right(_tree));

      await GetListingCategoryTabsUseCase(repository)(
        const GetListingCategoryTabsParams(query: bestSellers),
      );

      expect(
        [for (final probe in repository.probes) probe.query.categorySlug],
        unorderedEquals(['snacks', 'ice-cream', 'dairy', 'bakery']),
        reason: 'roots only: a child is inside its parent list already',
      );
      for (final probe in repository.probes) {
        expect(probe.page, 1);
        expect(probe.limit, 1);
        expect(probe.query.collectionSlug, 'best-sellers');
        expect(probe.query.inStockOnly, isTrue);
      }
    },
  );

  test('drops the roots whose total is zero', () async {
    final repository = _ProbeRepository(
      tree: Right(_tree),
      totals: {
        'snacks': Right(_total(0)),
        'ice-cream': Right(_total(2)),
        'dairy': Right(_total(0)),
      },
    );

    final result = await GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );

    expect(_slugs(result.getOrElse(() => const [])), ['ice-cream']);
  });

  test('a failed probe drops only its own root', () async {
    final repository = _ProbeRepository(
      tree: Right(_tree),
      totals: {
        'snacks': Right(_total(5)),
        'ice-cream': const Left(NetworkFailure()),
        'dairy': Right(_total(4)),
      },
    );

    final result = await GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );

    expect(result.isRight(), isTrue);
    expect(_slugs(result.getOrElse(() => const [])), ['snacks', 'dairy']);
  });

  test('never runs more than four probes at once', () async {
    final roots = CatalogCategoryTree([
      for (var i = 0; i < 9; i++) _root('root-$i', sortOrder: i),
    ]);
    final repository = _ProbeRepository(
      tree: Right(roots),
      totals: {for (var i = 0; i < 9; i++) 'root-$i': Right(_total(i))},
      gated: true,
    );

    final pending = GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );
    await _flush();
    expect(repository.probes, hasLength(4));
    expect(repository.inFlight, 4);

    // One answer frees one slot: the next root is asked, never more.
    repository.gates.first.complete();
    await _flush();
    await _flush();
    expect(repository.probes, hasLength(5));
    expect(repository.inFlight, 4);

    while (repository.gates.any((gate) => !gate.isCompleted)) {
      for (final gate in repository.gates.where((g) => !g.isCompleted)) {
        gate.complete();
      }
      await _flush();
      await _flush();
    }
    final result = await pending;

    expect(repository.maxInFlight, 4);
    expect(repository.probes, hasLength(9));
    expect(_slugs(result.getOrElse(() => const [])), [
      for (var i = 1; i < 9; i++) 'root-$i',
    ], reason: 'tree order, root-0 has no products');
  });

  test('a failed tree read fails the call and probes nothing', () async {
    final repository = _ProbeRepository(tree: const Left(NetworkFailure()));

    final result = await GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );

    expect(
      result,
      const Left<Failure, List<CatalogCategoryEntity>>(NetworkFailure()),
    );
    expect(repository.probes, isEmpty);
  });

  test('an empty tree gives no tabs', () async {
    final repository = _ProbeRepository(tree: Right(CatalogCategoryTree.empty));

    final result = await GetListingCategoryTabsUseCase(repository)(
      const GetListingCategoryTabsParams(query: bestSellers),
    );

    expect(result.getOrElse(() => [_root('x')]), isEmpty);
    expect(repository.probes, isEmpty);
  });
}
