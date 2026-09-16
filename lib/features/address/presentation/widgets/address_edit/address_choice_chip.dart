import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Yellow-selected pill-ish choice chip (struct type / drop spot).
class AddressChoiceChip extends StatelessWidget {
  const AddressChoiceChip({
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
    final fg = selected ? AppColors.primaryText : AppColors.secondaryText;
    return PressScale(
      onTap: onTap,
      child: PopScale(
        popKey: selected,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: MotionGuard.curve(context, AppMotion.standard),
          height: 40,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandLightBg
                : AppColors.smallBackground,
            borderRadius: BorderRadius.circular(AppRadius.r4),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.headingSmall.copyWith(
              color: fg,
              fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
            ),
          ),
        ),
      ),
    );
  }
}
