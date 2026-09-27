import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// Material "shared X axis" page motion for a forward step in one flow
/// (login → OTP, Mine → Settings → About): the new page fades in while
/// sliding [_shift] in from the end edge; the page it covers fades out while
/// sliding the same distance toward the start edge. Mirrored in RTL, driven
/// by paint-only transforms. Reduced motion → an instant cut.
class HeroSharedAxisTransition extends StatelessWidget {
  const HeroSharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  /// Horizontal travel of each leg, in logical pixels.
  static const double _shift = 30;

  /// Share of a leg the outgoing fade takes; the incoming fade waits for it.
  static const double _fadeShare = 0.3;

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return child;
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final enter = animation.drive(CurveTween(curve: AppMotion.signature));
    final enterFade = animation.drive(
      CurveTween(curve: const Interval(_fadeShare, 1)),
    );
    final cover = secondaryAnimation.drive(
      CurveTween(curve: AppMotion.signature),
    );
    final coverFade = secondaryAnimation.drive(
      CurveTween(curve: const Interval(0, _fadeShare)),
    );
    // FadeTransition = a cheap opacity layer (no per-frame saveLayer like an
    // animated Opacity); the slide is a paint-only translation.
    return FadeTransition(
      opacity: enterFade,
      child: FadeTransition(
        opacity: ReverseAnimation(coverFade),
        child: AnimatedBuilder(
          animation: Listenable.merge([enter, cover]),
          child: child,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              ((1 - enter.value) - cover.value) * _shift * direction,
              0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
