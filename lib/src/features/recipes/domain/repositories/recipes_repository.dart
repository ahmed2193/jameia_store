import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/recipe_detail.dart';
import '../entities/recipes_feed.dart';

/// Recipes of the jm3eia backend (public routes).
abstract class RecipesRepository {
  /// `GET /v1/recipes?page&limit` — one page (1-based).
  Future<Either<Failure, RecipesFeed>> getRecipes({
    required int page,
    required int limit,
  });

  /// `GET /v1/recipes/:slug`. An unknown slug is
  /// `Left(ServerFailure(statusCode: 404))`.
  Future<Either<Failure, RecipeDetail>> getRecipe(String slug);
}
