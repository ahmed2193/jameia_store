import 'package:flutter/material.dart';

import 'motion.dart';

/// Value-swap FLIP — Jameia's vertical price/total flip family
/// (`checkout_goods_price_flip`, `freeshipping_anim`, ~280ms). Swap the [child]
/// whenever [flipKey] changes; the outgoing value slides/fades out while the
/// incoming one settles in, sharing one [AppMotion.flip] token. Reduced-motion →
/// instant cut (duration collapses to zero via [MotionGuard]).
class FlipValue extends StatelessWidget {
  const FlipValue({
    super.key,
    required this.flipKey,
    required this.child,
    this.axis = Axis.vertical,
    this.alignment = AlignmentDirectional.centerStart,
  });

  /// Identity of the current value — when it changes, the flip plays.
  final Object flipKey;
  final Widget child;
  final Axis axis;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionGuard.duration(context, AppMotion.flip),
      switchInCurve: MotionGuard.curve(context, AppMotion.signature),
      switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final begin = axis == Axis.vertical
            ? const Offset(0, 0.6)
            : const Offset(0.6, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(flipKey), child: child),
    );
  }
}
