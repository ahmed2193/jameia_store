import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/utils/formatters.dart';

/// One option of a variant product ("1 L · KD 0.499"). An option that cannot
/// be bought is struck through and does not react.
class PdpVariantChip extends StatelessWidget {
  const PdpVariantChip({
    super.key,
    required this.variant,
    required this.selected,
    required this.pro,
    required this.onTap,
  });

  final CatalogVariantEntity variant;
  final bool selected;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = variant.isAvailable;
    final foreground = !available
        ? AppColors.disabledText
        : selected
        ? AppColors.primaryDark
        : AppColors.primaryText;
    return GestureDetector(
      onTap: available ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLightBg : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r5),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              variant.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: foreground,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
                decoration: available ? null : TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              Formatters.price(variant.priceKdFor(pro: pro)),
              style: AppTextStyles.captionLarge.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
