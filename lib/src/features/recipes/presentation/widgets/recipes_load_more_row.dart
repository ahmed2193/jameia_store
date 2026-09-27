import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../../../../core/widgets/load_more_offline_note.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';

/// The end of the recipe list while the server has more: a loader while
/// the next page is coming, a retry after a failed one — offline, "More will
/// load when you're back" instead (the list asks again by itself on
/// reconnect) — nothing otherwise. It selects the next page's progress
/// itself, so the list above never rebuilds for it.
class RecipesLoadMoreRow extends StatelessWidget {
  const RecipesLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecipesCubit, RecipesState, NextPageLoad>(
      selector: (state) => state.load.nextPage,
      builder: (context, nextPage) => switch (nextPage) {
        NextPageLoad.idle => const SizedBox.shrink(),
        NextPageLoad.loading => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: AppLoader.inline(),
        ),
        NextPageLoad.failed when ConnectivityScope.isOfflineOf(context) =>
          const LoadMoreOfflineNote(),
        NextPageLoad.failed => Center(
          child: TextButton(
            onPressed: () => context.read<RecipesCubit>().loadMore(retry: true),
            child: Text('retry'.tr()),
          ),
        ),
      },
    );
  }
}
