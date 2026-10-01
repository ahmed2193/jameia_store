import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// The route [showHeroDialog] pushes (docs/motion §9.4 #14, §9.10 #12): the
/// dialog fades in and settles from [AppMotion.dialogScaleBegin] to full
/// size over [enter] with [AppMotion.signature]; it leaves by fading only,
/// over [exit] with [AppMotion.exit] (no scale on the way out). [reduced]:
/// a plain fade both ways (the durations say how long; zero = a cut).
///
/// [pop]: the card pops in instead — it grows from [AppMotion.dialogPopBegin]
/// on [AppSprings.snappy] (a small overshoot, like the home popups' gift
/// card) while it fades in over the first part of [enter]. The confirmation
/// dialogs arrive this way (`HeroConfirmDialog`).
///
/// The curves are built once per route: [buildTransitions] runs again on
/// every rebuild of the route, and a new `CurvedAnimation` there would add a
/// listener to the route's animation each time.
class HeroDialogRoute<T> extends RawDialogRoute<T> {
  HeroDialogRoute({
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.barrierColor,
    required Duration enter,
    required this.exit,
    required this.reduced,
    this.pop = false,
  }) : super(transitionDuration: enter);

  /// Share of a pop's run the card fades in over.
  static const double _popFadeShare = 0.4;

  /// How long the fade out runs.
  final Duration exit;

  /// Reduced motion: a fade, no scale.
  final bool reduced;

  /// Pop in on a spring instead of settling from above full size.
  final bool pop;

  CurvedAnimation? _fade;
  CurvedAnimation? _settle;
  Animation<double>? _scale;

  @override
  Duration get reverseTransitionDuration => exit;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final popping = pop && !reduced;
    final fade = _fade ??= CurvedAnimation(
      parent: animation,
      curve: popping
          ? const Interval(0, _popFadeShare, curve: AppMotion.signature)
          : AppMotion.signature,
      // Played 1 → 0: flipped so the fade speeds up as it goes (exit).
      reverseCurve: AppMotion.exit.flipped,
    );
    if (reduced) return FadeTransition(opacity: fade, child: child);
    final settle = _settle ??= CurvedAnimation(
      parent: animation,
      curve: popping ? AppSprings.snappy : AppMotion.signature,
      // Leaving: held at full size (1 → 0 maps to scale 1 throughout).
      reverseCurve: const Threshold(0),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: _scale ??= settle.drive(
          Tween<double>(
            begin: popping
                ? AppMotion.dialogPopBegin
                : AppMotion.dialogScaleBegin,
            end: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _fade?.dispose();
    _settle?.dispose();
    super.dispose();
  }
}
