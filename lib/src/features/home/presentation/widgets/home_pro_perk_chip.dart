import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// One perk of the Pro banner ("Free delivery", "×2 points").
class HomeProPerkChip extends StatelessWidget {
  const HomeProPerkChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.popupCloseScrim,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionLarge.copyWith(
          color: AppColors.white,
          fontWeight: AppTextStyles.medium,
        ),
      ),
    );
  }
}
