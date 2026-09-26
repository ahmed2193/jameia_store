import 'package:flutter/widgets.dart';

import 'motion.dart';

/// FADE THROUGH — swaps [child] when [stateKey] changes (loading → content,
/// label → loader → check): the old child fades out over the first 35% of
/// [AppMotion.page], then the new one fades in while settling from 92% to full
/// size (the Material "fade through" pattern for two states with no spatial
/// relation). Reduced motion → a plain [AppMotion.fast] cross-fade.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = AlignmentDirectional.center,
  });

  /// Share of the transition the outgoing child fades over.
  static const double _outShare = 0.35;
  static const double _scaleFrom = 0.92;

  /// Identity of the current state; a new value plays the transition.
  final Object stateKey;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    final current = ValueKey<Object>(stateKey);
    return AnimatedSwitcher(
      duration: reduced ? AppMotion.fast : AppMotion.page,
      layoutBuilder: (currentChild, previous) => Stack(
        alignment: alignment,
        children: <Widget>[...previous, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        if (reduced) return FadeTransition(opacity: animation, child: child);
        final incoming = child.key == current;
        // The outgoing child runs its animation 1 → 0: it is gone once the
        // value passes 1 − _outShare. The incoming one waits for that point.
        // `drive` (not a CurvedAnimation) registers no listener per build.
        final opacity = animation.drive(
          CurveTween(
            curve: incoming
                ? const Interval(_outShare, 1, curve: AppMotion.signature)
                : const Interval(1 - _outShare, 1, curve: AppMotion.exit),
          ),
        );
        if (!incoming) return FadeTransition(opacity: opacity, child: child);
        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: Tween<double>(begin: _scaleFrom, end: 1).animate(opacity),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: current, child: child),
    );
  }
}
