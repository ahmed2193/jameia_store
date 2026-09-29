import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/design/hero_mark.dart';
import '../../../../core/design/hero_mark_painting.dart';
import 'splash_ambient_painting.dart';
import 'splash_confetti_painting.dart';
import 'splash_frame.dart';
import 'splash_grocery_painting.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';
import 'splash_ripple_painting.dart';
import 'splash_wordmark_painting.dart';

/// Paints one whole splash frame in one palette, back to front: background,
/// living colour, rings, speed streaks, the name on its way, the mark (with
/// any groceries in its bag) and the confetti. While the light sweeps, the
/// name and the mark share a layer so the band lights only them.
abstract final class SplashScenePainting {
  /// Streaks trailing behind and under the flying bag, which swoops up and
  /// forward: across (share of the bag's width from its middle) and length
  /// (share of the mark's height).
  static const List<(double, double)> speedLines = [
    (-0.28, 0.55),
    (0, 0.8),
    (0.28, 0.45),
  ];

  /// Gap under the bag before the streaks start, their width (design units)
  /// and their slant back from straight down (radians).
  static const double speedLineGap = 8;
  static const double speedLineWidth = 3.5;
  static const double speedLineSlant = 0.35;

  static final double _bagWidth =
      HeroMark.bagBottomRight.dx - HeroMark.bagBottomLeft.dx;

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
    final shining = frame.shine > 0 && frame.shine < 1;
    final lockup = layout.lockupBounds;
    if (shining) {
      canvas.saveLayer(
        lockup.inflate(SplashWordmarkPainting.shineMargin),
        Paint(),
      );
    }
    final pose = frame.pose;
    if (frame.deliveries.isNotEmpty) {
      // The bag is solid: a piece passing behind it is hidden, even where
      // the "h" is cut out of it.
      final bag = HeroMark.bag.transform(
        HeroMarkPainting.matrixFor(
          center: frame.markCenter,
          unit: frame.markUnit,
          pose: pose,
        ),
      );
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Offset.zero & size)
            ..addPath(bag, Offset.zero),
        );
      SplashWordmarkPainting.paintDeliveries(canvas, layout, frame, palette);
      canvas.restore();
    }
    final groceries = frame.groceries;
    HeroMarkPainting.paint(
      canvas,
      center: frame.markCenter,
      unit: frame.markUnit,
      colors: palette.mark,
      pose: pose,
      inside: groceries.isEmpty
          ? null
          : (canvas) => SplashGroceryPainting.paint(canvas, palette, groceries),
    );
    if (shining) {
      SplashWordmarkPainting.paintShine(canvas, lockup, frame.shine, palette);
      canvas.restore();
    }
    SplashConfettiPainting.paint(canvas, frame, palette);
  }

  static void _speedLines(
    Canvas canvas,
    SplashFrame frame,
    SplashPalette palette,
  ) {
    final unit = frame.markUnit;
    final ground =
        SplashLayout.groundOf(frame.markCenter, unit) -
        Offset(0, frame.lift * unit);
    final back = Offset(
      -math.sin(speedLineSlant) * frame.forward,
      math.cos(speedLineSlant),
    );
    final color = palette.speedLine;
    for (final (across, length) in speedLines) {
      final start = Offset(
        ground.dx + across * _bagWidth * unit * frame.forward,
        ground.dy + speedLineGap * unit,
      );
      final reach = frame.speedLines * length * HeroMark.bounds.height * unit;
      if (reach < 1) continue;
      final end = start + back * reach;
      // Solid at the bag, fading away behind it.
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = speedLineWidth * unit
          ..strokeCap = StrokeCap.round
          ..shader = Gradient.linear(start, end, [
            color,
            color.withValues(alpha: 0),
          ]),
      );
    }
  }
}
