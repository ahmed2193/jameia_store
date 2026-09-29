import 'package:flutter/widgets.dart';

import 'motion.dart';

/// The one height + fade transition (docs/motion §9.3 BX-07): as [animation]
/// runs 0 → 1 the box opens from [alignment] along [curve] while the child
/// fades in over the last part of it (from [fadeFrom]), so the room is
/// mostly made before the content shows; 1 → 0 plays it back. Driven by
/// the caller's animation ([CollapseReveal], [ListItemTransition], a list's
/// insert / remove, a fold), it only uses `drive` — no listener per build —
/// and animates nothing itself: a caller that is reduced to instant simply
/// hands it a finished animation.
class SizeFadeTransition extends StatelessWidget {
  const SizeFadeTransition({
    super.key,
    required this.animation,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.curve = AppMotion.signature,
    this.fadeFrom = defaultFadeFrom,
    this.alwaysIncludeSemantics = false,
  });

  /// The fade waits for half the opening by default.
  static const double defaultFadeFrom = 0.5;
  static const double _fadeTo = 1;

  final Animation<double> animation;
  final Widget child;
  final AlignmentGeometry alignment;

  /// The height's curve (the fade stays linear inside its interval).
  final Curve curve;

  /// Where on the animation the fade starts (0 = with the height).
  final double fadeFrom;

  /// A closing block may keep being read out (see [FadeTransition]).
  final bool alwaysIncludeSemantics;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation.drive(CurveTween(curve: curve)),
      alignment: alignment,
      child: FadeTransition(
        opacity: fadeFrom <= 0
            ? animation
            : animation.drive(CurveTween(curve: Interval(fadeFrom, _fadeTo))),
        alwaysIncludeSemantics: alwaysIncludeSemantics,
        child: child,
      ),
    );
  }
}
