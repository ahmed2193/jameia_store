import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/recipe_models.dart';

/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only. Replies come
/// back with their raw `results`, which the repository keeps on the device
/// as sent (the first page, a recipe).
abstract class RecipesRemoteDataSource {
  /// `GET /v1/recipes?page&limit`.
  Future<RemotePayload<RecipesPageModel>> getRecipes({
    required int page,
    required int limit,
  });

  /// `GET /v1/recipes/:slug` — `404 RESOURCE_NOT_FOUND` for an unknown slug.
  Future<RemotePayload<RecipeDetailModel>> getRecipe(String slug);
}

class RecipesRemoteDataSourceImpl implements RecipesRemoteDataSource {
  const RecipesRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';

  @override
  Future<RemotePayload<RecipesPageModel>> getRecipes({
    required int page,
    required int limit,
  }) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.recipes,
        queryParameters: <String, dynamic>{pageField: page, limitField: limit},
      ),
      EndPoints.recipes,
    );
    return RemotePayload(
      RecipesPageModel.fromJson(results, requestedPage: page),
      results,
    );
  }

  @override
  Future<RemotePayload<RecipeDetailModel>> getRecipe(String slug) async {
    final path = EndPoints.recipe(slug);
    final results = ApiPayload.asMap(await _api.get(path), path);
    return RemotePayload(RecipeDetailModel.fromJson(results), results);
  }
}
