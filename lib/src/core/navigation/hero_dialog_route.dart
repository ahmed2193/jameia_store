import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// The route [showHeroDialog] pushes (docs/motion §9.4 #14, §9.10 #12): the
/// dialog fades in and settles from [AppMotion.dialogScaleBegin] to full
/// size over [enter] with [AppMotion.signature]; it leaves by fading only,
/// over [exit] with [AppMotion.exit] (no scale on the way out). [reduced]:
/// a plain fade both ways (the durations say how long; zero = a cut).
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
  }) : super(transitionDuration: enter);

  /// How long the fade out runs.
  final Duration exit;

  /// Reduced motion: a fade, no scale.
  final bool reduced;

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
    final fade = _fade ??= CurvedAnimation(
      parent: animation,
      curve: AppMotion.signature,
      // Played 1 → 0: flipped so the fade speeds up as it goes (exit).
      reverseCurve: AppMotion.exit.flipped,
    );
    if (reduced) return FadeTransition(opacity: fade, child: child);
    final settle = _settle ??= CurvedAnimation(
      parent: animation,
      curve: AppMotion.signature,
      // Leaving: held at full size (1 → 0 maps to scale 1 throughout).
      reverseCurve: const Threshold(0),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: _scale ??= settle.drive(
          Tween<double>(begin: AppMotion.dialogScaleBegin, end: 1),
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
