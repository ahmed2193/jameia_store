// Recipes: DTOs / mappers fed with the live payloads, datasource, repository
// failure mapping and the cubits (paging, stale replies, not found).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/recipe_summary_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/recipes/data/datasources/recipes_remote_data_source.dart';
import 'package:jameia_mart/src/features/recipes/data/mappers/recipes_mapper.dart';
import 'package:jameia_mart/src/features/recipes/data/models/recipe_models.dart';
import 'package:jameia_mart/src/features/recipes/data/repositories/recipes_repository_impl.dart';
import 'package:jameia_mart/src/features/recipes/domain/entities/recipe_detail.dart';
import 'package:jameia_mart/src/features/recipes/domain/entities/recipes_feed.dart';
import 'package:jameia_mart/src/features/recipes/domain/usecases/get_recipe_detail_usecase.dart';
import 'package:jameia_mart/src/features/recipes/domain/usecases/get_recipes_usecase.dart';
import 'package:jameia_mart/src/features/recipes/presentation/cubit/recipe_detail_cubit.dart';
import 'package:jameia_mart/src/features/recipes/presentation/cubit/recipes_cubit.dart';
import 'package:jameia_mart/src/features/recipes/presentation/cubit/recipes_state.dart';

import '../../core/network/network_test_fakes.dart';

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

class _StubGetRecipeDetail implements GetRecipeDetailUseCase {
  _StubGetRecipeDetail(this.reply);

  Either<Failure, RecipeDetail> reply;

  @override
  Future<Either<Failure, RecipeDetail>> call(
    GetRecipeDetailParams params,
  ) async => reply;
}

class _ScriptedRemote implements RecipesRemoteDataSource {
  Object? error;

  @override
  Future<RecipesPageModel> getRecipes({
    required int page,
    required int limit,
  }) async {
    final current = error;
    if (current != null) throw current;
    return RecipesPageModel.fromJson(
      _fixture('recipes_list_fixture.json'),
      requestedPage: page,
    );
  }

  @override
  Future<RecipeDetailModel> getRecipe(String slug) async {
    final current = error;
    if (current != null) throw current;
    return RecipeDetailModel.fromJson(_fixture('recipe_detail_fixture.json'));
  }
}

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
      expect(page.items, hasLength(2));
    });

    test('getRecipe GETs /v1/recipes/:slug', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(_fixture('recipe_detail_fixture.json')),
        ),
      );

      final recipe = await dataSource.getRecipe('machboos');

      expect(adapter.requests.single.path, EndPoints.recipe('machboos'));
      expect(recipe.steps, hasLength(5));
    });
  });

  group('RecipesRepositoryImpl', () {
    test('maps entities; a 404 keeps its status', () async {
      final remote = _ScriptedRemote();
      final repository = RecipesRepositoryImpl(remote);

      expect(
        (await repository.getRecipes(page: 1, limit: 20)).isRight(),
        isTrue,
      );
      expect((await repository.getRecipe('machboos')).isRight(), isTrue);

      remote.error = const NotFoundException('Recipe not found');
      final missing = await repository.getRecipe('nope');

      expect(
        missing.swap().getOrElse(() => throw StateError('right')),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404),
      );
    });
  });

  group('cubits', () {
    test(
      'RecipesCubit pages, merges, and stops auto-paging after a failure',
      () async {
        final gate = _GatedGetRecipes();
        final cubit = RecipesCubit(gate);

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
      final cubit = RecipesCubit(gate);
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
      expect(cubit.state.status, RecipesStatus.loaded);
      await cubit.close();
    });

    test('RecipeDetailCubit: an unknown slug is "not found"', () async {
      final cubit = RecipeDetailCubit(
        _StubGetRecipeDetail(
          const Left(ServerFailure('Recipe not found', statusCode: 404)),
        ),
        slug: 'nope',
      );

      await cubit.load();

      expect(cubit.state.isNotFound, isTrue);
      await cubit.close();
    });
  });
}
