import 'hero_page.dart';
import 'hero_through_transition.dart';

/// A top-level swap between unrelated roots (docs/motion §9.4 #11): splash →
/// shell, sign-in → shell, sign-out / expiry → login, order placed →
/// tracking. The page below fades out over the first 30 %, then this one
/// fades in while settling from [zoomFrom] — no slide, so no false
/// hierarchy.
///
/// The shell always arrives on this page type, so a later
/// `go(Routes.shell)` finds the same page (same type, same key) and keeps
/// the shell and its tabs instead of building a new one.
class HeroFadeThroughPage<T> extends HeroPage<T> {
  const HeroFadeThroughPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  });

  /// Scale the page settles from.
  static const double zoomFrom = 0.92;

  @override
  HeroEnterBuilder get enter =>
      (context, animation, child) => HeroThroughTransition(
        animation: animation,
        zoomFrom: zoomFrom,
        child: child,
      );
}
