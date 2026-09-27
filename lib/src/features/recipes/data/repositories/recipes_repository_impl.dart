import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recipe_detail.dart';
import '../../domain/entities/recipes_feed.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../datasources/recipes_cache_data_source.dart';
import '../datasources/recipes_remote_data_source.dart';
import '../mappers/recipes_mapper.dart';

class RecipesRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements RecipesRepository {
  const RecipesRepositoryImpl(this._remote, {required this._cache});

  final RecipesRemoteDataSource _remote;
  final RecipesCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<RecipesFeed>> watchRecipes({
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.list(limit: limit),
    fetch: () => _remote.getRecipes(page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, RecipesFeed>> getRecipes({
    required int page,
    required int limit,
  }) => execute(
    () async =>
        (await _remote.getRecipes(page: page, limit: limit)).model.toEntity(),
  );

  @override
  Stream<DataSnapshot<RecipeDetail>> watchRecipe(
    String slug, {
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.detail(slug),
    fetch: () => _remote.getRecipe(slug),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );
}
