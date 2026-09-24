import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'shell_nav_badge.dart';

/// One bottom-nav destination: icon (scaled up a touch when selected), label,
/// and an optional count badge.
class ShellNavItem extends StatelessWidget {
  const ShellNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.iconKey,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Shown over the icon when above zero.
  final int badge;

  /// Put on the rendered icon so [FlyToCart] can find the cart tab on screen.
  final GlobalKey? iconKey;

  static const double _selectedScale = 1.12;
  static const double _restScale = 1;
  static const double _badgeEnd = -10;
  static const double _badgeTop = -5;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.tertiaryText;
    return Semantics(
      selected: selected,
      button: true,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Reduced-motion safe: MotionGuard collapses the duration.
                  AnimatedScale(
                    scale: selected ? _selectedScale : _restScale,
                    duration: MotionGuard.duration(context, AppMotion.fast),
                    curve: MotionGuard.curve(context, AppMotion.signature),
                    child: Icon(
                      icon,
                      key: iconKey,
                      size: AppSize.s24,
                      color: color,
                    ),
                  ),
                  if (badge > 0)
                    PositionedDirectional(
                      end: _badgeEnd,
                      top: _badgeTop,
                      child: ShellNavBadge(count: badge),
                    ),
                ],
              ),
              const SizedBox(height: AppSize.s2),
              AnimatedDefaultTextStyle(
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: MotionGuard.curve(context, AppMotion.signature),
                style: AppTextStyles.captionSmall.copyWith(
                  color: color,
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.regular,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
