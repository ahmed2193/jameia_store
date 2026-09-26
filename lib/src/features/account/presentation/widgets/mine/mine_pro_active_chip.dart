import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "Active" chip on the Jm3eia Pro row while the customer is a member.
class MineProActiveChip extends StatelessWidget {
  const MineProActiveChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentVioletLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'account.pro_active'.tr(),
        maxLines: 1,
        style: AppTextStyles.captionMedium.copyWith(
          fontWeight: AppTextStyles.bold,
          color: AppColors.accentViolet,
        ),
      ),
    );
  }
}
