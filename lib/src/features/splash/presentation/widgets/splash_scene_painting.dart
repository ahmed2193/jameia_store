import 'dart:ui';

import '../../../../core/design/jameia_cart_mark.dart';
import 'splash_ambient_painting.dart';
import 'splash_cart_painting.dart';
import 'splash_confetti_painting.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';
import 'splash_ripple_painting.dart';
import 'splash_wordmark_painting.dart';

/// Paints one whole splash frame in one palette, back to front: background,
/// living colour, rings, speed lines, the cart, the name and the confetti.
abstract final class SplashScenePainting {
  /// Vertical place (share of the cart height from its centre) and length
  /// (share of the cart width) of each streak behind the moving cart.
  static const List<(double, double)> speedLines = [
    (-0.2, 0.8),
    (0.06, 1),
    (0.3, 0.6),
  ];

  /// Gap between the cart and its streaks, and streak width, in design units.
  static const double speedLineGap = 8;
  static const double speedLineWidth = 5;

  static void paint(
    Canvas canvas,
    Size size,
    SplashLayout layout,
    SplashFrame frame,
    SplashPalette palette, {
    Offset glowShift = Offset.zero,
  }) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    SplashAmbientPainting.paint(
      canvas,
      size,
      frame,
      palette,
      glowShift: glowShift,
    );
    SplashRipplePainting.paint(canvas, frame.ripples, palette.ripple);
    if (frame.speedLines > 0) _speedLines(canvas, frame, palette);
    SplashCartPainting.paint(
      canvas,
      center: frame.cartCenter,
      unit: frame.cartUnit,
      palette: palette,
      squash: frame.squash,
      lift: frame.lift,
      groceries: frame.groceries,
    );
    SplashWordmarkPainting.paint(canvas, layout, frame, palette);
    SplashConfettiPainting.paint(canvas, frame, palette);
  }

  static void _speedLines(
    Canvas canvas,
    SplashFrame frame,
    SplashPalette palette,
  ) {
    final bounds = JameiaCartMark.bounds;
    final unit = frame.cartUnit;
    final startX =
        frame.cartCenter.dx + (bounds.width / 2 + speedLineGap) * unit;
    final paint = Paint()
      ..color = palette.speedLine
      ..strokeWidth = speedLineWidth * unit
      ..strokeCap = StrokeCap.round;
    for (final (place, length) in speedLines) {
      final y = frame.cartCenter.dy + place * bounds.height * unit;
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + frame.speedLines * length * bounds.width * unit, y),
        paint,
      );
    }
  }
}
