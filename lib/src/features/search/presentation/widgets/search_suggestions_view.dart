import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/search_state.dart';
import 'search_suggestion_tile.dart';

/// What shows while the customer types: a "see all results" row for the text
/// as it is, then the live product matches (a thin progress bar while a
/// request is pending).
class SearchSuggestionsView extends StatelessWidget {
  const SearchSuggestionsView({
    super.key,
    required this.state,
    required this.onOpenProduct,
    required this.onSeeAll,
  });

  final SearchState state;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  /// Commits the typed text as a search.
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    final suggestions = state.suggestions;
    return ListView.builder(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      itemCount: suggestions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppSize.s2,
                child: state.isSuggesting
                    ? const LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.brandLightBg,
                      )
                    : null,
              ),
              InkWell(
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: AppSize.s20,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Text(
                          'search.see_all_results'.tr(
                            namedArgs: {'query': state.query.trim()},
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: AppSize.s20,
                        color: AppColors.tertiaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        final product = suggestions[index - 1];
        return SearchSuggestionTile(
          key: ValueKey(product.id),
          product: product,
          query: state.query,
          pro: isPro,
          onTap: () => onOpenProduct(product),
        );
      },
    );
  }
}
