// Search: recent-term rules, local persistence, the repository (live
// suggestions; discover blocks the device copy first, then the server's),
// the use cases, the cubit (discover blocks one by one, typing rules —
// debounce, minimum length, stale replies — the offline suggestion state
// and the reconnect refresh) and the offline list while typing.
import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/datasources/catalog_cache_data_source.dart';
import 'package:hero_mart/src/core/data/models/brand_model.dart';
import 'package:hero_mart/src/core/data/models/catalog_results.dart';
import 'package:hero_mart/src/core/data/models/category_model.dart';
import 'package:hero_mart/src/core/data/models/product_model.dart';
import 'package:hero_mart/src/core/data/models/products_page_model.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/core/storage/local_storage.dart';
import 'package:hero_mart/src/core/usecase/watch_params.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:hero_mart/src/features/search/data/datasources/search_local_data_source.dart';
import 'package:hero_mart/src/features/search/data/repositories/search_repository_impl.dart';
import 'package:hero_mart/src/features/search/domain/entities/recent_searches.dart';
import 'package:hero_mart/src/features/search/domain/repositories/search_repository.dart';
import 'package:hero_mart/src/features/search/domain/usecases/get_recent_searches_usecase.dart';
import 'package:hero_mart/src/features/search/domain/usecases/save_recent_searches_usecase.dart';
import 'package:hero_mart/src/features/search/domain/usecases/suggest_products_usecase.dart';
import 'package:hero_mart/src/features/search/domain/usecases/watch_search_brands_usecase.dart';
import 'package:hero_mart/src/features/search/domain/usecases/watch_search_categories_usecase.dart';
import 'package:hero_mart/src/features/search/presentation/cubit/search_cubit.dart';
import 'package:hero_mart/src/features/search/presentation/cubit/search_state.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_suggestion_skeleton.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_suggestions_view.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_term_row.dart';

import '../../core/data/catalog_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';

const Duration _debounce = Duration(milliseconds: 1);
const Duration _settle = Duration(milliseconds: 30);

CatalogProductEntity _product(String id) =>
    CatalogProductEntity(id: id, slug: id, name: id, priceFils: 100);

final CatalogCategoryTree _tree = CatalogCategoryTree(const [
  CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
  CatalogCategoryEntity(
    id: 'c2',
    slug: 'apples',
    name: 'Apples',
    parentId: 'c1',
  ),
]);

const List<BrandEntity> _brands = [
  BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
];

final DateTime _fetchedAt = DateTime.utc(2026, 9, 27, 12);

/// A cached read as a repository streams it: the saved copy (when given and
/// not forced), then the server's reply or its failure.
Stream<DataSnapshot<T>> _read<T>({
  required T? cached,
  required Either<Failure, T> network,
  required bool forceRefresh,
}) async* {
  if (cached != null && !forceRefresh) {
    yield DataSnapshot<T>(
      data: cached,
      fetchedAt: _fetchedAt.subtract(const Duration(hours: 1)),
      origin: SnapshotOrigin.cache,
    );
  }
  yield* network.fold(
    Stream<DataSnapshot<T>>.error,
    (data) => Stream.value(
      DataSnapshot<T>(
        data: data,
        fetchedAt: _fetchedAt,
        origin: SnapshotOrigin.network,
      ),
    ),
  );
}

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
  Either<Failure, CatalogCategoryTree> tree = Right(_tree);
  Either<Failure, List<BrandEntity>> brands = const Right(_brands);
  CatalogCategoryTree? cachedTree;
  List<BrandEntity>? cachedBrands;

  /// The discover reads asked for (`true` = forced).
  final List<bool> treeReads = [];
  RecentSearches stored = const RecentSearches(['milk']);
  final List<String> suggestRequests = [];
  final Map<String, Completer<Either<Failure, List<CatalogProductEntity>>>>
  gates = {};

  @override
  Stream<DataSnapshot<CatalogCategoryTree>> watchCategoryTree({
    bool forceRefresh = false,
  }) {
    treeReads.add(forceRefresh);
    return _read(cached: cachedTree, network: tree, forceRefresh: forceRefresh);
  }

  @override
  Stream<DataSnapshot<List<BrandEntity>>> watchBrands({
    bool forceRefresh = false,
  }) =>
      _read(cached: cachedBrands, network: brands, forceRefresh: forceRefresh);

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

