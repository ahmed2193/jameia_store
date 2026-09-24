import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/recipe_models.dart';

/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only.
abstract class RecipesRemoteDataSource {
  /// `GET /v1/recipes?page&limit`.
  Future<RecipesPageModel> getRecipes({required int page, required int limit});

  /// `GET /v1/recipes/:slug` — `404 RESOURCE_NOT_FOUND` for an unknown slug.
  Future<RecipeDetailModel> getRecipe(String slug);
}

class RecipesRemoteDataSourceImpl implements RecipesRemoteDataSource {
  const RecipesRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';

  @override
  Future<RecipesPageModel> getRecipes({
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.recipes,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return RecipesPageModel.fromJson(
      ApiPayload.asMap(results, EndPoints.recipes),
      requestedPage: page,
    );
  }

  @override
  Future<RecipeDetailModel> getRecipe(String slug) async {
    final path = EndPoints.recipe(slug);
    final results = await _api.get(path);
    return RecipeDetailModel.fromJson(ApiPayload.asMap(results, path));
  }
}
