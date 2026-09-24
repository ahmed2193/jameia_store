import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/models/recipe_summary_model.dart';
import '../../../../core/error/exceptions.dart';

/// `results` of `GET /v1/recipes`: `{ data: [Recipe], pagination }`.
class RecipesPageModel {
  const RecipesPageModel({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String pageKey = 'page';
  static const String hasMoreKey = 'hasMore';
  static const String _logName = 'RecipesPageModel';

  /// [requestedPage] fills in when the backend omits `pagination`. A malformed
  /// row is skipped.
  factory RecipesPageModel.fromJson(
    Map<String, dynamic> json, {
    int requestedPage = 1,
  }) {
    final data = json[dataKey];
    if (data is! List) throw const ParsingException('recipes: data missing');
    final pagination =
        JsonRead.object(json[paginationKey]) ?? const <String, dynamic>{};
    return RecipesPageModel(
      items: JsonRead.rows(
        data,
        RecipeSummaryModel.fromJson,
        logName: _logName,
      ),
      page: JsonRead.integer(pagination[pageKey]) ?? requestedPage,
      hasMore: JsonRead.flag(pagination[hasMoreKey]),
    );
  }

  final List<RecipeSummaryModel> items;
  final int page;
  final bool hasMore;
}

/// `results` of `GET /v1/recipes/:slug`: the recipe card fields plus
/// `ingredients[]` and `steps[]`.
class RecipeDetailModel {
  const RecipeDetailModel({
    required this.summary,
    this.ingredients = const <RecipeIngredientModel>[],
    this.steps = const <RecipeStepModel>[],
  });

  static const String ingredientsKey = 'ingredients';
  static const String stepsKey = 'steps';
  static const String _logName = 'RecipeDetailModel';

  /// Throws [ParsingException] when the recipe itself has no id / slug; a
  /// malformed ingredient or step is skipped.
  factory RecipeDetailModel.fromJson(Map<String, dynamic> json) =>
      RecipeDetailModel(
        summary: RecipeSummaryModel.fromJson(json),
        ingredients: JsonRead.rows(
          json[ingredientsKey],
          RecipeIngredientModel.fromJson,
          logName: _logName,
        ),
        steps: JsonRead.rows(
          json[stepsKey],
          RecipeStepModel.fromJson,
          logName: _logName,
        ),
      );

  final RecipeSummaryModel summary;
  final List<RecipeIngredientModel> ingredients;
  final List<RecipeStepModel> steps;
}

/// One row of `ingredients[]`:
/// `{ id, productId, purchaseQty, useQty, useUnitOfSale, note?, product }`.
class RecipeIngredientModel {
  const RecipeIngredientModel({
    required this.id,
    required this.product,
    this.purchaseQty = 1,
    this.useQty = 0,
    this.note = '',
  });

  static const String idKey = 'id';
  static const String productKey = 'product';
  static const String purchaseQtyKey = 'purchaseQty';
  static const String useQtyKey = 'useQty';
  static const String noteKey = 'note';

  /// Throws [ParsingException] without the nested product (nothing to show or
  /// to buy).
  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    final product = JsonRead.object(json[productKey]);
    if (product == null) {
      throw const ParsingException('recipe ingredient: product missing');
    }
    final model = ProductModel.fromJson(product);
    return RecipeIngredientModel(
      id: JsonRead.string(json[idKey]) ?? model.id,
      product: model,
      purchaseQty: JsonRead.decimal(json[purchaseQtyKey]) ?? 1,
      useQty: JsonRead.decimal(json[useQtyKey]) ?? 0,
      note: JsonRead.string(json[noteKey]) ?? '',
    );
  }

  final String id;
  final ProductModel product;

  /// A number on the wire (may be fractional for weighed goods).
  final double purchaseQty;
  final double useQty;
  final String note;
}

/// One row of `steps[]`: `{ id, order, body, durationMin? }`.
class RecipeStepModel {
  const RecipeStepModel({
    required this.id,
    required this.body,
    this.order = 0,
    this.durationMin = 0,
  });

  static const String idKey = 'id';
  static const String orderKey = 'order';
  static const String bodyKey = 'body';
  static const String durationMinKey = 'durationMin';

  /// Throws [ParsingException] without text (an empty step is noise).
  factory RecipeStepModel.fromJson(Map<String, dynamic> json) {
    final body = JsonRead.string(json[bodyKey]);
    if (body == null) throw const ParsingException('recipe step: body missing');
    final order = JsonRead.integer(json[orderKey]) ?? 0;
    return RecipeStepModel(
      id: JsonRead.string(json[idKey]) ?? '$order',
      body: body,
      order: order,
      durationMin: JsonRead.integer(json[durationMinKey]) ?? 0,
    );
  }

  final String id;
  final String body;
  final int order;
  final int durationMin;
}
