import 'package:go_router/go_router.dart';

import '../motion/motion.dart';
import 'hero_shared_axis_transition.dart';

/// GoRouter page for a forward step inside one flow (login → OTP, Mine →
/// Settings → About): the Material shared-X-axis motion
/// ([HeroSharedAxisTransition]) over [AppMotion.page], popping over
/// [AppMotion.medium]. Standard pushes keep [HeroTransitionPage].
class HeroSharedAxisPage<T> extends CustomTransitionPage<T> {
  HeroSharedAxisPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
         transitionDuration: AppMotion.page,
         reverseTransitionDuration: AppMotion.medium,
         transitionsBuilder: (_, animation, secondaryAnimation, child) =>
             HeroSharedAxisTransition(
               animation: animation,
               secondaryAnimation: secondaryAnimation,
               child: child,
             ),
       );
}
