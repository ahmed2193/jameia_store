import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Text side of the savings card when no coupon is available yet.
class CouponsSummaryEmpty extends StatelessWidget {
  const CouponsSummaryEmpty({super.key});

  static const double _mutedAlpha = 0.88;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'coupons.summary_empty'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.white,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'coupons.summary_empty_hint'.tr(),
          style: AppTextStyles.bodyLarge.copyWith(color: _muted),
        ),
      ],
    );
  }
}
