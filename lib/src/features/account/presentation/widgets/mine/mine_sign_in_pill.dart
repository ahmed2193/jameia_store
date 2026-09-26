import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'mine_header_metrics.dart';

/// The guest's "Sign in" pill under the header pitch. Visual only — the
/// whole header is the button (it opens the login page). [opacity] fades its
/// colours as the header collapses.
class MineSignInPill extends StatelessWidget {
  const MineSignInPill({super.key, this.opacity = 1});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MineHeaderMetrics.cta,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      // Hugs its label instead of stretching across the header.
      child: Center(
        widthFactor: 1,
        child: Text(
          'account.sign_in'.tr(),
          maxLines: 1,
          style: AppTextStyles.subheadingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.brandForeground.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
