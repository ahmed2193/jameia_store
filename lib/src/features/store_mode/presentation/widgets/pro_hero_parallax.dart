import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';

/// Lets [child] lag behind the page while it scrolls up (a light parallax):
/// only the `Transform` rebuilds per scroll frame, inside its own
/// `RepaintBoundary`. Capped, so the art never drifts far; off under reduced
/// motion or outside a vertical scrollable.
class ProHeroParallax extends StatelessWidget {
  const ProHeroParallax({super.key, required this.child});

  /// Share of the scroll offset the child sinks by.
  static const double _factor = 0.12;
  static const double _maxShift = AppSize.s40;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final position = MotionGuard.reduced(context)
        ? null
        : Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position == null) return child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: position,
        child: child,
        builder: (context, child) {
          final pixels = position.hasPixels ? position.pixels : 0.0;
          final shift = (pixels * _factor).clamp(0.0, _maxShift);
          return Transform.translate(offset: Offset(0, shift), child: child);
        },
      ),
    );
  }
}
