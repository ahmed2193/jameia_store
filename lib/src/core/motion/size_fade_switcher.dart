import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Swaps [child] when [stateKey] changes: the box eases to the NEW child's
/// height while the old child fades out on top (pinned to the start edge).
/// Unlike an AnimatedSize around a FadeThroughSwitcher, the height moves
/// once, not twice. For full-width blocks (an address section ↔ a branch
/// section). Reduced motion → instant.
class SizeFadeSwitcher extends StatelessWidget {
  const SizeFadeSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
  });

  final Object stateKey;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.signature,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
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
      ),
    );
  }
}
