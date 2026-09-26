import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../cubit/search_state.dart';
import 'search_brands_section.dart';
import 'search_categories_section.dart';
import 'search_recents_section.dart';

/// The search screen before the customer types: recent terms (device), the
/// store's top-level categories and its brands (backend). A block with
/// nothing to show is left out. Dragging the list puts the keyboard away.
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.section),
      children: [
        if (recents.isNotEmpty)
          SearchRecentsSection(
            terms: recents,
            onTerm: onTerm,
            onClear: onClearRecents,
          ),
        if (categories.isNotEmpty)
          SearchCategoriesSection(categories: categories),
        if (brands.isNotEmpty) SearchBrandsSection(brands: brands),
      ],
    );
  }
}
