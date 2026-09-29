import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Swaps [child] when [stateKey] changes: the box eases to the NEW child's
/// height over [AppMotion.medium] while the old child fades out on top
/// (pinned to the start edge) and the new one fades in, over [fade]. Unlike
/// an AnimatedSize around a FadeThroughSwitcher, the height moves once, not
/// twice. For full-width blocks (an address section ↔ a branch section).
/// Reduced motion → instant, with no size box at all (an `AnimatedSize`
/// with no duration re-dirties itself in its own layout).
class SizeFadeSwitcher extends StatelessWidget {
  const SizeFadeSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.fade = AppMotion.medium,
  });

  final Object stateKey;
  final Widget child;
  final AlignmentGeometry alignment;

  /// How long the children cross-fade (the height always takes `medium`).
  final Duration fade;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    final switcher = AnimatedSwitcher(
      duration: MotionGuard.duration(context, fade),
      switchInCurve: AppMotion.signature,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: <Widget>[
          for (final old in previous)
            PositionedDirectional(top: 0, start: 0, end: 0, child: old),
          ?current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
    );
    if (duration == Duration.zero) return switcher;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.signature,
      alignment: alignment,
      child: switcher,
    );
  }
}
