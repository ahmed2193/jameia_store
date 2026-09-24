// Category browsing + product listings: the browse tree the rows are built
// from, the repository, the request bounds of GetProductsUseCase, and the
// cubits' races (a filter change while a page is in flight, a failed page,
// re-entry, a stale tree).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/catalog_remote_data_source.dart';
import 'package:jameia_mart/src/core/data/models/brand_model.dart';
import 'package:jameia_mart/src/core/data/models/category_model.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/shop/data/repositories/catalog_browse_repository_impl.dart';
import 'package:jameia_mart/src/features/shop/domain/entities/category_browse.dart';
import 'package:jameia_mart/src/features/shop/domain/repositories/catalog_browse_repository.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_brands_usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_category_tree_usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/category_browse_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/category_browse_state.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/product_listing_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/product_listing_state.dart';

/// Three levels, exactly like the backend tree: a root, its sub-category and
/// that one's own children — plus a second root to switch tabs to.
final CatalogCategoryTree _tree = CatalogCategoryTree(const [
  CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
  CatalogCategoryEntity(
    id: 'c2',
    slug: 'fruits-vegetables',
    name: 'Fruits and Vegetables',
    parentId: 'c1',
  ),
  CatalogCategoryEntity(
    id: 'c3',
    slug: 'apples',
    name: 'Apples',
    parentId: 'c2',
  ),
  CatalogCategoryEntity(
    id: 'c4',
    slug: 'bananas',
    name: 'Bananas',
    parentId: 'c2',
  ),
  CatalogCategoryEntity(
    id: 'c9',
    slug: 'dairy-eggs',
    name: 'Dairy and Eggs',
    sortOrder: 1,
  ),
]);

List<String> _slugs(List<CatalogCategoryEntity> categories) => [
  for (final category in categories) category.slug,
];

CatalogProductsPage _page(
  int page,
  List<String> ids, {
  required bool hasMore,
}) => CatalogProductsPage(
  products: [
    for (final id in ids)
      CatalogProductEntity(id: id, slug: id, name: id, priceFils: 100),
  ],
  page: page,
  hasMore: hasMore,
  total: 5,
);

/// A products use case whose replies are released by the test.
class _GatedGetProducts implements GetProductsUseCase {
  final List<GetProductsParams> requests = [];
  final List<Completer<Either<Failure, CatalogProductsPage>>> calls = [];

  @override
  Future<Either<Failure, CatalogProductsPage>> call(GetProductsParams params) {
    requests.add(params);
    final completer = Completer<Either<Failure, CatalogProductsPage>>();
    calls.add(completer);
    return completer.future;
  }
}

/// The brand filter's source: counts how often the list asks for it.
class _CountingGetBrands implements GetBrandsUseCase {
  int calls = 0;
  Either<Failure, List<BrandEntity>> result = const Right([
    BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
    BrandEntity(id: 'b2', slug: 'kdd', name: 'KDD'),
  ]);

  @override
  Future<Either<Failure, List<BrandEntity>>> call(NoParams params) async {
    calls++;
    return result;
  }
}

class _RecordingRepository implements CatalogBrowseRepository {
  int? lastPage;
  int? lastLimit;
  final List<bool> treeReads = [];
  Either<Failure, CatalogCategoryTree> tree = Right(CatalogCategoryTree.empty);

  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) async {
    treeReads.add(refresh);
    return tree;
  }

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    lastPage = page;
    lastLimit = limit;
    return const Right(CatalogProductsPage.empty);
  }
}

class _ScriptedCatalog implements CatalogRemoteDataSource {
  Object? error;

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) async {
    final current = error;
    if (current != null) throw current;
    return const [
      CategoryModel(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
      CategoryModel(id: 'c2', slug: 'apples', parentId: 'c1'),
    ];
  }

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    final current = error;
    if (current != null) throw current;
    return ProductsPageModel(
      items: const [ProductModel(id: 'p1', slug: 'p-1', price: 1250)],
      total: 1,
      page: page,
      limit: limit,
      hasMore: false,
    );
  }

  @override
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  }) async => const <BrandModel>[];
}

