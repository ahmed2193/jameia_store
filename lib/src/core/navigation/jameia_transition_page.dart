import 'package:go_router/go_router.dart';

import '../motion/motion.dart';
import 'jameia_slide_fade_transition.dart';

/// Shared GoRouter page transition — every standard `GoRoute` builds its page
/// through this so each push animates the same way. `routes.dart` /
/// `app_router.dart` decide WHICH screen; this decides HOW it animates.
///
/// Faithful to 1Day's decoded `anim/activity_slide_in` (MOTION_AND_NAVIGATION
/// §2): **300ms ease-out, slide-up from the bottom (100%→0) + fade**. 1Day pairs
/// interpolator_style2 (enter, ease-out) with interpolator_style1 (exit,
/// ease-in), so the reverse leg uses its ease-in companion ([AppMotion.exit])
/// and pop matches the exit curve instead of re-using the enter curve
/// (MOTION_AND_NAVIGATION.md:40-44). Pop runs for [AppMotion.medium].
/// [MotionGuard] collapses the transition to an instant cut under reduced motion.
class JameiaTransitionPage<T> extends CustomTransitionPage<T> {
  JameiaTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
         transitionDuration: AppMotion.page,
         reverseTransitionDuration: AppMotion.medium,
         transitionsBuilder: (_, animation, _, child) =>
             JameiaSlideFadeTransition(
               animation: animation,
               curve: AppMotion.signature,
               reverseCurve: AppMotion.exit,
               child: child,
             ),
       );
}
