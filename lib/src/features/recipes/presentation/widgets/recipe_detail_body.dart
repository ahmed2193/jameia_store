import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipe_detail_cubit.dart';
import '../cubit/recipe_detail_state.dart';
import 'recipe_detail_view.dart';

/// Switches the recipe page on the cubit state: loader, the recipe (the
/// saved one at once, offline too), "not found" for an unknown slug, error +
/// retry or "No connection" when nothing is saved. A failed reload keeps the
/// recipe and shows a snack bar (never offline: the banner speaks); a
/// returning connection refreshes a saved or failed recipe.
class RecipeDetailBody extends StatelessWidget {
  const RecipeDetailBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<RecipeDetailCubit>().onReconnected(),
      child: ScreenFailureListener<RecipeDetailCubit, RecipeDetailState>(
        child: BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.detail != current.detail,
          builder: (context, state) {
            final detail = state.detail;
            if (detail != null) return RecipeDetailView(detail: detail);
            if (state.isNotFound) {
              return SafeArea(
                child: EmptyStateView(
                  message: 'recipes.not_found'.tr(),
                  icon: Icons.soup_kitchen_outlined,
                  actionLabel: 'common.back'.tr(),
                  onAction: () => context.pop(),
                ),
              );
            }
            if (state.status == LoadPhase.error) {
              return SafeArea(
                child: FailureView(
                  failure: state.failure,
                  onRetry: context.read<RecipeDetailCubit>().load,
                ),
              );
            }
            return const SafeArea(child: AppLoader());
          },
        ),
      ),
    );
  }
}
