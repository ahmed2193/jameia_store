import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// One delivery window in the slot sheet: a 36 dp pill inside a 44 dp tap
/// target. Selected → ink fill and a white label; bookable → white with a
/// hairline; full → a muted fill that ignores taps. The fill cross-fades and
/// the pill dips a little under the finger.
class CheckoutSlotChip extends StatelessWidget {
  const CheckoutSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  static const double _pressedScale = 0.97;

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? AppColors.primaryText
        : enabled
        ? AppColors.white
        : AppColors.smallBackground;
    final ink = selected
        ? AppColors.white
        : enabled
        ? AppColors.primaryText
        : AppColors.disabledText;
    final side = !selected && enabled
        ? const BorderSide(color: AppColors.divider)
        : BorderSide.none;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      // The pill's own gesture sits under excludeSemantics: without this a
      // screen reader would announce a button it cannot press.
      onTap: enabled ? onTap : null,
      child: PressScale(
        onTap: enabled ? onTap : null,
        enabled: enabled,
        haptic: HapticKind.selection,
        pressedScale: _pressedScale,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.s44),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: AppMotion.signature,
              constraints: const BoxConstraints(minHeight: AppSize.s36),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s6,
              ),
              decoration: ShapeDecoration(
                color: fill,
                shape: StadiumBorder(side: side),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
