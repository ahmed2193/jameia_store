import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// One chunky block of the "Jm3eia | Pro" lockup: bold white [label] on a
/// rounded slab of [color], or of [gradient] when given.
class ProLockupBlock extends StatelessWidget {
  const ProLockupBlock({
    super.key,
    required this.label,
    required this.color,
    this.gradient,
  });

  final String label;
  final Color color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: AppTextStyles.headingLarge.copyWith(
          fontSize: AppSize.font20,
          height: AppSize.lh1_2,
          fontWeight: AppTextStyles.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}
