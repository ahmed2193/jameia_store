import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A pill of the listing toolbar: the sort button or the brand filter (with
/// a dropdown caret), or an on / off filter. Outlined at rest, filled with
/// ink while it is doing something (the fill cross-fades and the caret
/// turns), and it sinks a touch under the finger.
class ListingFilterPill extends StatelessWidget {
  const ListingFilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.isDropdown = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;
  final bool isDropdown;

  static const double height = AppSize.s40;
  static const double _glyph = AppSize.s18;

  /// The caret turns over while its filter is on (a half turn).
  static const double _caretTurned = 0.5;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    final foreground = selected ? AppColors.white : AppColors.primaryText;
    return PressScale(
      onTap: onTap,
      haptic: HapticKind.selection,
      child: AnimatedContainer(
        duration: duration,
        curve: MotionGuard.curve(context, AppMotion.signature),
        height: height,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryText : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryText : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HeroIcon(icon!, size: _glyph, color: foreground),
              const SizedBox(width: AppSpacing.s6),
            ],
            AnimatedDefaultTextStyle(
              duration: duration,
              style: AppTextStyles.bodyLarge.copyWith(
                color: foreground,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.regular,
              ),
              child: Text(label, maxLines: 1),
            ),
            if (isDropdown) ...[
              const SizedBox(width: AppSpacing.s4),
              AnimatedRotation(
                turns: selected ? _caretTurned : 0,
                duration: MotionGuard.duration(context, AppMotion.medium),
                curve: AppMotion.emphasizedDecelerate,
                child: HeroIcon(
                  HeroIcons.chevronDown,
                  size: _glyph,
                  color: foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
