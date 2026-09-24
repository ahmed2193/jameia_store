import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recipe_detail.dart';
import '../../domain/entities/recipes_feed.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../datasources/recipes_remote_data_source.dart';
import '../mappers/recipes_mapper.dart';

class RecipesRepositoryImpl
    with BaseRepositoryMixin
    implements RecipesRepository {
  const RecipesRepositoryImpl(this._remote);

  final RecipesRemoteDataSource _remote;

  @override
  Future<Either<Failure, RecipesFeed>> getRecipes({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getRecipes(page: page, limit: limit)).toEntity(),
  );

  @override
  Future<Either<Failure, RecipeDetail>> getRecipe(String slug) =>
      execute(() async => (await _remote.getRecipe(slug)).toEntity());
}
