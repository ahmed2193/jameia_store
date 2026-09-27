import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';

/// GoRouter page that fades in while settling from a slight zoom — the
/// incoming half of Material's fade-through. For a hand-off between two whole
/// surfaces (splash → app), where a slide would read as a sheet.
class HeroFadeThroughPage<T> extends CustomTransitionPage<T> {
  HeroFadeThroughPage({
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
           final eased = animation.drive(
             CurveTween(curve: AppMotion.signature),
           );
           return FadeTransition(
             opacity: eased,
             child: ScaleTransition(
               scale: eased.drive(Tween<double>(begin: zoomFrom, end: 1)),
               child: child,
             ),
           );
         },
       );

  /// Scale the page starts at before settling to 1.
  static const double zoomFrom = 0.96;
}
