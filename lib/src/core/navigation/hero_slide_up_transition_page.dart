import '../motion/motion.dart';
import 'hero_page.dart';
import 'hero_slide_fade_transition.dart';

/// A modal presentation — a layer the customer will close (docs/motion §9.4
/// #10): the product page, its photo viewer, the assistant chat, search from
/// a pill, the cart preview, the Pro paywall. Rises from the bottom
/// (100 % → 0) with a fade and drops back down on pop; the page below holds
/// still. In over [AppMotion.page], out over [AppMotion.medium] ([HeroPage]
/// adds the easing, reduced motion and the back gestures).
///
/// [opaque] defaults to `true` (a full-screen page); pass `false` for a
/// see-through surface over the previous route. For sheets use
/// `showHeroBottomSheet`.
class HeroSlideUpTransitionPage<T> extends HeroPage<T> {
  const HeroSlideUpTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.opaque,
  });

  @override
  HeroEnterBuilder get enter =>
      (context, animation, child) => HeroSlideFadeTransition(
        animation: animation,
        curve: AppMotion.linear,
        child: child,
      );
}
