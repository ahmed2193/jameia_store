import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/widgets/collection_frame.dart';
import '../../../../../core/widgets/countdown_chip.dart';
import '../../cubit/listing_tabs_cubit.dart';
import '../../cubit/listing_tabs_state.dart';
import 'catalog_cart_bar.dart';
import 'listing_category_tabs.dart';
import 'product_listing_body.dart';

/// A collection or a brand as a talabat collection page: the store's name in
/// a top bar that turns white as the tinted hero (heading, emoji, line, a
/// flash sale's countdown) scrolls away, the category tabs pinned under it
/// once at least two categories have products, the grid with no sort /
/// filter toolbar, and the "View cart" pill.
class ListingCollectionScaffold extends StatelessWidget {
  const ListingCollectionScaffold({super.key, required this.args});

  final ProductListingArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListingTabsCubit, ListingTabsState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories,
      builder: (context, tabs) => CollectionFrame(
        storeName: 'core.store_name'.tr(),
        heading: args.title,
        emoji: args.emoji,
        subtitle: args.subtitle.isEmpty ? null : args.subtitle,
        heroTrailing: switch (args.endsAt) {
          final endsAt? when endsAt.isAfter(DateTime.now()) => CountdownChip(
            endsAt: endsAt,
          ),
          _ => null,
        },
        onBack: context.canPop() ? () => context.pop() : null,
        onSearch: () => context.push(Routes.search),
        tabs: tabs.showsTabs ? ListingCategoryTabs(tabs: tabs) : null,
        bottomBar: const CatalogCartBar(),
        bodyBuilder: (context, headerSlivers) => ProductListingBody(
          headerSlivers: headerSlivers,
          showsToolbar: false,
          reservesViewportWhileLoading: true,
          refreshEdgeOffset: CollectionFrame.pinnedExtent(context),
        ),
      ),
    );
  }
}
