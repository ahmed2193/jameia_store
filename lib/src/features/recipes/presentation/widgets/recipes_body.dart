import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hero_assets.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/recipes_cubit.dart';
import '../cubit/recipes_state.dart';
import 'recipes_list_view.dart';
import 'recipes_skeleton.dart';

/// Body of the recipe list: the rows' bones on a first load with nothing
/// saved (cross-fading into the list), the lazily built paginated list (the
/// saved first page at once, with the "Updated … ago" note while offline),
/// empty, error + retry or "No connection" when nothing is saved. A failed
/// refresh or page keeps the list and shows a snack bar (never offline: the
/// banner speaks); the footer offers the retry, or says more will load when
/// the connection returns — which refreshes what failed.
class RecipesBody extends StatelessWidget {
  const RecipesBody({super.key});

  static const Object _emptyKey = #empty;

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
            return FadeThroughSwitcher(
              // initial and loading share the bones. Every swap is the
              // same-place cross-fade: the bones land as the list.
              stateKey: switch (state.status) {
                LoadPhase.initial => LoadPhase.loading,
                LoadPhase.loaded when state.isEmpty => _emptyKey,
                final status => status,
              },
              crossFade: true,
              child: switch (state.status) {
                LoadPhase.initial ||
                LoadPhase.loading => const RecipesSkeleton(),
                LoadPhase.error => FailureView(
                  failure: state.failure,
                  onRetry: cubit.load,
                ),
                LoadPhase.loaded when state.isEmpty => BrandedRefresh(
                  onRefresh: cubit.refresh,
                  child: HeroStateView(
                    message: 'recipes.empty'.tr(),
                    art: HeroAssets.emptyShelf,
                  ),
                ),
                LoadPhase.loaded => RecipesListView(feed: state.feed),
              },
            );
          },
        ),
      ),
    );
  }
}
