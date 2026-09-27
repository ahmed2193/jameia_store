import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';
import 'recipe_list_tile.dart';
import 'recipes_load_more_row.dart';

/// Body of the recipe list: loader, the lazily built paginated list (the
/// saved first page at once, with the "Updated … ago" note while offline),
/// empty, error + retry or "No connection" when nothing is saved. A failed
/// refresh or page keeps the list and shows a snack bar (never offline: the
/// banner speaks); the footer offers the retry, or says more will load when
/// the connection returns — which refreshes what failed.
class RecipesBody extends StatelessWidget {
  const RecipesBody({super.key});

  static const double _loadMoreThreshold = AppSize.s500;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<RecipesCubit>().onReconnected(),
      child: ScreenFailureListener<RecipesCubit, RecipesState>(
        child: BlocBuilder<RecipesCubit, RecipesState>(
          // A new freshness, a transient failure or the next page's progress
          // (its row selects that itself) change nothing in the list.
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.feed != current.feed,
          builder: (context, state) {
            final cubit = context.read<RecipesCubit>();
            switch (state.status) {
              case LoadPhase.initial:
              case LoadPhase.loading:
                return const AppLoader();
              case LoadPhase.error:
                return FailureView(failure: state.failure, onRetry: cubit.load);
              case LoadPhase.loaded:
                if (state.isEmpty) {
                  return BrandedRefresh(
                    onRefresh: cubit.refresh,
                    child: EmptyStateView(
                      message: 'recipes.empty'.tr(),
                      icon: Icons.soup_kitchen_outlined,
                    ),
                  );
                }
                final recipes = state.feed.recipes;
                final hasFooter = state.feed.hasMore;
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
                          return const ScreenStaleNotice<
                            RecipesCubit,
                            RecipesState
                          >();
                        }
                        final index = position - 1;
                        if (index >= recipes.length) {
                          return const RecipesLoadMoreRow();
                        }
                        final recipe = recipes[index];
                        return RecipeListTile(
                          key: ValueKey(recipe.id),
                          recipe: recipe,
                          onTap: () =>
                              context.push(Routes.recipe, extra: recipe.slug),
                        );
                      },
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
