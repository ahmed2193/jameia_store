import 'package:flutter/material.dart';

import 'motion.dart';
import 'spring_curve.dart';

/// POP SWITCH — swaps [child] when [stateKey] changes: the new child pops in
/// from [alignment] (scale [from] → 1 on `AppSprings.snappy`, fading in over
/// the first half), the old one fades out over [AppMotion.fast] (ease-in).
/// The FIRST build is static (an `AnimatedSwitcher` never animates its
/// initial child), so content already there when the page opens never pops.
/// Reduced motion → zero-duration swap (no ticker runs).
///
/// [stateKey] is the IDENTITY of what is shown (a coupon code, a line ref, a
/// bool) — never a value that changes on every emission.
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = AlignmentDirectional.center,
    this.from = defaultFrom,
  });

  /// The scale the incoming child starts from.
  static const double defaultFrom = 0.6;

  /// Share of the pop over which the incoming child fades in.
  static const double _fadeShare = 0.5;
  static const double _to = 1;

  final Object stateKey;
  final Widget child;
  final AlignmentDirectional alignment;
  final double from;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    final current = ValueKey<Object>(stateKey);
    final origin = alignment.resolve(Directionality.of(context));
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : AppSprings.snappy.duration,
      reverseDuration: reduced ? Duration.zero : AppMotion.fast,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (incoming, previous) => Stack(
        alignment: alignment,
        children: <Widget>[...previous, ?incoming],
      ),
      transitionBuilder: (child, animation) {
        if (child.key != current) {
          return FadeTransition(opacity: animation, child: child);
        }
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0, _fadeShare)),
          ),
          child: ScaleTransition(
            alignment: origin,
            scale: animation.drive(
              Tween<double>(
                begin: from,
                end: _to,
              ).chain(CurveTween(curve: AppSprings.snappy)),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: current, child: child),
    );
  }
}
