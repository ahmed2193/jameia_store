import 'package:go_router/go_router.dart';

import '../motion/motion.dart';
import 'hero_slide_fade_transition.dart';

/// 1Day `activity_slide_in` (`anim/`): **300ms ease-out**, slide-up from the
/// bottom (100%→0) + fade, with the SAME ease-out curve on the pop leg. Used for
/// full-screen "Pop" presentations (product detail, the PDP image viewer) and
/// large bottom-anchored surfaces. For modal sheets prefer
/// `showHeroBottomSheet`; this is for route-level slide-ups.
///
/// [opaque] defaults to `true` (a full-screen page); pass `false` for a
/// see-through surface over the previous route. [MotionGuard] collapses the
/// transition to an instant cut under reduced motion.
class HeroSlideUpTransitionPage<T> extends CustomTransitionPage<T> {
  HeroSlideUpTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.opaque,
  }) : super(
         transitionDuration: AppMotion.page,
         reverseTransitionDuration: AppMotion.medium,
         transitionsBuilder: (_, animation, _, child) =>
             HeroSlideFadeTransition(
               animation: animation,
               curve: AppMotion.signature,
               child: child,
             ),
       );
}