CategoryBrowseCubit _browseCubit(
  CatalogBrowseRepository repository, {
  String baseSlug = '',
}) =>
    CategoryBrowseCubit(GetCategoryTreeUseCase(repository), baseSlug: baseSlug);

void main() {
  group('CategoryBrowse', () {
    test('the store browses roots, then their children, then the leaves', () {
      var browse = CategoryBrowse.resolve(_tree, selectFirstOption: true);

      // The tab row, opened on the first category.
      expect(_slugs(browse.optionsAt(0)), ['fresh-food', 'dairy-eggs']);
      expect(browse.selectionAt(0)?.slug, 'fresh-food');
      expect(browse.activeSlug, 'fresh-food');
      expect(_slugs(browse.optionsAt(1)), ['fruits-vegetables']);
      expect(browse.optionsAt(2), isEmpty);

      // The sub-category rail, then its chips.
      browse = browse.select(1, _tree.bySlug('fruits-vegetables'));
      expect(_slugs(browse.optionsAt(2)), ['apples', 'bananas']);
      expect(browse.activeSlug, 'fruits-vegetables');

      browse = browse.select(2, _tree.bySlug('bananas'));
      expect(browse.activeSlug, 'bananas');

      // "All" on the rail drops the chip pick with it.
      browse = browse.select(1, null);
      expect(browse.selectionAt(2), isNull);
      expect(browse.activeSlug, 'fresh-food');

      // Another tab drops everything below it.
      browse = browse
          .select(1, _tree.bySlug('fruits-vegetables'))
          .select(0, _tree.bySlug('dairy-eggs'));
      expect(browse.path, hasLength(1));
      expect(browse.activeSlug, 'dairy-eggs');
      expect(browse.optionsAt(1), isEmpty);
    });

    test('a category page offers its own children, never the roots', () {
      final browse = CategoryBrowse.resolve(
        _tree,
        baseSlug: 'fruits-vegetables',
      );

      expect(browse.isStoreWide, isFalse);
      expect(browse.base?.name, 'Fruits and Vegetables');
      expect(_slugs(browse.optionsAt(0)), ['apples', 'bananas']);
      expect(browse.activeSlug, 'fruits-vegetables');
      expect(browse.parentAt(0)?.slug, 'fruits-vegetables');
    });

    test('a slug the tree does not have still scopes the products', () {
      final browse = CategoryBrowse.resolve(_tree, baseSlug: 'gone');

      expect(browse.base, isNull);
      expect(browse.optionsAt(0), isEmpty);
      expect(browse.activeSlug, 'gone');
    });

    test('a reload keeps the picks and drops what moved away', () {
      final kept = CategoryBrowse.resolve(
        _tree,
        pathSlugs: const ['fresh-food', 'fruits-vegetables', 'apples'],
      );
      expect(kept.activeSlug, 'apples');

      // Apples now hangs under another parent: the path ends before it.
      final moved = CatalogCategoryTree(const [
        CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
        CatalogCategoryEntity(
          id: 'c2',
          slug: 'fruits-vegetables',
          name: 'Fruits and Vegetables',
          parentId: 'c1',
        ),
        CatalogCategoryEntity(id: 'c3', slug: 'apples', name: 'Apples'),
      ]);
      final trimmed = CategoryBrowse.resolve(
        moved,
        pathSlugs: const ['fresh-food', 'fruits-vegetables', 'apples'],
      );

      expect(trimmed.pathSlugs, ['fresh-food', 'fruits-vegetables']);
      expect(trimmed.activeSlug, 'fruits-vegetables');
    });
  });

  group('CategoryBrowseCubit', () {
    test('the store opens on its first category', () async {
      final repository = _RecordingRepository()..tree = Right(_tree);
      final cubit = _browseCubit(repository);

      await cubit.load();

      expect(cubit.state.status, CategoryBrowseStatus.loaded);
      expect(cubit.state.browse.activeSlug, 'fresh-food');
      expect(repository.treeReads, [false]);
      await cubit.close();
    });

    test('a category page keeps its base and picks across a refresh', () async {
      final repository = _RecordingRepository()..tree = Right(_tree);
      final cubit = _browseCubit(repository, baseSlug: 'fruits-vegetables');
      await cubit.load();

      cubit.select(0, _tree.bySlug('apples'));
      expect(cubit.state.browse.activeSlug, 'apples');

      await cubit.refresh();

      expect(repository.treeReads, [false, true]);
      expect(cubit.state.browse.activeSlug, 'apples');
      expect(cubit.state.browse.base?.slug, 'fruits-vegetables');
      await cubit.close();
    });

    test(
      'a failed first load is an error; a failed refresh keeps rows',
      () async {
        final repository = _RecordingRepository()
          ..tree = const Left(NetworkFailure('offline'));
        final cubit = _browseCubit(repository);

        await cubit.load();
        expect(cubit.state.status, CategoryBrowseStatus.error);

        repository.tree = Right(_tree);
        await cubit.load();
        repository.tree = const Left(ServerFailure('down'));
        await cubit.refresh();

        expect(cubit.state.status, CategoryBrowseStatus.loaded);
        expect(cubit.state.browse.activeSlug, 'fresh-food');
        expect(cubit.state.failure, isA<ServerFailure>());
        expect(const GetCategoryTreeParams(), const GetCategoryTreeParams());
        await cubit.close();
      },
    );

    test('picking what is already picked emits nothing', () async {
      final repository = _RecordingRepository()..tree = Right(_tree);
      final cubit = _browseCubit(repository);
      await cubit.load();
      final states = <CategoryBrowseState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.select(0, _tree.bySlug('fresh-food'));
      await Future<void>.delayed(Duration.zero);

      expect(states, isEmpty);
      await subscription.cancel();
      await cubit.close();
    });
  });

  group('CatalogBrowseRepositoryImpl', () {
    late _ScriptedCatalog catalog;
    late CatalogBrowseRepositoryImpl repository;

    setUp(() {
      catalog = _ScriptedCatalog();
      repository = CatalogBrowseRepositoryImpl(catalog);
    });

    test('builds the tree and maps products (fils kept)', () async {
      final tree = (await repository.getCategoryTree()).getOrElse(
        () => throw StateError('left'),
      );
      final page = (await repository.getProducts(
        query: const CatalogProductQuery(categorySlug: 'fresh-food'),
        page: 1,
        limit: 20,
      )).getOrElse(() => throw StateError('left'));

      expect(tree.roots.single.slug, 'fresh-food');
      expect(tree.childrenOf('c1').single.slug, 'apples');
      expect(page.products.single.priceFils, 1250);
    });

    test('exceptions become their failures', () async {
      catalog.error = const NoInternetConnectionException();

      final tree = await repository.getCategoryTree();
      final products = await repository.getProducts(
        query: const CatalogProductQuery(),
        page: 1,
        limit: 20,
      );

      expect(
        tree.swap().getOrElse(() => throw StateError('right')),
        isA<NetworkFailure>(),
      );
      expect(
        products.swap().getOrElse(() => throw StateError('right')),
        isA<NetworkFailure>(),
      );
    });
  });

  group('GetProductsUseCase', () {
    test('keeps page and limit inside the backend bounds', () async {
      final repository = _RecordingRepository();
      final getProducts = GetProductsUseCase(repository);

      await getProducts(
        const GetProductsParams(
          query: CatalogProductQuery(),
          page: 0,
          limit: 500,
        ),
      );

      expect(repository.lastPage, 1);
      expect(repository.lastLimit, CatalogProductQuery.maxPageSize);
    });
  });

  group('ProductListingCubit', () {
    const query = CatalogProductQuery(categorySlug: 'fresh-food');
    late _CountingGetBrands brands;

    setUp(() => brands = _CountingGetBrands());

    test('loads, pages, merges and stops at the end', () async {
      final gate = _GatedGetProducts();
      final cubit = ProductListingCubit(gate, brands, query: query);

      final first = cubit.load();
      expect(cubit.state.status, ProductListingStatus.loading);
      gate.calls[0].complete(Right(_page(1, ['a', 'b'], hasMore: true)));
      await first;
      final more = cubit.loadMore();
      unawaited(cubit.loadMore()); // re-entry while loading: ignored
      gate.calls[1].complete(Right(_page(2, ['b', 'c'], hasMore: false)));
      await more;
      await cubit.loadMore(); // nothing left

      expect(gate.requests.map((r) => r.page), [1, 2]);
      expect(
        [for (final p in cubit.state.products.products) p.id],
        ['a', 'b', 'c'],
      );
      await cubit.close();
    });

    test(
      'browsing to another category restarts the list, keeping sort',
      () async {
        final gate = _GatedGetProducts();
        final cubit = ProductListingCubit(gate, brands, query: query);
        final first = cubit.load();
        gate.calls[0].complete(Right(_page(1, ['a'], hasMore: true)));
        await first;
        final sorted = cubit.setSort(CatalogProductSort.priceLowToHigh);
        gate.calls[1].complete(Right(_page(1, ['a'], hasMore: true)));
        await sorted;

        final scoped = cubit.setCategorySlug('apples');
        expect(cubit.state.status, ProductListingStatus.loading);
        gate.calls[2].complete(Right(_page(1, ['apple'], hasMore: false)));
        await scoped;
        await cubit.setCategorySlug('apples'); // the same scope: no reload

        expect(gate.requests.last.page, 1);
        expect(gate.requests.last.query.categorySlug, 'apples');
        expect(
          gate.requests.last.query.sort,
          CatalogProductSort.priceLowToHigh,
        );
        expect(gate.calls, hasLength(3));

        final cleared = cubit.setCategorySlug(null);
        gate.calls[3].complete(Right(_page(1, ['any'], hasMore: false)));
        await cleared;
        expect(gate.requests.last.query.categorySlug, isNull);
        await cubit.close();
      },
    );

    test('a sort change restarts at page 1 and drops the stale page', () async {
      final gate = _GatedGetProducts();
      final cubit = ProductListingCubit(gate, brands, query: query);
      final first = cubit.load();
      gate.calls[0].complete(Right(_page(1, ['a'], hasMore: true)));
      await first;

      final stalePage = cubit.loadMore();
      final resort = cubit.setSort(CatalogProductSort.priceLowToHigh);
      expect(cubit.state.status, ProductListingStatus.loading);
      expect(cubit.state.query.sort, CatalogProductSort.priceLowToHigh);
      gate.calls[2].complete(Right(_page(1, ['cheap'], hasMore: true)));
      await resort;
      gate.calls[1].complete(Right(_page(2, ['stale'], hasMore: false)));
      await stalePage;

      expect(gate.requests.last.query.sort, CatalogProductSort.priceLowToHigh);
      expect(gate.requests.last.page, 1);
      expect([for (final p in cubit.state.products.products) p.id], ['cheap']);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });

    test('a failed page keeps the list and stops paging until retry', () async {
      final gate = _GatedGetProducts();
      final cubit = ProductListingCubit(gate, brands, query: query);
      final first = cubit.load();
      gate.calls[0].complete(Right(_page(1, ['a'], hasMore: true)));
      await first;

      final more = cubit.loadMore();
      gate.calls[1].complete(const Left(TimeoutFailure('slow')));
      await more;
      expect(cubit.state.loadMoreFailed, isTrue);
      expect(cubit.state.failure, isA<TimeoutFailure>());
      expect([for (final p in cubit.state.products.products) p.id], ['a']);

      await cubit.loadMore(); // a scroll event: must NOT hit the backend again
      expect(gate.calls, hasLength(2));

      final retry = cubit.loadMore(retry: true);
      gate.calls[2].complete(Right(_page(2, ['b'], hasMore: false)));
      await retry;

      expect(cubit.state.loadMoreFailed, isFalse);
      expect([for (final p in cubit.state.products.products) p.id], ['a', 'b']);
      await cubit.close();
    });

    test(
      'toggles are server-side filters; same sort does not reload',
      () async {
        final gate = _GatedGetProducts();
        final cubit = ProductListingCubit(gate, brands, query: query);
        final first = cubit.load();
        gate.calls[0].complete(Right(_page(1, ['a'], hasMore: false)));
        await first;

        await cubit.setSort(null); // already the default
        expect(gate.calls, hasLength(1));

        final toggled = cubit.toggleInStockOnly();
        gate.calls[1].complete(Right(_page(1, <String>[], hasMore: false)));
        await toggled;

        expect(gate.requests.last.query.inStockOnly, isTrue);
        expect(gate.requests.last.query.categorySlug, 'fresh-food');
        expect(cubit.state.isEmpty, isTrue);
        await cubit.close();
      },
    );

    test(
      'the brand filter reads the brands once and restarts the list',
      () async {
        final gate = _GatedGetProducts();
        final cubit = ProductListingCubit(gate, brands, query: query);
        final first = cubit.load();
        gate.calls[0].complete(Right(_page(1, ['a'], hasMore: false)));
        await first;

        await cubit.loadBrands();
        await cubit.loadBrands(); // the sheet opened again: no second read
        expect(brands.calls, 1);
        expect(cubit.state.brandNameOf('kdd'), 'KDD');
        expect(cubit.state.brandNameOf('gone'), 'gone');

        final filtered = cubit.setBrandSlug('almarai');
        gate.calls[1].complete(Right(_page(1, ['milk'], hasMore: false)));
        await filtered;

        expect(gate.requests.last.query.brandSlug, 'almarai');
        expect(gate.requests.last.query.categorySlug, 'fresh-food');
        expect(gate.requests.last.page, 1);

        final cleared = cubit.setBrandSlug(null);
        gate.calls[2].complete(Right(_page(1, ['a'], hasMore: false)));
        await cleared;
        expect(gate.requests.last.query.brandSlug, isNull);
        await cubit.close();
      },
    );

    test('a list that IS a brand does not offer the brand filter', () async {
      final gate = _GatedGetProducts();
      final cubit = ProductListingCubit(
        gate,
        brands,
        query: const CatalogProductQuery(brandSlug: 'almarai'),
      );
      final first = cubit.load();
      gate.calls[0].complete(Right(_page(1, ['a'], hasMore: false)));
      await first;

      expect(cubit.state.brandLocked, isTrue);
      await cubit.setBrandSlug('kdd');

      expect(gate.calls, hasLength(1));
      expect(cubit.state.query.brandSlug, 'almarai');
      await cubit.close();
    });

    test(
      'a failed first load is the error state; a failed refresh is not',
      () async {
        final gate = _GatedGetProducts();
        final cubit = ProductListingCubit(gate, brands, query: query);
        final first = cubit.load();
        gate.calls[0].complete(const Left(NetworkFailure('offline')));
        await first;
        expect(cubit.state.status, ProductListingStatus.error);

        final retry = cubit.load();
        gate.calls[1].complete(Right(_page(1, ['a'], hasMore: false)));
        await retry;
        final refresh = cubit.refresh();
        gate.calls[2].complete(const Left(NetworkFailure('offline')));
        await refresh;

        expect(cubit.state.status, ProductListingStatus.loaded);
        expect(cubit.state.failure, isA<NetworkFailure>());
        await cubit.close();
      },
    );
  });
}
