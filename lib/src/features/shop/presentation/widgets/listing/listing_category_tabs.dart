import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/collection_frame.dart';
import '../../../../../core/widgets/collection_tabs_delegate.dart';
import '../../cubit/listing_tabs_state.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';

/// The pinned category tabs of a collection page ("All | Snacks & Chocolate |
/// Ice Cream"), as a sliver. The open tab follows the list's category scope;
/// a tap re-scopes the list. Tapped while the grid is scrolled under the
/// tabs, the page stays with the tabs pinned on top and the new list starting
/// right under them, instead of scrolling back to the hero.
class ListingCategoryTabs extends StatelessWidget {
  const ListingCategoryTabs({super.key, required this.tabs});

  final ListingTabsState tabs;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'shop.all'.tr(),
      for (final category in tabs.categories) category.name,
    ];
    return BlocSelector<ProductListingCubit, ProductListingState, String?>(
      selector: (state) => state.query.categorySlug,
      builder: (context, categorySlug) => SliverPersistentHeader(
        pinned: true,
        delegate: CollectionTabsDelegate(
          labels: labels,
          selected: tabs.tabOf(categorySlug),
          onSelected: (index) {
            _keepTabsPinned(context);
            context.read<ProductListingCubit>().setCategorySlug(
              tabs.slugAt(index),
            );
          },
        ),
      ),
    );
  }

  /// When the grid is scrolled past the hero, park the list exactly where
  /// the tabs pin under the top bar: the new list starts at its top and the
  /// hero stays out of view. Above that point nothing moves.
  static void _keepTabsPinned(BuildContext context) {
    final sliver = context.findRenderObject();
    final position = Scrollable.maybeOf(context)?.position;
    if (sliver is! RenderSliver || position == null || !position.hasPixels) {
      return;
    }
    // The pinned top bar above the tabs, status bar included.
    final pinsAt =
        sliver.constraints.precedingScrollExtent -
        CollectionFrame.pinnedExtent(context);
    if (position.pixels > pinsAt) position.jumpTo(pinsAt);
  }
}