/// `results` of `GET /v1/categories` and `GET /v1/brands`.
const Map<String, Object?> _categoriesJson = {
  CatalogResults.dataKey: [
    {
      CategoryModel.idKey: 'c1',
      CategoryModel.slugKey: 'fresh-food',
      CategoryModel.nameKey: 'Fresh Food',
    },
    {
      CategoryModel.idKey: 'c2',
      CategoryModel.slugKey: 'apples',
      CategoryModel.nameKey: 'Apples',
      CategoryModel.parentIdKey: 'c1',
    },
  ],
};

const Map<String, Object?> _brandsJson = {
  CatalogResults.dataKey: [
    {
      BrandModel.idKey: 'b1',
      BrandModel.slugKey: 'kdd',
      BrandModel.nameKey: 'KDD',
    },
  ],
};

class _ScriptedCatalog extends FakeCatalogRemoteDataSource {
  CatalogProductQuery? lastQuery;
  int? lastLimit;
  Object? error;
  int categoryFetches = 0;
  (int, int)? brandsPage;

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
  Future<RemotePayload<List<CategoryModel>>> fetchCategories() async {
    categoryFetches++;
    final thrown = error;
    if (thrown != null) throw thrown;
    return RemotePayload(
      CatalogResults.categories(_categoriesJson),
      _categoriesJson,
    );
  }

  @override
  Future<RemotePayload<List<BrandModel>>> fetchBrands({
    required int page,
    required int limit,
    String? search,
  }) async {
    brandsPage = (page, limit);
    return RemotePayload(CatalogResults.brands(_brandsJson), _brandsJson);
  }
}

SearchCubit _cubit(_FakeRepository repository) => SearchCubit(
  WatchSearchCategoriesUseCase(repository),
  WatchSearchBrandsUseCase(repository),
  SuggestProductsUseCase(repository),
  GetRecentSearchesUseCase(repository),
  SaveRecentSearchesUseCase(repository),
  debounce: _debounce,
);

