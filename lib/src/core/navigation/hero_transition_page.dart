import '../motion/motion.dart';
import 'hero_page.dart';
import 'hero_through_transition.dart';

/// The forward push — every step deeper into the app (docs/motion §9.4 #8):
/// the Material shared X axis. The page below fades out while sliding
/// [AppMotion.slideShift] toward the start edge; this page then fades in
/// while sliding the same distance in from the end edge. Mirrored in RTL,
/// the pop plays it backwards; in over [AppMotion.page], out over
/// [AppMotion.medium] ([HeroPage] adds the easing, reduced motion and the
/// back gestures).
///
/// Modal presentations use [HeroSlideUpTransitionPage]; top-level swaps
/// ([GoRouter.go]) use [HeroFadeThroughPage].
class HeroTransitionPage<T> extends HeroPage<T> {
  const HeroTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  bool get shiftsCoveredPage => true;

  @override
  HeroEnterBuilder get enter =>
      (context, animation, child) => HeroThroughTransition(
        animation: animation,
        shift: AppMotion.slideShift,
        child: child,
      );
}
