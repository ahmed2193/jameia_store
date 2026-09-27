import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/recipe_models.dart';

/// The recipes as last shown — the first page of the list and each recipe
/// opened, per language. Public: the same for every customer. Parsed back
/// with the DTOs' own `fromJson`.
abstract class RecipesCacheDataSource {
  /// `GET /v1/recipes` — the first page of [limit].
  CacheSlot<RecipesPageModel>? list({required int limit});

  /// `GET /v1/recipes/:slug`.
  CacheSlot<RecipeDetailModel>? detail(String slug);
}

class RecipesCacheDataSourceImpl implements RecipesCacheDataSource {
  const RecipesCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  static const CacheNamespace listNamespace = CacheNamespace(
    'recipes.list',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
  );

  /// One entry per recipe (and language): the oldest go past 40.
  static const CacheNamespace detailNamespace = CacheNamespace(
    'recipes.detail',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
    maxEntries: 40,
  );

  @override
  CacheSlot<RecipesPageModel>? list({required int limit}) => _slots.of(
    listNamespace,
    id: '$limit',
    parse: (raw) => RecipesPageModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.recipes),
      requestedPage: _firstPage,
    ),
  );

  @override
  CacheSlot<RecipeDetailModel>? detail(String slug) => _slots.of(
    detailNamespace,
    id: slug,
    parse: (raw) => RecipeDetailModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.recipe(slug)),
    ),
  );
}
