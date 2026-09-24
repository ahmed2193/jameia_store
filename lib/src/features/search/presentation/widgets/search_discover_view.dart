import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../cubit/search_state.dart';
import 'search_discover_section.dart';

/// The search screen before the customer types: recent terms (device), the
/// store's top-level categories and its brands (backend). Each block hides
/// itself while it is empty.
class SearchDiscoverView extends StatelessWidget {
  const SearchDiscoverView({
    super.key,
    required this.state,
    required this.onTerm,
    required this.onClearRecents,
  });

  final SearchState state;

  /// Runs a recent term again.
  final ValueChanged<String> onTerm;
  final VoidCallback onClearRecents;

  @override
  Widget build(BuildContext context) {
    final recents = state.recents.terms;
    final categories = state.discover.categories;
    final brands = state.discover.brands;
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      children: [
        SearchDiscoverSection(
          title: 'search.recent'.tr(),
          labels: recents,
          onTapIndex: (index) => onTerm(recents[index]),
          actionLabel: 'search.clear_recent'.tr(),
          onAction: onClearRecents,
        ),
        SearchDiscoverSection(
          title: 'search.popular_categories'.tr(),
          labels: [for (final category in categories) category.name],
          onTapIndex: (index) => context.push(
            Routes.category,
            extra: CategoryArgs.of(categories[index]),
          ),
        ),
        SearchDiscoverSection(
          title: 'search.brands'.tr(),
          labels: [for (final brand in brands) brand.name],
          onTapIndex: (index) => context.push(
            Routes.productListing,
            extra: ProductListingArgs.brand(
              slug: brands[index].slug,
              title: brands[index].name,
            ),
          ),
        ),
      ],
    );
  }
}
