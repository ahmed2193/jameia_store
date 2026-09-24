import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipe_detail_cubit.dart';
import '../cubit/recipe_detail_state.dart';
import 'recipe_detail_view.dart';

/// Switches the recipe page on the cubit state: loader, the recipe, "not
/// found" for an unknown slug, error + retry (offline = the error view). A
/// failed reload keeps the recipe and shows a snack bar.
class RecipeDetailBody extends StatelessWidget {
  const RecipeDetailBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipeDetailCubit, RecipeDetailState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
      buildWhen: (previous, current) =>
          previous.status != current.status ||
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
        if (state.status == RecipeDetailStatus.error) {
          return SafeArea(
            child: ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: context.read<RecipeDetailCubit>().load,
            ),
          );
        }
        return const SafeArea(child: AppLoader());
      },
    );
  }
}
