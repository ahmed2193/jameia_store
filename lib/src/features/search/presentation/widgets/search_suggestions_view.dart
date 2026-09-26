import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/search_state.dart';
import 'search_see_all_row.dart';
import 'search_suggestion_skeleton.dart';
import 'search_suggestion_tile.dart';
import 'search_term_row.dart';

/// What shows while the customer types: past terms that match, the live
/// product matches (bone rows until the first reply arrives, a thin bar while
/// a newer request runs) and, last, "see all results" for the text as typed.
class SearchSuggestionsView extends StatelessWidget {
  const SearchSuggestionsView({
    super.key,
    required this.state,
    required this.onSearch,
    required this.onRefine,
    required this.onOpenProduct,
  });

  final SearchState state;

  /// Commits a term as a search (a past term, or the text as typed).
  final ValueChanged<String> onSearch;

  /// Copies a past term into the field to go on typing.
  final ValueChanged<String> onRefine;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    final query = state.query;
    // The bar is the only looping motion here: off under reduced motion.
    final showProgress = state.isSuggesting && !MotionGuard.reduced(context);
    return Column(
      children: [
        SizedBox(
          height: AppSize.s2,
          child: showProgress
              ? const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.brandLightBg,
                )
              : null,
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s4,
              bottom: AppSpacing.section,
            ),
            children: [
              for (final term in state.recentMatches)
                SearchTermRow(
                  key: ValueKey<String>('term:$term'),
                  term: term,
                  query: query,
                  onTap: () => onSearch(term),
                  onRefine: () => onRefine(term),
                ),
              if (state.isAwaitingSuggestions)
                const SearchSuggestionSkeleton()
              else
                for (final product in state.suggestions)
                  SearchSuggestionTile(
                    key: ValueKey<String>(product.id),
                    product: product,
                    query: query,
                    pro: isPro,
                    onTap: () => onOpenProduct(product),
                  ),
              SearchSeeAllRow(
                query: query.trim(),
                onTap: () => onSearch(query),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
