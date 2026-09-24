import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';

/// One ingredient of a recipe: a real product of the store, how much the dish
/// uses and how many units the customer has to buy for it.
class RecipeIngredient extends Equatable {
  const RecipeIngredient({
    required this.id,
    required this.product,
    this.purchaseQuantity = 1,
    this.useQuantity = 0,
    this.note = '',
  });

  final String id;
  final CatalogProductEntity product;

  /// Whole units to put in the cart (at least one).
  final int purchaseQuantity;

  /// What the dish actually uses, in the product's unit of sale.
  final double useQuantity;
  final String note;

  /// Can go into the cart in one tap (in stock, not a variant product).
  bool get canAddToCart => product.canQuickAdd;

  @override
  List<Object?> get props => [id, product, purchaseQuantity, useQuantity, note];
}

class RecipeStep extends Equatable {
  const RecipeStep({
    required this.id,
    required this.order,
    required this.body,
    this.durationMinutes = 0,
  });

  final String id;

  /// 1-based position.
  final int order;
  final String body;

  /// `0` = the backend gave no duration.
  final int durationMinutes;

  @override
  List<Object?> get props => [id, order, body, durationMinutes];
}

/// A recipe page (`GET /v1/recipes/:slug`).
class RecipeDetail extends Equatable {
  const RecipeDetail({
    required this.summary,
    this.ingredients = const <RecipeIngredient>[],
    this.steps = const <RecipeStep>[],
  });

  final RecipeSummaryEntity summary;
  final List<RecipeIngredient> ingredients;

  /// In cooking order.
  final List<RecipeStep> steps;

  /// The ingredients "add all to cart" can add right now.
  List<RecipeIngredient> get purchasableIngredients => [
    for (final ingredient in ingredients)
      if (ingredient.canAddToCart) ingredient,
  ];

  @override
  List<Object?> get props => [summary, ingredients, steps];
}
