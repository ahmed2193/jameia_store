import 'package:go_router/go_router.dart';

import '../motion/motion.dart';
import 'jameia_shared_axis_transition.dart';

/// GoRouter page for a forward step inside one flow (login → OTP, Mine →
/// Settings → About): the Material shared-X-axis motion
/// ([JameiaSharedAxisTransition]) over [AppMotion.page], popping over
/// [AppMotion.medium]. Standard pushes keep [JameiaTransitionPage].
class JameiaSharedAxisPage<T> extends CustomTransitionPage<T> {
  JameiaSharedAxisPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
         transitionDuration: AppMotion.page,
         reverseTransitionDuration: AppMotion.medium,
         transitionsBuilder: (_, animation, secondaryAnimation, child) =>
             JameiaSharedAxisTransition(
               animation: animation,
               secondaryAnimation: secondaryAnimation,
               child: child,
             ),
       );
}
