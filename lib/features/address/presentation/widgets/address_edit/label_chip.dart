import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Label tag chip with a KeeTa glyph (Home | Work | Hangout | Other).
class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
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
            horizontal: AppSpacing.s14,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconAsset,
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(KeetaIcons.location, size: 15, color: fg),
              ),
              const SizedBox(width: AppSpacing.s6),
              Text(
                label,
                style: AppTextStyles.headingSmall.copyWith(
                  color: fg,
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
