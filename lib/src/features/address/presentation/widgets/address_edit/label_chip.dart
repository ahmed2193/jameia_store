import 'package:flutter/material.dart';

import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One word chip of the label track (Home | Work | Gathering | Other),
/// Glovo style: white on the grey track; the pick turns mint with a green
/// ring and bold words.
class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: ChangeBump(
          value: selected,
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: MotionGuard.curve(context, AppMotion.signature),
            height: AppSize.s40,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandLightBg : AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.white,
                width: AppSize.s1_5,
              ),
            ),
            // Hugs its words (a Wrap of chips), centred in the chip's height.
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.medium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
