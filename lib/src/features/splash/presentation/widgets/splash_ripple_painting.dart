import 'dart:ui';

import '../../../../core/motion/motion.dart';
import 'splash_frame.dart';

/// Rings spreading from a landing (flat, on the ground) or a tap (round):
/// two rings each, the second a little behind the first.
abstract final class SplashRipplePainting {
  /// Radii in dp at strength 1, and the ring width at its start.
  static const double startRadius = 10;
  static const double reach = 96;
  static const double strokeWidth = 3;
  static const double opacity = 0.6;

  /// A ground ring's height as a share of its width.
  static const double groundFlatten = 0.32;

  /// The second ring starts this share of the run after the first.
  static const double echoDelay = 0.2;

  static void paint(Canvas canvas, List<SplashRipple> ripples, Color color) {
    for (final ripple in ripples) {
      for (final delay in const [0.0, echoDelay]) {
        final t = ((ripple.progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        final eased = AppMotion.signature.transform(t);
        final radius = (startRadius + eased * reach) * ripple.strength;
        final fade = (1 - t) * (1 - t);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * (1 - t) + 1
          ..color = color.withValues(
            alpha: color.a * opacity * fade * ripple.strength,
          );
        canvas.drawOval(
          Rect.fromCenter(
            center: ripple.center,
            width: radius * 2,
            height: radius * 2 * (ripple.ground ? groundFlatten : 1),
          ),
          paint,
        );
      }
    }
  }
}
