import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import 'hero_page_route.dart';

/// The one GoRouter page family of the app. Each page type (forward
/// [HeroTransitionPage], modal [HeroSlideUpTransitionPage], top-level
/// [HeroFadeThroughPage], same-flow [HeroCrossFadePage]) only says how its
/// page ENTERS ([enter]); the shared [HeroPageRoute] adds the rest the
/// same way for all of them:
///
/// - one easing: in over [transitionDuration] with [AppMotion.signature], out
///   over [reverseTransitionDuration] easing in like [AppMotion.exit];
/// - reduced motion: a `fast` fade; animations off: a cut ([MotionGuard]);
/// - the page it covers slides back by [AppMotion.slideShift] when this page
///   [shiftsCoveredPage] (the shared X axis), mirrored in RTL;
/// - back gestures: Android predictive back (the page shrinks and shifts
///   with the finger) and the iOS edge swipe (the finger drives the pop),
///   unless the page blocks back (`PopScope`).
///
/// Being one class family also keeps a page's type stable across entries:
/// Navigator keeps a route only while its page type and key match.
abstract class HeroPage<T> extends Page<T> {
  const HeroPage({
    required this.child,
    this.opaque = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The screen.
  final Widget child;

  /// `false` = a see-through surface over the previous route.
  final bool opaque;

  Duration get transitionDuration => AppMotion.page;
  Duration get reverseTransitionDuration => AppMotion.medium;

  /// Whether the page under this one slides back on the X axis while this
  /// one comes in (a forward step), instead of holding still.
  bool get shiftsCoveredPage => false;

  /// The entrance of the page, driven by the already-eased animation
  /// (0 → 1 on push, 1 → 0 on pop; linear while a finger drives it).
  HeroEnterBuilder get enter;

  @override
  Route<T> createRoute(BuildContext context) => HeroPageRoute<T>(this);
}

/// How a [HeroPage] brings its [child] in, driven by [animation].
typedef HeroEnterBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);
