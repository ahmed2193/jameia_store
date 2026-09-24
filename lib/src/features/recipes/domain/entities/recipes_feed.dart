import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/recipe_summary_entity.dart';

/// The recipes loaded so far (`GET /v1/recipes`, pages merged in order).
class RecipesFeed extends Equatable {
  const RecipesFeed({
    required this.recipes,
    required this.page,
    required this.hasMore,
  });

  static const RecipesFeed empty = RecipesFeed(
    recipes: <RecipeSummaryEntity>[],
    page: 0,
    hasMore: false,
  );

  final List<RecipeSummaryEntity> recipes;

  /// Last page merged in (1-based); `0` before the first load.
  final int page;
  final bool hasMore;

  bool get isEmpty => recipes.isEmpty;

  /// Appends [next] (a later page), dropping recipes already shown.
  RecipesFeed merge(RecipesFeed next) {
    final known = {for (final recipe in recipes) recipe.id};
    return RecipesFeed(
      recipes: [
        ...recipes,
        ...next.recipes.where((recipe) => !known.contains(recipe.id)),
      ],
      page: next.page,
      hasMore: next.hasMore,
    );
  }

  @override
  List<Object?> get props => [recipes, page, hasMore];
}
