// Search: recent-term rules, local persistence, the discover use case (one
// block may fail), the repository, and the cubit's typing rules (debounce,
// minimum length, stale replies).
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
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/search/data/datasources/search_local_data_source.dart';
import 'package:jameia_mart/src/features/search/data/repositories/search_repository_impl.dart';
import 'package:jameia_mart/src/features/search/domain/entities/recent_searches.dart';
import 'package:jameia_mart/src/features/search/domain/repositories/search_repository.dart';
import 'package:jameia_mart/src/features/search/domain/usecases/get_recent_searches_usecase.dart';
import 'package:jameia_mart/src/features/search/domain/usecases/get_search_discover_usecase.dart';
import 'package:jameia_mart/src/features/search/domain/usecases/save_recent_searches_usecase.dart';
import 'package:jameia_mart/src/features/search/domain/usecases/suggest_products_usecase.dart';
import 'package:jameia_mart/src/features/search/presentation/cubit/search_cubit.dart';

const Duration _debounce = Duration(milliseconds: 1);
const Duration _settle = Duration(milliseconds: 30);

CatalogProductEntity _product(String id) =>
    CatalogProductEntity(id: id, slug: id, name: id, priceFils: 100);

class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = <String, Object>{};

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
}

class _FakeRepository implements SearchRepository {
  Either<Failure, CatalogCategoryTree> tree = Right(
    CatalogCategoryTree(const [
      CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
      CatalogCategoryEntity(
        id: 'c2',
        slug: 'apples',
        name: 'Apples',
        parentId: 'c1',
      ),
    ]),
  );
  Either<Failure, List<BrandEntity>> brands = const Right([
    BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
  ]);
  RecentSearches stored = const RecentSearches(['milk']);
  final List<String> suggestRequests = [];
  final Map<String, Completer<Either<Failure, List<CatalogProductEntity>>>>
  gates = {};

  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree() async => tree;

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async => brands;

  @override
  Either<Failure, RecentSearches> getRecentSearches() => Right(stored);

  @override
  Future<Either<Failure, Unit>> saveRecentSearches(
    RecentSearches recents,
  ) async {
    stored = recents;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> suggestProducts({
    required String text,
    required int limit,
  }) {
    suggestRequests.add(text);
    return (gates[text] ??= Completer()).future;
  }
}

class _ScriptedCatalog implements CatalogRemoteDataSource {
  CatalogProductQuery? lastQuery;
  int? lastLimit;

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    lastQuery = query;
    lastLimit = limit;
    return const ProductsPageModel(
      items: [ProductModel(id: 'p1', slug: 'rice', name: 'Rice')],
      total: 1,
      page: 1,
      limit: 6,
      hasMore: false,
    );
  }

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) async =>
      throw const NoInternetConnectionException();

  @override
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  }) async => const [BrandModel(id: 'b1', slug: 'kdd', name: 'KDD')];
}

SearchCubit _cubit(_FakeRepository repository) => SearchCubit(
  GetSearchDiscoverUseCase(repository),
  SuggestProductsUseCase(repository),
  GetRecentSearchesUseCase(repository),
  SaveRecentSearchesUseCase(repository),
  debounce: _debounce,
);

