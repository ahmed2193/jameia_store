import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Green "Save X" chip under the price of a discounted product.
class CatalogSaveBadge extends StatelessWidget {
  const CatalogSaveBadge({super.key, required this.amountKd});

  final double amountKd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        'catalog.save_amount'.tr(
          namedArgs: {'amount': Formatters.price(amountKd)},
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.success,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
