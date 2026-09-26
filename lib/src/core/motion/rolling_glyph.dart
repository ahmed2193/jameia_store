import 'package:flutter/widgets.dart';

import 'motion.dart';

/// One character slot of a [RollingNumber]: when [glyph] changes it rolls the
/// old character out and the new one in vertically, up for a rising number
/// ([trend] > 0) and down for a falling one, clipped to its own box. An
/// unchanged glyph never animates. Reduced motion → an instant swap.
class RollingGlyph extends StatelessWidget {
  const RollingGlyph({
    super.key,
    required this.glyph,
    required this.trend,
    this.style,
  });

  /// How far (of its height) a glyph travels in / out.
  static const double _travel = 0.6;

  final String glyph;

  /// +1 rising, −1 falling, 0 unknown (treated as rising).
  final int trend;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final direction = trend < 0 ? -1.0 : 1.0;
    final current = ValueKey<String>(glyph);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.flip),
        switchInCurve: AppMotion.signature,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) {
          final incoming = child.key == current;
          // Incoming rises from below (rising number); outgoing leaves above.
          final from = Offset(0, (incoming ? _travel : -_travel) * direction);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: from,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(glyph, key: current, style: style),
      ),
    );
  }
}
