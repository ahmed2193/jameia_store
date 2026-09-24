import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../domain/entities/recipe_detail.dart';
import '../../domain/entities/recipes_feed.dart';
import '../models/recipe_models.dart';

/// [RecipesPageModel] (wire) → [RecipesFeed].
extension RecipesPageMapper on RecipesPageModel {
  RecipesFeed toEntity() =>
      RecipesFeed(recipes: items.toEntities(), page: page, hasMore: hasMore);
}

/// [RecipeDetailModel] (wire) → [RecipeDetail]; steps in cooking order.
extension RecipeDetailMapper on RecipeDetailModel {
  RecipeDetail toEntity() {
    final ordered = steps.toList()..sort((a, b) => a.order.compareTo(b.order));
    return RecipeDetail(
      summary: summary.toEntity(),
      ingredients: [
        for (final ingredient in ingredients)
          RecipeIngredient(
            id: ingredient.id,
            product: ingredient.product.toEntity(),
            // The cart holds whole units: round a fractional quantity up, and
            // never below one.
            purchaseQuantity: ingredient.purchaseQty < 1
                ? 1
                : ingredient.purchaseQty.ceil(),
            useQuantity: ingredient.useQty,
            note: ingredient.note,
          ),
      ],
      steps: [
        for (final (index, step) in ordered.indexed)
          RecipeStep(
            id: step.id,
            order: step.order > 0 ? step.order : index + 1,
            body: step.body,
            durationMinutes: step.durationMin,
          ),
      ],
    );
  }
}
