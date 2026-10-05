import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../motion/motion.dart';
import 'hero_dialog_route.dart';

// Route-level page transitions live next to the modal presenters below: the
// GoRouter config (`config/routes`) builds every page through one of the
// [HeroPage] types — forward push [HeroTransitionPage], modal
// [HeroSlideUpTransitionPage], top-level swap [HeroFadeThroughPage], same-flow
// step [HeroCrossFadePage] — and features present sheets/dialogs through
// [showHeroBottomSheet] / [showHeroDialog]: one motion language for all
// navigation (docs/motion §9.4 #8-#14).
export 'hero_back_gesture.dart';
export 'hero_confirm_dialog_presenter.dart';
export 'hero_cross_fade_page.dart';
export 'hero_dialog_route.dart';
export 'hero_fade_through_page.dart';
export 'hero_page.dart';
export 'hero_page_route.dart';
export 'hero_slide_up_transition_page.dart';
export 'hero_snack_bar.dart';
export 'hero_transition_page.dart';
export 'route_observer.dart';
export 'sign_in_flow.dart';

/// The white sheet's 24 dp top corners (`HeroSheetHeader.shape`).
const ShapeBorder _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
);

/// The sheet on screen (set when its route first builds).
ModalRoute<Object?>? _openSheet;

/// The navigator a sheet was asked of that has not built yet.
NavigatorState? _sheetPendingIn;

/// The sheet the presenter holds on to — none once it has answered (for
/// tests: a closed sheet must not keep its page alive).
@visibleForTesting
ModalRoute<Object?>? get debugHeldSheet => _openSheet;

/// A sheet answered: nothing waits for it any more, and the app lets go of
/// its route — a closed sheet must not keep the page it was opened from
/// alive (its captured themes hold that page's elements).
void _release(ModalRoute<Object?>? sheet) {
  _sheetPendingIn = null;
  if (sheet != null && identical(_openSheet, sheet)) _openSheet = null;
}

/// A sheet is up and not on its way out: another one waits for it.
bool _sheetIsUp() {
  if (_sheetPendingIn?.mounted ?? false) return true;
  final open = _openSheet;
  if (open == null) return false;
  return open.isActive && (open.animation?.isForwardOrCompleted ?? false);
}

/// The one bottom-sheet presenter: in over [AppMotion.page] ([AppMotion.slow]
/// for a [large] sheet) with [AppMotion.signature], out over
/// [AppMotion.medium] with [AppMotion.exit] (docs/motion §9.4 #13, §9.10 #12).
/// One place for the sheet duration / curve so features stop relying on
/// Material's default. [MotionGuard] collapses motion when reduced.
/// [elevation] lets a transparent sheet (one that draws its own card) drop
/// the Material shadow. Every sheet is white with 24 dp top corners unless
/// it asks for another [backgroundColor] / [shape] (one that draws its own
/// card passes a transparent one) — never Material's tinted surface.
/// [barrierColor] replaces the dimming behind it (a sheet that belongs to
/// the screen under it, like the map picker's building-type panel, passes a
/// transparent one; a tap outside still closes it).
///
/// One sheet at a time: while a sheet is up (not already leaving), another
/// call does nothing and completes with `null` — a double tap never stacks
/// two copies. A flow of sheets opens the next one once the first has
/// answered (its closing slide may still be running).
Future<T?> showHeroBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool large = false,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  double? elevation,
  Color? barrierColor,
}) {
  if (_sheetIsUp()) return Future<T?>.value();
  _sheetPendingIn = Navigator.of(context);
  ModalRoute<Object?>? mine;
  final base = large ? AppMotion.slow : AppMotion.page;
  final shown = showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? AppColors.white,
    shape: shape ?? _sheetShape,
    elevation: elevation,
    barrierColor: barrierColor,
    sheetAnimationStyle: AnimationStyle(
      duration: MotionGuard.duration(context, base),
      reverseDuration: MotionGuard.duration(context, AppMotion.medium),
      curve: MotionGuard.curve(context, AppMotion.signature),
      reverseCurve: MotionGuard.curve(context, AppMotion.exit),
    ),
    builder: (sheetContext) {
      final route = ModalRoute.of(sheetContext);
      // Claimed by the new sheet only (not one still sliding out).
      if (_sheetPendingIn != null &&
          (route?.animation?.isForwardOrCompleted ?? true)) {
        _sheetPendingIn = null;
        _openSheet = mine = route;
      }
      return builder(sheetContext);
    },
  );
  // Never left pending or held: the answer (or a failure to show)
  // releases it.
  unawaited(
    shown.then((_) => _release(mine), onError: (Object _) => _release(mine)),
  );
  return shown;
}

/// Central presenter so centered modal dialogs share one motion (docs/motion
/// §9.4 #14): fade + scale [AppMotion.dialogScaleBegin] → 1 over
/// [AppMotion.medium] with [AppMotion.signature] in, a fade over
/// [AppMotion.fast] with [AppMotion.exit] out ([HeroDialogRoute]). [pop]:
/// the card pops in on [AppSprings.snappy] instead (the confirmation
/// dialogs). Reduced motion: a [AppMotion.fast] fade both ways (instant when
/// animations are off).
Future<T?> showHeroDialog<T>(
  BuildContext context, {
  required WidgetBuilder pageBuilder,
  required String barrierLabel,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool pop = false,
}) {
  final reduced = MotionGuard.reduced(context);
  final off = MotionGuard.off(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    HeroDialogRoute<T>(
      pageBuilder: (ctx, _, _) => pageBuilder(ctx),
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? AppColors.overlayPrimary,
      enter: off
          ? Duration.zero
          : reduced
          ? AppMotion.fast
          : pop
          ? AppSprings.snappy.duration
          : AppMotion.medium,
      exit: off ? Duration.zero : AppMotion.fast,
      reduced: reduced,
      pop: pop,
    ),
  );
}