class _MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}

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
        expect(storage.values.keys.single, 'hero.search.recents.v1');
        expect(local.readRecentSearches(), ['rice', 'milk']);

        await local.writeRecentSearches(const []);
        expect(storage.values, isEmpty);

        storage.values[SearchLocalDataSourceImpl.recentsKey] = '{not json';
        expect(local.readRecentSearches(), isEmpty);
      },
    );
  });

  group('SearchRepositoryImpl', () {
    late _ScriptedCatalog catalog;
    late InMemoryJsonCacheStore store;
    late SearchRepositoryImpl repository;

    setUp(() {
      catalog = _ScriptedCatalog();
      store = InMemoryJsonCacheStore();
      repository = SearchRepositoryImpl(
        catalog,
        SearchLocalDataSourceImpl(_MemoryStorage()),
        cache: CatalogCacheDataSourceImpl(
          // Public entries: cached even before the session is known.
          CacheSlots(
            store: store,
            owner: CacheOwner(),
            locale: FakeLocaleProvider('en'),
          ),
        ),
      );
    });

    test('suggestions ask the product list by text, live', () async {
      final products = await repository.suggestProducts(text: 'rice', limit: 6);

      expect(catalog.lastQuery, const CatalogProductQuery(search: 'rice'));
      expect(catalog.lastLimit, 6);
      expect(products.getOrElse(() => []).single.slug, 'rice');
      expect(store.writes, 0, reason: 'suggestions are never kept');
    });

    test(
      'the tree is saved; the next open paints it without a request',
      () async {
        final first = await repository.watchCategoryTree().toList();
        await pumpEventQueue();
        final reopened = await repository.watchCategoryTree().toList();

        expect(first.single.origin, SnapshotOrigin.network);
        expect(
          [for (final c in first.single.data.roots) c.slug],
          ['fresh-food'],
        );
        expect(reopened.single.isFromCache, isTrue);
        expect(reopened.single.data, first.single.data);
        expect(catalog.categoryFetches, 1);
      },
    );

    test('offline with nothing saved is a NetworkFailure', () async {
      catalog.error = const NoInternetConnectionException();

      await expectLater(
        repository.watchCategoryTree(),
        emitsError(isA<NetworkFailure>()),
      );
    });

    test('brands: the first page of 100, saved', () async {
      final brands = await repository.watchBrands().last;
      await pumpEventQueue();

      expect(catalog.brandsPage, (1, 100));
      expect(brands.data.single.slug, 'kdd');
      expect(store.writes, 1);
    });
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

    test('the categories block is the roots only, freshness kept', () async {
      final repository = _FakeRepository()..cachedTree = _tree;

      final snapshots = await WatchSearchCategoriesUseCase(repository)(
        WatchParams.cached,
      ).toList();

      expect(snapshots.map((s) => s.isFromCache), [true, false]);
      expect([for (final c in snapshots.last.data) c.slug], ['fresh-food']);
    });
  });

  group('SearchCubit', () {
    test('loadDiscover shows the stored recents and both blocks', () async {
      final cubit = _cubit(_FakeRepository());

      await cubit.loadDiscover();

      expect(cubit.state.recents.terms, ['milk']);
      expect(cubit.state.discover.categories.single.slug, 'fresh-food');
      expect(cubit.state.discover.brands.single.slug, 'almarai');
      await cubit.close();
    });

    test(
      'offline: the saved blocks show; one block failing keeps the other',
      () async {
        final repository = _FakeRepository()
          ..cachedTree = _tree
          ..tree = const Left(NetworkFailure())
          ..brands = const Left(ServerFailure('down'));
        final cubit = _cubit(repository);

        await cubit.loadDiscover();

        expect(cubit.state.discover.categories.single.slug, 'fresh-food');
        expect(cubit.state.discover.brands, isEmpty);
        expect(cubit.state.discoverFailure, isNull, reason: 'a block shows');
        expect(cubit.state.isDiscoverLoading, isFalse);
        await cubit.close();
      },
    );

    test('discover: loading while nothing shows; both failed with nothing '
        'saved keeps the reason; a retry clears it', () async {
      final repository = _FakeRepository()
        ..tree = const Left(ServerFailure('down'))
        ..brands = const Left(ServerFailure('down'));
      final cubit = _cubit(repository);

      final reading = cubit.loadDiscover();
      expect(cubit.state.isDiscoverLoading, isTrue);
      expect(cubit.state.discoverFailure, isNull);
      await reading;

      expect(cubit.state.isDiscoverLoading, isFalse);
      expect(cubit.state.discoverFailure, isA<ServerFailure>());

      repository
        ..tree = Right(_tree)
        ..brands = const Right(_brands);
      final retry = cubit.loadDiscover();
      expect(cubit.state.discoverFailure, isNull, reason: 'the skeleton again');
      expect(cubit.state.isDiscoverLoading, isTrue);
      await retry;
      expect(cubit.state.isDiscoverLoading, isFalse);
      expect(cubit.state.discover.categories.single.slug, 'fresh-food');
      await cubit.close();
    });

    test('reconnect refreshes stale blocks once, then nothing', () async {
      final repository = _FakeRepository()
        ..cachedTree = _tree
        ..tree = const Left(NetworkFailure());
      final cubit = _cubit(repository);
      await cubit.loadDiscover();

      repository.tree = Right(_tree);
      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);
      expect(repository.treeReads, [false, true], reason: 'single-flight');

      await cubit.onReconnected();
      expect(repository.treeReads, [false, true], reason: 'all fresh now');
      await cubit.close();
    });

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

    test('a failed request keeps its reason until the next keystroke; '
        'reconnect asks again for the text as it is', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      cubit.onQueryChanged('rice');
      await Future<void>.delayed(_settle);
      repository.gates['rice']!.complete(const Left(NetworkFailure()));
      await Future<void>.delayed(_settle);

      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.isSuggesting, isFalse);
      expect(cubit.state.suggestFailure, isA<NetworkFailure>());
      expect(cubit.state.showsOfflineList(offline: false), isTrue);

      repository.gates.remove('rice');
      unawaited(cubit.onReconnected());
      expect(cubit.state.suggestFailure, isNull);
      expect(cubit.state.isSuggesting, isTrue);
      await Future<void>.delayed(_settle);
      repository.gates['rice']!.complete(Right([_product('rice')]));
      await Future<void>.delayed(_settle);

      expect(repository.suggestRequests, ['rice', 'rice']);
      expect(cubit.state.suggestions.single.id, 'rice');
      await cubit.close();
    });

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

  group('SearchState offline list', () {
    const recents = RecentSearches(['milk', 'bread']);

    test('offline with no matches, or a no-connection failure', () {
      const typing = SearchState(query: 'mi', recents: recents);

      expect(typing.showsOfflineList(offline: false), isFalse);
      expect(typing.showsOfflineList(offline: true), isTrue);
      expect(
        typing
            .copyWith(suggestions: [_product('milk')])
            .showsOfflineList(offline: true),
        isFalse,
        reason: 'matches that came through still show',
      );
      expect(
        typing
            .copyWith(suggestFailure: const ServerFailure('down'))
            .showsOfflineList(offline: false),
        isFalse,
      );
    });

    test('the matching past terms, else all of them', () {
      expect(const SearchState(query: 'mi', recents: recents).offlineTerms, [
        'milk',
      ]);
      expect(const SearchState(query: 'rice', recents: recents).offlineTerms, [
        'milk',
        'bread',
      ]);
    });
  });

  group('SearchSuggestionsView', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late _MockAuthSessionCubit session;

    setUpAll(() async {
      final en = json.decode(
        await rootBundle.loadString('assets/i18n/en.json'),
      ) as Map<String, dynamic>;
      Localization.load(const Locale('en'), translations: Translations(en));
    });

    setUp(() {
      session = _MockAuthSessionCubit();
      whenListen(
        session,
        const Stream<AuthSessionState>.empty(),
        initialState: const AuthSessionState(),
      );
    });

    Future<void> pump(
      WidgetTester tester,
      SearchState state, {
      required bool offline,
    }) => tester.pumpWidget(
      ConnectivityScope(
        isOffline: offline,
        reconnectEpoch: 0,
        onNudge: () {},
        child: BlocProvider<AuthSessionCubit>.value(
          value: session,
          child: MaterialApp(
            home: Scaffold(
              body: SearchSuggestionsView(
                state: state,
                onSearch: (_) {},
                onRefine: (_) {},
                onOpenProduct: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    const typing = SearchState(
      query: 'rice',
      recents: RecentSearches(['milk', 'bread']),
      isSuggesting: true,
    );

    testWidgets('offline: the past terms under the note, no bones, no bar', (
      tester,
    ) async {
      await pump(tester, typing, offline: true);

      expect(find.text('connectivity.search_offline'.tr()), findsOneWidget);
      expect(find.byType(SearchTermRow), findsNWidgets(2));
      expect(find.byType(SearchSuggestionSkeleton), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('online: bone rows while the first reply is on its way', (
      tester,
    ) async {
      await pump(tester, typing, offline: false);

      expect(find.text('connectivity.search_offline'.tr()), findsNothing);
      expect(find.byType(SearchSuggestionSkeleton), findsOneWidget);
    });
  });
}
