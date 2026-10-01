import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/load_more_offline_note.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';

/// The end of the recipe list while the server has more: the shared
/// [LoadMoreFooter] — dots while the next page is coming, the retry pill
/// after a failed one — offline, "More will load when you're back" instead
/// (the list asks again by itself on reconnect) — nothing otherwise. It
/// selects the next page's progress itself, so the list above never
/// rebuilds for it.
class RecipesLoadMoreRow extends StatelessWidget {
  const RecipesLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecipesCubit, RecipesState, NextPageLoad>(
      selector: (state) => state.load.nextPage,
      builder: (context, nextPage) {
        final failed = nextPage == NextPageLoad.failed;
        if (failed && ConnectivityScope.isOfflineOf(context)) {
          return const LoadMoreOfflineNote();
        }
        if (nextPage == NextPageLoad.idle) return const SizedBox.shrink();
        return LoadMoreFooter(
          failed: failed,
          onRetry: () => context.read<RecipesCubit>().loadMore(retry: true),
        );
      },
    );
  }
}
