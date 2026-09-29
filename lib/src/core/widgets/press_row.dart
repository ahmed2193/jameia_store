import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';

/// THE list-row press (docs/motion §9.4 #1, backlog B1-16): a row (a Mine
/// menu row, a settings row, an address, a list row, a sheet option) answers
/// a finger like every other tappable — it dips ([PressScale],
/// `AppMotion.pressedScale`) — and tints flat with the one brand touch tint
/// ([AppColors.pressTint], no splash, no sparkle). Under reduced motion the
/// dip goes and the tint stays. No haptic: opening a row is navigation
/// (§9.5); a row that picks something fires its own in [onTap].
///
/// [tint] false keeps the dip without the tint (a bottom-nav item, a
/// segment: the thumb / the selected state is their answer). The row keeps
/// the `InkWell`'s focus and semantics. Paint it on a [Material] so the tint
/// shows. A button inside the row (an icon action) presses itself, and the
/// row then stays still (one press at a time).
class PressRow extends StatelessWidget {
  const PressRow({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.tint = true,
    this.pressedScale,
    this.excludeFromSemantics = false,
  });

  /// `null` = inert (no dip, no tint).
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  /// Clips the tint (a rounded card row).
  final BorderRadius? borderRadius;
  final bool tint;

  /// Overrides `AppMotion.pressedScale` (a small round control).
  final double? pressedScale;

  /// The row's action is announced by a child instead.
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final ink = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      excludeFromSemantics: excludeFromSemantics,
      borderRadius: borderRadius,
      splashFactory: NoSplash.splashFactory,
      splashColor: AppColors.scrimTransparent,
      highlightColor: tint ? AppColors.pressTint : AppColors.scrimTransparent,
      child: child,
    );
    return PressScale(
      enabled: onTap != null || onLongPress != null,
      pressedScale: pressedScale ?? AppMotion.pressedScale,
      child: ink,
    );
  }
}
