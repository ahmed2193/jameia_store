// Recipes: DTOs / mappers fed with the live payloads, datasource, repository
// (failure mapping, the device copy) and the cubits (paging, stale replies,
// not found, a saved copy at once, the reconnect refresh).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/recipe_summary_entity.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/core/usecase/watch_params.dart';
import 'package:hero_mart/src/features/recipes/data/datasources/recipes_cache_data_source.dart';
import 'package:hero_mart/src/features/recipes/data/datasources/recipes_remote_data_source.dart';
import 'package:hero_mart/src/features/recipes/data/mappers/recipes_mapper.dart';
import 'package:hero_mart/src/features/recipes/data/models/recipe_models.dart';
import 'package:hero_mart/src/features/recipes/data/repositories/recipes_repository_impl.dart';
import 'package:hero_mart/src/features/recipes/domain/entities/recipe_detail.dart';
import 'package:hero_mart/src/features/recipes/domain/entities/recipes_feed.dart';
import 'package:hero_mart/src/features/recipes/domain/usecases/get_recipes_usecase.dart';
import 'package:hero_mart/src/features/recipes/domain/usecases/watch_recipe_detail_usecase.dart';
import 'package:hero_mart/src/features/recipes/domain/usecases/watch_recipes_usecase.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipe_detail_cubit.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipe_detail_state.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipes_cubit.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipes_state.dart';

import '../../core/data/snapshot_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/features/recipes/$name').readAsStringSync())
        as Map<String, dynamic>;

RecipesFeed _feed(int page, List<String> ids, {required bool hasMore}) =>
    RecipesFeed(
      recipes: [
        for (final id in ids) RecipeSummaryEntity(id: id, slug: id, title: id),
      ],
      page: page,
      hasMore: hasMore,
    );

class _GatedGetRecipes implements GetRecipesUseCase {
  final List<GetRecipesParams> requests = [];
  final List<Completer<Either<Failure, RecipesFeed>>> calls = [];

  @override
  Future<Either<Failure, RecipesFeed>> call(GetRecipesParams params) {
    requests.add(params);
    final completer = Completer<Either<Failure, RecipesFeed>>();
    calls.add(completer);
    return completer.future;
  }
}

/// The first recipes page, served by the gated page fake like every page.
class _WatchRecipesFromGet implements WatchRecipesUseCase {
  const _WatchRecipesFromGet(this._get, {this.saved});

  final GetRecipesUseCase _get;
  final RecipesFeed? saved;

  @override
  Stream<DataSnapshot<RecipesFeed>> call(WatchParams params) => networkRead(
    _get(const GetRecipesParams(page: 1)),
    saved: params.forceRefresh ? null : saved,
  );
}

/// The recipe read: [saved] (when set and not forced), then [reply].
class _StubWatchRecipe implements WatchRecipeDetailUseCase {
  _StubWatchRecipe(this.reply);

  Either<Failure, RecipeDetail> reply;
  RecipeDetail? saved;
  final List<bool> reads = [];

  @override
  Stream<DataSnapshot<RecipeDetail>> call(WatchRecipeDetailParams params) {
    reads.add(params.forceRefresh);
    return networkRead(
      Future.value(reply),
      saved: params.forceRefresh ? null : saved,
    );
  }
}

class _ScriptedRemote implements RecipesRemoteDataSource {
  Object? error;
  int detailReads = 0;

  @override
  Future<RemotePayload<RecipesPageModel>> getRecipes({
    required int page,
    required int limit,
  }) async {
    final current = error;
    if (current != null) throw current;
    final raw = _fixture('recipes_list_fixture.json');
    return RemotePayload(
      RecipesPageModel.fromJson(raw, requestedPage: page),
      raw,
    );
  }

  @override
  Future<RemotePayload<RecipeDetailModel>> getRecipe(String slug) async {
    detailReads++;
    final current = error;
    if (current != null) throw current;
    final raw = _fixture('recipe_detail_fixture.json');
    return RemotePayload(RecipeDetailModel.fromJson(raw), raw);
  }
}

RecipesRepositoryImpl _repository(_ScriptedRemote remote) =>
    RecipesRepositoryImpl(
      remote,
      cache: RecipesCacheDataSourceImpl(
        CacheSlots(
          store: InMemoryJsonCacheStore(),
          owner: CacheOwner(),
          locale: FakeLocaleProvider('en'),
        ),
      ),
    );

RecipesCubit _recipesCubit(_GatedGetRecipes gate, {RecipesFeed? saved}) =>
    RecipesCubit(_WatchRecipesFromGet(gate, saved: saved), gate);

