import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// What a Pro member would pay, for a customer who is not one yet: a small
/// "pro" tag and the Pro price on a soft Pro wash.
class ShelfProPriceChip extends StatelessWidget {
  const ShelfProPriceChip({super.key, required this.priceKd});

  final double priceKd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s6,
        AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentVioletLight,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s4,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentViolet,
              borderRadius: BorderRadius.circular(AppRadius.r7),
            ),
            child: Text(
              'shop.pro_tag'.tr(),
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.white,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              Formatters.price(priceKd),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accentViolet,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
