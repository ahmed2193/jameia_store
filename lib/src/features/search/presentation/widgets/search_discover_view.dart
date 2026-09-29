import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/widgets/failure_view.dart';
import '../cubit/search_state.dart';
import 'search_brands_section.dart';
import 'search_categories_section.dart';
import 'search_discover_skeleton.dart';
import 'search_recents_section.dart';

/// The search screen before the customer types: recent terms (device), the
/// store's top-level categories and its brands (backend). A block with
/// nothing to show is left out. While neither block has anything yet their
/// skeleton shows and cross-fades into them; when both failed with nothing
/// saved and no recent terms, the failure view says why (offline: the
/// connection check first) and [onRetry] reads them again. Dragging the list
/// puts the keyboard away.
class SearchDiscoverView extends StatelessWidget {
  const SearchDiscoverView({
    super.key,
    required this.state,
    required this.onTerm,
    required this.onClearRecents,
    required this.onRetry,
  });

  final SearchState state;

  /// Runs a recent term again.
  final ValueChanged<String> onTerm;
  final VoidCallback onClearRecents;

  /// Reads the discover blocks again (the failure view's Retry).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final recents = state.recents.terms;
    final categories = state.discover.categories;
    final brands = state.discover.brands;
    final failure = recents.isEmpty ? state.discoverFailure : null;
    return FadeThroughSwitcher(
      stateKey: failure != null,
      crossFade: true,
      alignment: AlignmentDirectional.topCenter,
      child: failure != null
          ? FailureView(failure: failure, onRetry: onRetry)
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.only(
                bottom: AppSpacing.section,
              ),
              children: [
                if (recents.isNotEmpty)
                  SearchRecentsSection(
                    terms: recents,
                    onTerm: onTerm,
                    onClear: onClearRecents,
                  ),
                // Only the blocks swap: the recent terms above stay put.
                FadeThroughSwitcher(
                  stateKey: state.isDiscoverLoading,
                  crossFade: true,
                  alignment: AlignmentDirectional.topCenter,
                  child: state.isDiscoverLoading
                      ? const SearchDiscoverSkeleton()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (categories.isNotEmpty)
                              SearchCategoriesSection(categories: categories),
                            if (brands.isNotEmpty)
                              SearchBrandsSection(brands: brands),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
