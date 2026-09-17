import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// The route-level Jameia page motion: slide up from the bottom (100% -> 0) +
/// fade, driven by the route's primary [animation].
///
/// Faithful to 1Day's decoded `anim/activity_slide_in` (MOTION_AND_NAVIGATION
/// §2): 300ms ease-out. Shared by [JameiaTransitionPage] (enter/exit curve pair)
/// and [JameiaSlideUpTransitionPage] (enter curve on both legs). Gated by
/// [MotionGuard] so reduced motion degrades to an instant cut.
class JameiaSlideFadeTransition extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: reverseCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: AppMotion.pageSlideBegin,
          end: AppMotion.pageSlideEnd,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
