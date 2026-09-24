import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// Dark translucent tag over a recipe photo ("Kuwaiti", "Halal").
class CatalogRecipeTag extends StatelessWidget {
  const CatalogRecipeTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.bannerTagBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.white,
          fontWeight: AppTextStyles.medium,
        ),
      ),
    );
  }
}
