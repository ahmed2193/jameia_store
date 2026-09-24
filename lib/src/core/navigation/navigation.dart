import 'package:flutter/material.dart';

import '../motion/motion.dart';

// Route-level page transitions live next to the modal presenters below: the
// GoRouter config (`config/routes`) builds every page through these, and
// features present sheets/dialogs through [showJameiaBottomSheet] /
// [showJameiaDialog] — one motion language for all navigation.
export 'jameia_slide_up_transition_page.dart';
export 'jameia_snack_bar.dart';
export 'jameia_transition_page.dart';
export 'route_observer.dart';

/// 1Day `bottom_slide_in` / `slide_in_bottom`: 300ms ease-out slide-from-bottom
/// (500ms `large` variant for big sheets). One place for the sheet duration /
/// curve so features stop relying on Material's default 250ms/standard curve.
/// [MotionGuard] collapses motion when reduced. MOTION_AND_NAVIGATION.md §6.
Future<T?> showJameiaBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool large = false,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final base = large ? AppMotion.sheetLarge : AppMotion.page; // 500ms : 300ms
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: shape,
    sheetAnimationStyle: AnimationStyle(
      duration: MotionGuard.duration(context, base),
      reverseDuration: MotionGuard.duration(context, AppMotion.medium),
      curve: MotionGuard.curve(context, AppMotion.signature),
      reverseCurve: MotionGuard.curve(context, AppMotion.exit),
    ),
    builder: builder,
  );
}

/// 1Day `dialog_anim_appear`: 250ms settle-in — scale 1.1 -> 1.0 + fade,
/// ease-out. Central presenter so centered modal dialogs share one enter.
/// MOTION_AND_NAVIGATION.md §6 (dialog_anim_appear, 250ms).
Future<T?> showJameiaDialog<T>(
  BuildContext context, {
  required WidgetBuilder pageBuilder,
  required String barrierLabel,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: MotionGuard.duration(context, AppMotion.medium),
    pageBuilder: (ctx, _, _) => pageBuilder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      if (MotionGuard.reduced(ctx)) return child;
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.decelerate);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: AppMotion.dialogScaleBegin,
            end: 1.0,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
