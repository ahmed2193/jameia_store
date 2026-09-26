import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// The last suggestion row: "See all results for “…”" with a chevron — the
/// same as the keyboard's search key. Read as one element.
class SearchSeeAllRow extends StatelessWidget {
  const SearchSeeAllRow({super.key, required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.s56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: AppSize.s24,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Text(
                      'search.see_all_results'.tr(namedArgs: {'query': query}),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.itemTitleStrong,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppSize.s24,
                    color: AppColors.tertiaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
