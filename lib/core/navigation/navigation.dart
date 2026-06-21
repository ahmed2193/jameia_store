import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Shared page transition. Use this for new routes so every push animates the
/// same way. The `routes.dart` / `app_router.dart` pair decides WHICH screen;
/// this decides HOW it animates.
///
/// Faithful to 1Day's decoded `anim/activity_slide_in` (MOTION_AND_NAVIGATION
/// §2): **300ms ease-out, slide-up from the bottom (100%→0) + fade**. Durations/
/// curves come from the motion tokens, and the transition is gated by
/// [MotionGuard] so reduced-motion degrades to an instant cut.
class KeetaPageRoute<T> extends PageRouteBuilder<T> {
  KeetaPageRoute({required Widget page, super.settings})
      : super(
          transitionDuration: AppMotion.page,
          reverseTransitionDuration: AppMotion.medium,
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (context, animation, _, child) {
            if (MotionGuard.reduced(context)) return child;
            // 1Day pairs interpolator_style2 (enter, ease-out) with
            // interpolator_style1 (exit, ease-in): give the reverse leg its
            // ease-in companion so pop matches AppMotion.exit instead of
            // re-using the enter curve. MOTION_AND_NAVIGATION.md:40-44.
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.signature, // enter: ease-out (interpolator_style2)
              reverseCurve: AppMotion.exit, // pop: ease-in (interpolator_style1 pair)
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// 1Day `bottom_slide_in` / `slide_in_bottom`: 300ms ease-out slide-from-bottom
/// (500ms `large` variant for big sheets). One place for the sheet duration /
/// curve so features stop relying on Material's default 250ms/standard curve.
/// [MotionGuard] collapses motion when reduced. MOTION_AND_NAVIGATION.md §6.
Future<T?> showKeetaBottomSheet<T>(
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
Future<T?> showKeetaDialog<T>(
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
          scale: Tween<double>(begin: AppMotion.dialogScaleBegin, end: 1.0)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 1Day `activity_slide_in` (`anim/`): **300ms ease-out**, slide-up from the
/// bottom (100%→0) + fade. Used for full-screen "Pop" presentations and large
/// bottom-anchored surfaces (cart add-on, checkout dialogs). For modal sheets
/// prefer [showModalBottomSheet]; this is for route-level slide-ups.
class KeetaSlideUpRoute<T> extends PageRouteBuilder<T> {
  KeetaSlideUpRoute({required Widget page, super.settings, super.opaque})
      : super(
          transitionDuration: AppMotion.page,
          reverseTransitionDuration: AppMotion.medium,
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (context, animation, _, child) {
            if (MotionGuard.reduced(context)) return child;
            final curved =
                CurvedAnimation(parent: animation, curve: AppMotion.signature);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
