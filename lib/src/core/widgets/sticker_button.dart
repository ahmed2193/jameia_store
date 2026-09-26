import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import 'branded_loader.dart';
import 'sticker_text.dart';

/// The buy button of the basket bars and the product page: a vivid rounded
/// block with a white [StickerText] label ("Checkout", "Add to cart"), or a
/// small dark one ([StickerButton.compact], "Add item"). Disabled it turns
/// grey with plain grey text and does not react; loading it shows the
/// branded spinner and does not react either. It sinks under the finger.
class StickerButton extends StatelessWidget {
  const StickerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.color = AppColors.primary,
    this.height = defaultHeight,
  }) : compact = false;

  /// The small variant: tighter padding, smaller label, smaller corners.
  const StickerButton.compact({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.color = AppColors.brandDeep,
    this.height = compactHeight,
  }) : compact = true;

  static const double defaultHeight = AppSize.s56;
  static const double compactHeight = AppSize.s36;
  static const double _pressedScale = 0.97;

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;
  final Color color;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    final base = compact
        ? AppTextStyles.headingMedium
        : AppTextStyles.displaySmall.copyWith(fontSize: AppSize.font20);
    final style = base.copyWith(
      color: AppColors.brandForeground,
      fontWeight: AppTextStyles.bold,
    );
    final Widget content = loading
        ? BrandedLoader.inline(
            size: AppSize.s22,
            color: AppColors.brandForeground,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: active
                ? StickerText(
                    label,
                    style: style,
                    rim: compact ? AppSize.s2 : StickerText.defaultRim,
                  )
                : Text(
                    label,
                    maxLines: 1,
                    style: style.copyWith(color: AppColors.tertiaryText),
                  ),
          );
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      excludeSemantics: true,
      onTap: active ? onPressed : null,
      child: PressScale(
        onTap: active ? onPressed : null,
        enabled: active,
        pressedScale: _pressedScale,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          height: height,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? AppSpacing.s12 : AppSpacing.s16,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active || loading ? color : AppColors.divider,
            borderRadius: BorderRadius.circular(
              compact ? AppRadius.r5 : AppRadius.r3,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
