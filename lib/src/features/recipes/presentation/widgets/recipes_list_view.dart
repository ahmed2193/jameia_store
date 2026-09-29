import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../domain/entities/recipes_feed.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';
import 'recipe_list_tile.dart';
import 'recipes_load_more_row.dart';

/// The loaded recipes as a lazily built, pull-to-refresh list: the
/// "Updated … ago" note first, then the recipes, then the next page's
/// footer while the server has more (asked for as the end comes near).
class RecipesListView extends StatelessWidget {
  const RecipesListView({super.key, required this.feed});

  final RecipesFeed feed;

  static const double _loadMoreThreshold = AppSize.s500;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecipesCubit>();
    final recipes = feed.recipes;
    final hasFooter = feed.hasMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadMoreThreshold) {
          cubit.loadMore();
        }
        return false;
      },
      child: BrandedRefresh(
        onRefresh: cubit.refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.s12,
            bottom: AppSpacing.s24,
          ),
          // The note first, then the recipes, then the footer.
          itemCount: recipes.length + 1 + (hasFooter ? 1 : 0),
          itemBuilder: (context, position) {
            if (position == 0) {
              return const ScreenStaleNotice<RecipesCubit, RecipesState>();
            }
            final index = position - 1;
            if (index >= recipes.length) return const RecipesLoadMoreRow();
            final recipe = recipes[index];
            return RecipeListTile(
              key: ValueKey(recipe.id),
              recipe: recipe,
              onTap: () => context.push(Routes.recipe, extra: recipe.slug),
            );
          },
        ),
      ),
    );
  }
}
