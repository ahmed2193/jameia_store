import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// One delivery window in the slot sheet, as a Hero choice: a 36 dp box
/// (8 dp corners) inside a 44 dp tap target. Selected → a light brand fill,
/// a brand hairline and bold letters; bookable → white with a grey
/// hairline; full → a muted fill that ignores taps. The fill and border
/// cross-fade and the box dips a little under the finger.
class CheckoutSlotChip extends StatelessWidget {
  const CheckoutSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? AppColors.brandLightBg
        : enabled
        ? AppColors.white
        : AppColors.smallBackground;
    final side = selected
        ? const BorderSide(color: AppColors.primary)
        : enabled
        ? const BorderSide(color: AppColors.divider)
        : BorderSide.none;
    final style = selected
        ? AppTextStyles.label.copyWith(fontWeight: AppTextStyles.bold)
        : AppTextStyles.label.copyWith(
            color: enabled ? AppColors.primaryText : AppColors.disabledText,
          );
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      // The box's own gesture sits under excludeSemantics: without this a
      // screen reader would announce a button it cannot press.
      onTap: enabled ? onTap : null,
      child: PressScale(
        onTap: enabled ? onTap : null,
        enabled: enabled,
        haptic: HapticKind.selection,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.s44),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: AppMotion.signature,
              constraints: const BoxConstraints(minHeight: AppSize.s36),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s6,
              ),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: fill,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSize.r8),
                  ),
                  side: side,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
