import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/press_row.dart';
import 'shell_nav_badge.dart';

/// One side of [ShellBasketSwitch]: icon, label and an optional count. The
/// thumb under it is drawn by the switch, so a segment only paints its
/// content, darker when chosen, and dips when pressed ([PressRow], no tint).
class ShellBasketSegment extends StatelessWidget {
  const ShellBasketSegment({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shown after the label when above zero.
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.secondaryText;
    return Semantics(
      button: true,
      selected: selected,
      child: PressRow(
        onTap: onTap,
        tint: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSize.s18, color: color),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: MotionGuard.curve(context, AppMotion.signature),
                style: AppTextStyles.headingSmall.copyWith(
                  color: color,
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.medium,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Always mounted: it fades out at zero instead of cutting.
            ShellNavBadge(
              count: count,
              margin: const EdgeInsetsDirectional.only(start: AppSpacing.s6),
            ),
          ],
        ),
      ),
    );
  }
}
