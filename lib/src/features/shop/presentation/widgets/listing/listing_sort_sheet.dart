import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../../core/responsive/app_size.dart';
import 'listing_sort_label.dart';

/// Bottom sheet listing the product orderings. Pops with a record so "the
/// backend's default" (`null`) is distinguishable from a dismissed sheet.
class ListingSortSheet extends StatelessWidget {
  const ListingSortSheet({super.key, required this.selected});

  final CatalogProductSort? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              child: Text(
                'shop.sort_by'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
            for (final option in ListingSortLabel.options)
              InkWell(
                onTap: () => context.pop((sort: option)),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ListingSortLabel.keyOf(option).tr(),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: option == selected
                                ? AppTextStyles.bold
                                : AppTextStyles.regular,
                          ),
                        ),
                      ),
                      if (option == selected)
                        const Icon(
                          Icons.check_rounded,
                          size: AppSize.s20,
                          color: AppColors.primaryDark,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
