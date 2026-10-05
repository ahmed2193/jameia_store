import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The dark label over the pin, Glovo style (a rounded box, no tail, as
/// wide as its words): what the pin points at (a street and its number, a
/// place's name, "Out of delivery area", "Finding your location…"). It pops
/// in once there are words — while they are read the pin's own head shows
/// the dots — and away when the map moves; a new line cross-fades in while
/// the label eases to its width.
class PickerPinTooltip extends StatelessWidget {
  const PickerPinTooltip({
    super.key,
    required this.text,
    required this.visible,
  });

  final String text;
  final bool visible;

  static const double maxWidth = AppSize.s240;
  static const double _hiddenScale = 0.85;

  @override
  Widget build(BuildContext context) {
    final fast = MotionGuard.duration(context, AppMotion.fast);
    final shown = visible && text.isNotEmpty;
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: fast,
      curve: AppMotion.signature,
      child: AnimatedScale(
        scale: shown ? 1 : _hiddenScale,
        alignment: Alignment.bottomCenter,
        duration: MotionGuard.duration(context, AppSprings.snappy.duration),
        curve: shown ? AppSprings.snappy : AppMotion.exit,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.tooltipFill,
              borderRadius: BorderRadius.circular(AppRadius.r5),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: AnimatedSize(
                duration: fast,
                curve: AppMotion.signature,
                child: FadeThroughSwitcher(
                  stateKey: text,
                  crossFade: true,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
