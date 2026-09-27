import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';

/// GoRouter page that only fades in over the page below it — nothing slides
/// or zooms. For the steps of one flow that share their chrome (the sign-in
/// pages share their brand header): what both pages paint the same looks
/// still while the rest cross-fades, and a page that stages its own entrance
/// (a sheet rising) is not moved twice.
class HeroCrossFadePage<T> extends CustomTransitionPage<T> {
  HeroCrossFadePage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
         transitionDuration: AppMotion.page,
         reverseTransitionDuration: AppMotion.medium,
         transitionsBuilder: (context, animation, _, child) {
           if (MotionGuard.reduced(context)) return child;
           // drive(): this builder runs every tick; a CurvedAnimation here
           // would add a listener to the route animation each time.
           return FadeTransition(
             opacity: animation.drive(CurveTween(curve: AppMotion.signature)),
             child: child,
           );
         },
       );
}
