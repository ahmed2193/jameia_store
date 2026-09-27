import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/recipe_detail.dart';
import '../entities/recipes_feed.dart';

/// Recipes of the jm3eia backend (public routes). The first page of the list
/// and a recipe paint from the copy saved on the device first (offline too),
/// then the server's.
abstract class RecipesRepository {
  /// `GET /v1/recipes` — the FIRST page of [limit]: the saved copy, then the
  /// server's (skipped while the copy is fresh, unless [forceRefresh]).
  Stream<DataSnapshot<RecipesFeed>> watchRecipes({
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/recipes?page&limit` — one page (1-based). Never kept on the
  /// device.
  Future<Either<Failure, RecipesFeed>> getRecipes({
    required int page,
    required int limit,
  });

  /// `GET /v1/recipes/:slug`, like [watchRecipes]. An unknown slug is a
  /// `ServerFailure(statusCode: 404)` on the error channel.
  Stream<DataSnapshot<RecipeDetail>> watchRecipe(
    String slug, {
    bool forceRefresh = false,
  });
}
