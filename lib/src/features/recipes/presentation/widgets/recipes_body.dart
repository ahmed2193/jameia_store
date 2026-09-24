import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';
import 'recipe_list_tile.dart';

/// Body of the recipe list: loader, the lazily built paginated list, empty,
/// error + retry (offline = the error view). A failed refresh or page keeps
/// the list and shows a snack bar; the footer offers the retry.
class RecipesBody extends StatelessWidget {
  const RecipesBody({super.key});

  static const double _loadMoreThreshold = AppSize.s500;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipesCubit, RecipesState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
      builder: (context, state) {
        final cubit = context.read<RecipesCubit>();
        switch (state.status) {
          case RecipesStatus.initial:
          case RecipesStatus.loading:
            return const AppLoader();
          case RecipesStatus.error:
            return ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: cubit.load,
            );
          case RecipesStatus.loaded:
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
            final hasFooter = state.isLoadingMore || state.loadMoreFailed;
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
                  itemCount: recipes.length + (hasFooter ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= recipes.length) {
                      return state.loadMoreFailed
                          ? Center(
                              child: TextButton(
                                onPressed: () => cubit.loadMore(retry: true),
                                child: Text('retry'.tr()),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.all(AppSpacing.s16),
                              child: AppLoader(),
                            );
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
    );
  }
}