void main() {
  group('live payloads', () {
    test('the list keeps the pagination and the teaser', () {
      final feed = RecipesPageModel.fromJson(
        _fixture('recipes_list_fixture.json'),
      ).toEntity();

      expect(
        [for (final recipe in feed.recipes) recipe.slug],
        ['machboos', 'margoog'],
      );
      expect(feed.recipes.first.excerpt, isNotEmpty);
      expect(feed.recipes.first.totalMinutes, 80);
      expect(feed.page, 1);
      expect(feed.hasMore, isTrue);
    });

    test(
      'the detail maps ingredients to store products and orders the steps',
      () {
        final detail = RecipeDetailModel.fromJson(
          _fixture('recipe_detail_fixture.json'),
        ).toEntity();

        expect(detail.summary.slug, 'machboos');
        expect(detail.summary.cuisineName, 'Kuwaiti');
        expect(detail.ingredients, hasLength(5));
        final chicken = detail.ingredients.first;
        expect(chicken.product.slug, 'almarai-chicken-900g');
        expect(chicken.product.priceFils, 1499);
        expect(chicken.purchaseQuantity, 2);
        expect(chicken.note, 'bone-in pieces');
        expect(chicken.canAddToCart, isTrue);
        expect(detail.purchasableIngredients, hasLength(5));
        expect([for (final step in detail.steps) step.order], [1, 2, 3, 4, 5]);
        expect(detail.steps.first.durationMinutes, 10);
      },
    );
  });

  group('mapper rules', () {
    test('fractional purchase quantities round up; bad rows are skipped', () {
      final detail = RecipeDetailModel.fromJson({
        '_id': 'r1',
        'slug': 'r-1',
        'title': 'R',
        'ingredients': [
          {
            'id': 'i1',
            'purchaseQty': 0.4,
            'product': {'_id': 'p1', 'slug': 'p-1', 'price': 100, 'stock': 3},
          },
          {
            'id': 'i2',
            'purchaseQty': 2.2,
            'product': {
              '_id': 'p2',
              'slug': 'p-2',
              'type': 'variant',
              'stock': 3,
            },
          },
          {'id': 'no-product'},
        ],
        'steps': [
          {'id': 's2', 'order': 2, 'body': 'second'},
          {'id': 's1', 'order': 1, 'body': 'first'},
          {'id': 'empty', 'order': 3},
        ],
      }).toEntity();

      expect([for (final i in detail.ingredients) i.purchaseQuantity], [1, 3]);
      expect(detail.purchasableIngredients.single.id, 'i1');
      expect([for (final step in detail.steps) step.body], ['first', 'second']);
    });

    test('a recipe without an identity is a ParsingException', () {
      expect(
        () => RecipeDetailModel.fromJson({'title': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('RecipesRemoteDataSourceImpl', () {
    late FakeHttpClientAdapter adapter;

    RecipesRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return RecipesRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );
    }

    test('getRecipes GETs page + limit', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(_fixture('recipes_list_fixture.json')),
        ),
      );

      final page = await dataSource.getRecipes(page: 2, limit: 20);

      expect(adapter.requests.single.path, EndPoints.recipes);
      expect(adapter.requests.single.queryParameters, {'page': 2, 'limit': 20});
      expect(page.model.items, hasLength(2));
      expect(page.raw, _fixture('recipes_list_fixture.json'));
    });

    test('getRecipe GETs /v1/recipes/:slug', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(_fixture('recipe_detail_fixture.json')),
        ),
      );

      final recipe = (await dataSource.getRecipe('machboos')).model;

      expect(adapter.requests.single.path, EndPoints.recipe('machboos'));
      expect(recipe.steps, hasLength(5));
    });
  });

  group('RecipesRepositoryImpl', () {
    test('maps entities; a 404 keeps its status', () async {
      final remote = _ScriptedRemote();
      final repository = _repository(remote);

      expect(
        (await repository.getRecipes(page: 2, limit: 20)).isRight(),
        isTrue,
      );
      expect(
        (await repository.watchRecipe('machboos').last).data.summary.slug,
        'machboos',
      );

      remote.error = const NotFoundException('Recipe not found');

      await expectLater(
        repository.watchRecipe('nope'),
        emitsError(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('the first page and a recipe paint from the device copy', () async {
      final remote = _ScriptedRemote();
      final repository = _repository(remote);
      await repository.watchRecipes(limit: 20).drain<void>();
      await repository.watchRecipe('machboos').drain<void>();
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      final list = await repository.watchRecipes(limit: 20).toList();
      final recipe = await repository.watchRecipe('machboos').toList();

      expect(list.single.isFromCache, isTrue);
      expect(list.single.data.recipes, hasLength(2));
      expect(recipe.single.isFromCache, isTrue);
      expect(remote.detailReads, 1, reason: 'a fresh copy ends the read');
    });
  });

  group('cubits', () {
    test(
      'RecipesCubit pages, merges, and stops auto-paging after a failure',
      () async {
        final gate = _GatedGetRecipes();
        final cubit = _recipesCubit(gate);

        final first = cubit.load();
        gate.calls[0].complete(Right(_feed(1, ['a', 'b'], hasMore: true)));
        await first;
        final failing = cubit.loadMore();
        gate.calls[1].complete(const Left(TimeoutFailure('slow')));
        await failing;
        await cubit.loadMore(); // scroll event after a failure: ignored
        expect(gate.calls, hasLength(2));
        expect(cubit.state.loadMoreFailed, isTrue);

        final retry = cubit.loadMore(retry: true);
        gate.calls[2].complete(Right(_feed(2, ['b', 'c'], hasMore: false)));
        await retry;

        expect(
          [for (final r in cubit.state.feed.recipes) r.id],
          ['a', 'b', 'c'],
        );
        expect(cubit.state.canLoadMore, isFalse);
        await cubit.close();
      },
    );

    test('a page of the previous list is dropped after a refresh', () async {
      final gate = _GatedGetRecipes();
      final cubit = _recipesCubit(gate);
      final first = cubit.load();
      gate.calls[0].complete(Right(_feed(1, ['a'], hasMore: true)));
      await first;

      final stale = cubit.loadMore();
      final refresh = cubit.refresh();
      gate.calls[2].complete(Right(_feed(1, ['x'], hasMore: true)));
      await refresh;
      gate.calls[1].complete(Right(_feed(2, ['stale'], hasMore: false)));
      await stale;

      expect([for (final r in cubit.state.feed.recipes) r.id], ['x']);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.status, LoadPhase.loaded);
      await cubit.close();
    });

    test('RecipeDetailCubit: an unknown slug is "not found"', () async {
      final cubit = RecipeDetailCubit(
        _StubWatchRecipe(const Left(NotFoundFailure('Recipe not found'))),
        slug: 'nope',
      );

      await cubit.load();

      expect(cubit.state.isNotFound, isTrue);
      await cubit.onReconnected();
      expect(cubit.state.isNotFound, isTrue, reason: 'never asked again');
      await cubit.close();
    });

    test('RecipesCubit: a saved first page at once; reconnect refreshes '
        'it once, then retries a failed page', () async {
      final gate = _GatedGetRecipes();
      final cubit = _recipesCubit(
        gate,
        saved: _feed(1, ['saved'], hasMore: true),
      );

      final first = cubit.load();
      await pumpEventQueue();
      expect(cubit.state.feed.recipes.single.id, 'saved');
      expect(cubit.state.load.freshness.fromCache, isTrue);
      gate.calls[0].complete(const Left(NetworkFailure()));
      await first;
      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.load.freshness.isStale, isTrue);

      final reconnected = cubit.onReconnected();
      gate.calls[1].complete(Right(_feed(1, ['a'], hasMore: true)));
      await reconnected;
      expect(cubit.state.feed.recipes.single.id, 'a');
      expect(cubit.state.load.freshness.isStale, isFalse);

      final more = cubit.loadMore();
      gate.calls[2].complete(const Left(NetworkFailure()));
      await more;
      final retried = cubit.onReconnected();
      gate.calls[3].complete(Right(_feed(2, ['b'], hasMore: false)));
      await retried;

      expect([for (final r in cubit.state.feed.recipes) r.id], ['a', 'b']);
      expect(gate.requests.map((r) => r.page), [1, 1, 2, 2]);
      await cubit.close();
    });

    test('RecipeDetailCubit: nothing saved + offline keeps the reason; '
        'reconnect loads it', () async {
      final watch = _StubWatchRecipe(const Left(NetworkFailure()));
      final cubit = RecipeDetailCubit(watch, slug: 'machboos');

      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<NetworkFailure>());

      watch.reply = Right(
        RecipeDetailModel.fromJson(_fixture('recipe_detail_fixture.json'))
            .toEntity(),
      );
      await cubit.onReconnected();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(watch.reads, [false, true]);
      await cubit.close();
    });
  });
}
