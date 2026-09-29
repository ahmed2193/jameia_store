import 'package:flutter/material.dart';

import 'motion.dart';
import 'vertical_swap_transition.dart';

/// Value-swap FLIP for short labels and times (a CTA label, ETA minutes, a
/// delivery-code digit): whenever [flipKey] changes the new [child] rises
/// into place while the old one leaves above — the app's one vertical swap
/// ([VerticalSwapTransition], [AppMotion.entranceRise] of travel) over
/// [AppMotion.medium]. Numbers that roll digit by digit use `RollingNumber`
/// instead. Reduced motion → instant swap (the duration collapses to zero
/// through [MotionGuard]). The first value never flips; pass [animate]
/// false while a new key is not a real change (a load filling in a
/// placeholder), so it swaps in place.
class FlipValue extends StatelessWidget {
  const FlipValue({
    super.key,
    required this.flipKey,
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
    this.animate = true,
  });

  /// Identity of the current value — when it changes, the flip plays.
  final Object flipKey;
  final Widget child;
  final AlignmentGeometry alignment;

  /// False: a key change swaps without motion (not a real change).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey<Object>(flipKey);
    return AnimatedSwitcher(
      duration: animate
          ? MotionGuard.duration(context, AppMotion.medium)
          : Duration.zero,
      switchInCurve: MotionGuard.curve(context, AppMotion.signature),
      switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
      layoutBuilder: (incoming, previous) => Stack(
        alignment: alignment,
        children: <Widget>[...previous, ?incoming],
      ),
      transitionBuilder: (child, animation) => VerticalSwapTransition(
        animation: animation,
        incoming: child.key == current,
        child: child,
      ),
      child: KeyedSubtree(key: current, child: child),
    );
  }
}
