import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_rail_header_delegate.dart';

/// The sub-category rail of a listing as a sliver that stays at the top of
/// the list: circles at rest, folded into a row of chips while scrolling,
/// unfolding again as soon as the customer scrolls back up
/// ([CategoryRailHeaderDelegate]). Takes no room while the open category has
/// no sub-categories.
class CategoryRailHeader extends StatelessWidget {
  const CategoryRailHeader({super.key, required this.level});

  /// The browse level the rail offers.
  final int level;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryBrowseCubit, CategoryBrowseState, bool>(
      selector: (state) => state.browse.optionsAt(level).isNotEmpty,
      builder: (context, hasOptions) => hasOptions
          ? SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: CategoryRailHeaderDelegate(level: level),
            )
          : const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
