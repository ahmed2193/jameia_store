import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import '../listing/product_listing_body.dart';
import 'categories_skeleton.dart';
import 'category_chips.dart';
import 'category_rail_header.dart';

/// Body of the store page. The tabs live in the app bar; here comes the
/// sub-category rail of the open tab, its chips and the products. The tree is
/// what the whole page is built from, so its bones (the rail over the grid,
/// cross-fading into the store) / error / empty state
/// replace the body — unlike a category page, where the products load on their
/// own and only the rows wait for the tree. With nothing saved and no
/// connection it is the "No connection" state, which loads the store by
/// itself when the connection returns.
class CategoriesBody extends StatelessWidget {
  const CategoriesBody({super.key, required this.onRefresh});

  /// Reloads the tree and the products.
  final Future<void> Function() onRefresh;

  /// Level 0 is the app bar's tab row.
  static const int _railLevel = 1;
  static const int _chipsLevel = 2;
  static const Object _emptyKey = #empty;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<CategoryBrowseCubit>().onReconnected(),
      child: BlocBuilder<CategoryBrowseCubit, CategoryBrowseState>(
        buildWhen: (previous, current) =>
            current.load.screenChangedFrom(previous.load) ||
            previous.isEmpty != current.isEmpty,
        builder: (context, state) {
          final cubit = context.read<CategoryBrowseCubit>();
          return FadeThroughSwitcher(
            // initial and loading share the bones. Every swap is the
            // same-place cross-fade: the bones land as the store.
            stateKey: switch (state.status) {
              LoadPhase.initial => LoadPhase.loading,
              LoadPhase.loaded when state.isEmpty => _emptyKey,
              final status => status,
            },
            crossFade: true,
            alignment: AlignmentDirectional.topCenter,
            child: switch (state.status) {
              LoadPhase.initial ||
              LoadPhase.loading => const CategoriesSkeleton(),
              LoadPhase.error => FailureView(
                failure: state.failure,
                onRetry: cubit.load,
              ),
              LoadPhase.loaded when state.isEmpty => HeroStateView(
                message: 'shop.no_categories'.tr(),
                art: HeroAssets.emptyShelf,
              ),
              LoadPhase.loaded => ProductListingBody(
                onRefresh: onRefresh,
                headerSlivers: const [
                  CategoryRailHeader(level: _railLevel),
                  SliverToBoxAdapter(child: CategoryChips(level: _chipsLevel)),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}
