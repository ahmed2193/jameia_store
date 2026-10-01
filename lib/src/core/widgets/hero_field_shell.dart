import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// The box a form input sits in when it is more than a bare `TextField` (an
/// icon before the text, a country code, a picker row, a stepper) — the
/// field look of `HeroInputDecoration.outlined`: white, 12 dp corners, a
/// hairline at rest, an ink outline while anything inside has focus, a red
/// outline with [error]. The outline is drawn over the box, so nothing
/// inside moves when it appears; it cross-fades over [AppMotion.fast]. It
/// grows with large text: [minHeight] is a floor.
///
/// Focus is followed on its own (anything focusable inside); pass [focused]
/// to drive it instead.
class HeroFieldShell extends StatefulWidget {
  const HeroFieldShell({
    super.key,
    required this.child,
    this.error = false,
    this.focused,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.s16,
    ),
    this.minHeight = AppSize.s52,
  });

  /// The resting hairline.
  static const double hairline = AppSize.s1;

  static const BorderRadius radius = BorderRadius.all(
    Radius.circular(AppRadius.card),
  );

  final Widget child;
  final bool error;
  final bool? focused;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  State<HeroFieldShell> createState() => _HeroFieldShellState();
}

class _HeroFieldShellState extends State<HeroFieldShell> {
  static const double _ring = AppSize.s1_5;

  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final focused = widget.focused ?? _hasFocus;
    final error = widget.error;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (widget.focused == null && hasFocus != _hasFocus) {
          setState(() => _hasFocus = hasFocus);
        }
      },
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: AppMotion.signature,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: widget.padding,
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: HeroFieldShell.radius,
          border: Border.all(
            color: error ? AppColors.error : AppColors.divider,
            width: HeroFieldShell.hairline,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: HeroFieldShell.radius,
          border: Border.all(
            color: error
                ? AppColors.error
                : focused
                ? AppColors.primaryText
                : AppColors.scrimTransparent,
            width: _ring,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
