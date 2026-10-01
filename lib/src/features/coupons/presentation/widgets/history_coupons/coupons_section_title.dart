import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';

/// Bold heading above a group of history coupons ("Used", "Expired") with
/// how many there are; it rises in once, when it first scrolls into view.
class CouponsSectionTitle extends StatelessWidget {
  const CouponsSectionTitle({
    super.key,
    required this.text,
    required this.count,
  });

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: ScrollReveal(
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.sectionTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s2,
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
