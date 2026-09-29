import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'vertical_swap_transition.dart';

/// One character slot of a [RollingNumber]: when [glyph] changes it rolls the
/// old character out and the new one in vertically, up for a rising number
/// ([trend] > 0) and down for a falling one, clipped to its own box — the
/// app's vertical swap ([VerticalSwapTransition.fraction]) at an odometer's
/// travel. An unchanged glyph never animates. Reduced motion → the two
/// characters cross-fade over [AppMotion.fast] in place (no travel);
/// animations off → an instant swap.
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
    final off = MotionGuard.off(context);
    final reduced = MotionGuard.reduced(context);
    final current = ValueKey<String>(glyph);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: off
            ? Duration.zero
            : reduced
            ? AppMotion.fast
            : AppMotion.medium,
        switchInCurve: AppMotion.signature,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => reduced
            ? FadeTransition(opacity: animation, child: child)
            : VerticalSwapTransition.fraction(
                animation: animation,
                incoming: child.key == current,
                share: _travel,
                rising: trend >= 0,
                child: child,
              ),
        child: Text(glyph, key: current, style: style),
      ),
    );
  }
}
