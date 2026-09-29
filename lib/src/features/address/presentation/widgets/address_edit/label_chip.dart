import 'package:flutter/material.dart';

import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';

/// Label tag chip with its drawn Hero glyph (Home | Work | Hangout | Other;
/// a mono `HeroAssets.addressLabel*` tinted like the words).
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
      haptic: HapticKind.selection,
      child: ChangeBump(
        value: selected,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: MotionGuard.curve(context, AppMotion.signature),
          height: AppSize.s40,
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
              HeroSvgGlyph.mono(iconAsset, size: AppSize.s16, color: fg),
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
