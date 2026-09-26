import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// The route-level Jameia page motion: slide up from the bottom (100% -> 0) +
/// fade, driven by the route's primary [animation].
///
/// Faithful to 1Day's decoded `anim/activity_slide_in` (MOTION_AND_NAVIGATION
/// §2): 300ms ease-out. Shared by [JameiaTransitionPage] (enter/exit curve pair)
/// and [JameiaSlideUpTransitionPage] (enter curve on both legs). Gated by
/// [MotionGuard] so reduced motion degrades to an instant cut.
///
/// Stateful so the curve is built once: the route rebuilds this on every tick
/// of its own and of the route above it, and a CurvedAnimation made in build()
/// would leave one more listener on the (long-lived) route animation each time.
class JameiaSlideFadeTransition extends StatefulWidget {
  const JameiaSlideFadeTransition({
    super.key,
    required this.animation,
    required this.curve,
    this.reverseCurve,
    required this.child,
  });

  /// The route's primary animation (0 -> 1 on push, 1 -> 0 on pop).
  final Animation<double> animation;

  /// Curve for the forward (push) leg.
  final Curve curve;

  /// Curve for the reverse (pop) leg; `null` re-uses [curve].
  final Curve? reverseCurve;

  /// The page being presented.
  final Widget child;

  @override
  State<JameiaSlideFadeTransition> createState() =>
      _JameiaSlideFadeTransitionState();
}

class _JameiaSlideFadeTransitionState extends State<JameiaSlideFadeTransition> {
  static final Tween<Offset> _slide = Tween<Offset>(
    begin: AppMotion.pageSlideBegin,
    end: AppMotion.pageSlideEnd,
  );

  late CurvedAnimation _curved = _make();

  CurvedAnimation _make() => CurvedAnimation(
    parent: widget.animation,
    curve: widget.curve,
    reverseCurve: widget.reverseCurve,
  );

  @override
  void didUpdateWidget(JameiaSlideFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve) {
      _curved.dispose();
      _curved = _make();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: _curved.drive(_slide),
        child: widget.child,
      ),
    );
  }
}
