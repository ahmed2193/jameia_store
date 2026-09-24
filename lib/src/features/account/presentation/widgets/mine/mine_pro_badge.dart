import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "PRO" pill next to the name of a Jm3eia Pro member.
class MineProBadge extends StatelessWidget {
  const MineProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'profile.pro_badge'.tr(),
        style: AppTextStyles.captionMedium.copyWith(
          fontWeight: AppTextStyles.bold,
          color: AppColors.brandForeground,
        ),
      ),
    );
  }
}