void main() {
  group('RecentSearches', () {
    test('newest first, case-insensitive de-dupe, trimmed, capped', () {
      var recents = const RecentSearches(['milk', 'Bread']);

      recents = recents.add('  bread ');
      expect(recents.terms, ['bread', 'milk']);

      recents = recents.add('   ');
      expect(recents.terms, ['bread', 'milk']);

      for (var i = 0; i < 12; i++) {
        recents = recents.add('term $i');
      }
      expect(recents.terms, hasLength(RecentSearches.maxTerms));
      expect(recents.terms.first, 'term 11');
    });
  });

  group('SearchLocalDataSourceImpl', () {
    test(
      'round-trips under the legacy key; corrupt data is an empty history',
      () async {
        final storage = _MemoryStorage();
        final local = SearchLocalDataSourceImpl(storage);

        await local.writeRecentSearches(['rice', 'milk']);
        expect(storage.values.keys.single, 'jameia.search.recents.v1');
        expect(local.readRecentSearches(), ['rice', 'milk']);

        await local.writeRecentSearches(const []);
        expect(storage.values, isEmpty);

        storage.values[SearchLocalDataSourceImpl.recentsKey] = '{not json';
        expect(local.readRecentSearches(), isEmpty);
      },
    );
  });

  group('SearchRepositoryImpl', () {
    test(
      'suggestions ask the product list by text; failures are mapped',
      () async {
        final catalog = _ScriptedCatalog();
        final repository = SearchRepositoryImpl(
          catalog,
          SearchLocalDataSourceImpl(_MemoryStorage()),
        );

        final products = await repository.suggestProducts(
          text: 'rice',
          limit: 6,
        );
        final tree = await repository.getCategoryTree();

        expect(catalog.lastQuery, const CatalogProductQuery(search: 'rice'));
        expect(catalog.lastLimit, 6);
        expect(products.getOrElse(() => []).single.slug, 'rice');
        expect(
          tree.swap().getOrElse(() => throw StateError('right')),
          isA<NetworkFailure>(),
        );
      },
    );
  });

  group('use cases', () {
    test('short text asks nothing', () async {
      final repository = _FakeRepository();

      final result = await SuggestProductsUseCase(repository)(
        const SuggestProductsParams(' r '),
      );

      expect(result.getOrElse(() => [_product('x')]), isEmpty);
      expect(repository.suggestRequests, isEmpty);
    });

    test('discover: roots only; one failing block leaves the other', () async {
      final repository = _FakeRepository();
      final getDiscover = GetSearchDiscoverUseCase(repository);

      final both = (await getDiscover(const NoParams()))
          .getOrElse(() => throw StateError('left'));
      expect([for (final c in both.categories) c.slug], ['fresh-food']);
      expect(both.brands.single.slug, 'almarai');

      repository.tree = const Left(ServerFailure('down'));
      final brandsOnly = (await getDiscover(const NoParams()))
          .getOrElse(() => throw StateError('left'));
      expect(brandsOnly.categories, isEmpty);
      expect(brandsOnly.brands, hasLength(1));

      repository.brands = const Left(ServerFailure('down'));
      expect((await getDiscover(const NoParams())).isLeft(), isTrue);
    });
  });

  group('SearchCubit', () {
    test(
      'loadDiscover shows the stored recents and the backend blocks',
      () async {
        final cubit = _cubit(_FakeRepository());

        await cubit.loadDiscover();

        expect(cubit.state.recents.terms, ['milk']);
        expect(cubit.state.discover.categories.single.slug, 'fresh-food');
        await cubit.close();
      },
    );

    test('typing is debounced: only the last text is requested', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      cubit
        ..onQueryChanged('ri')
        ..onQueryChanged('ric')
        ..onQueryChanged('rice');
      expect(cubit.state.isSuggesting, isTrue);
      await Future<void>.delayed(_settle);
      repository.gates['rice']!.complete(Right([_product('rice')]));
      await Future<void>.delayed(_settle);

      expect(repository.suggestRequests, ['rice']);
      expect(cubit.state.suggestions.single.id, 'rice');
      expect(cubit.state.isSuggesting, isFalse);
      await cubit.close();
    });

    test('a reply for text the customer already changed is dropped', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      cubit.onQueryChanged('mil');
      await Future<void>.delayed(_settle);
      cubit.onQueryChanged('bread');
      await Future<void>.delayed(_settle);
      repository.gates['bread']!.complete(Right([_product('bread')]));
      await Future<void>.delayed(_settle);
      repository.gates['mil']!.complete(Right([_product('milk')]));
      await Future<void>.delayed(_settle);

      expect(cubit.state.suggestions.single.id, 'bread');
      await cubit.close();
    });

    test(
      'short text and clearQuery empty the suggestions without a request',
      () async {
        final repository = _FakeRepository();
        final cubit = _cubit(repository);

        cubit.onQueryChanged('rice');
        await Future<void>.delayed(_settle);
        repository.gates['rice']!.complete(Right([_product('rice')]));
        await Future<void>.delayed(_settle);

        cubit.onQueryChanged('r');
        expect(cubit.state.suggestions, isEmpty);
        expect(cubit.state.isSuggesting, isFalse);
        expect(cubit.state.isTyping, isTrue);

        cubit.clearQuery();
        expect(cubit.state.isTyping, isFalse);
        expect(repository.suggestRequests, ['rice']);
        await cubit.close();
      },
    );

    test(
      'a failed suggestion request leaves the list empty, not an error',
      () async {
        final repository = _FakeRepository();
        final cubit = _cubit(repository);

        cubit.onQueryChanged('rice');
        await Future<void>.delayed(_settle);
        repository.gates['rice']!.complete(
          const Left(NetworkFailure('offline')),
        );
        await Future<void>.delayed(_settle);

        expect(cubit.state.suggestions, isEmpty);
        expect(cubit.state.isSuggesting, isFalse);
        await cubit.close();
      },
    );

    test('recents are stored newest first and can be cleared', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.loadDiscover();

      cubit.addRecent('Rice');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.recents.terms, ['Rice', 'milk']);
      expect(repository.stored.terms, ['Rice', 'milk']);

      cubit.clearRecents();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.recents.isEmpty, isTrue);
      expect(repository.stored.isEmpty, isTrue);
      await cubit.close();
    });

    test('no timer fires after close', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      cubit.onQueryChanged('rice');
      await cubit.close();
      await Future<void>.delayed(_settle);

      expect(repository.suggestRequests, isEmpty);
    });
  });
}
