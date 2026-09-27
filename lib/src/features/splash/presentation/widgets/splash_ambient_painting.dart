import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'splash_frame.dart';
import 'splash_palette.dart';

/// The living colour behind the logo: a few large soft blobs drifting slowly
/// (lighter green, warm yellow, deep green) and a glow that follows the logo
/// — and the finger, see `SplashTouch`. Radial gradients only, no blur, so it
/// stays cheap on every frame.
abstract final class SplashAmbientPainting {
  /// Glow radius as a share of the screen's shorter side, and its strength.
  static const double glowRadius = 0.85;
  static const double glowOpacity = 0.6;

  /// How far the blobs wander, as a share of the shorter side.
  static const double drift = 0.08;

  /// Each blob: anchor (share of width, height), radius (share of the
  /// shorter side), drift period (ms), phase (radians), opacity.
  static const List<(Offset, double, double, double, double)> blobs = [
    (Offset(0.1, 0.18), 0.75, 5200, 0, 0.45),
    (Offset(0.95, 0.8), 0.85, 6400, 2.1, 0.3),
    (Offset(0.9, 0.08), 0.6, 4600, 4.2, 0.3),
  ];

  static void paint(
    Canvas canvas,
    Size size,
    SplashFrame frame,
    SplashPalette palette, {
    Offset glowShift = Offset.zero,
  }) {
    if (frame.ambient <= 0) return;
    final side = size.shortestSide;
    for (var i = 0; i < blobs.length; i++) {
      final (anchor, radius, period, phase, opacity) = blobs[i];
      final angle = frame.ms / period * 2 * math.pi + phase;
      final center = Offset(
        anchor.dx * size.width + math.cos(angle) * drift * side,
        anchor.dy * size.height + math.sin(angle) * drift * side,
      );
      _soft(
        canvas,
        center,
        radius * side,
        palette.aurora[i % palette.aurora.length],
        opacity * frame.ambient,
      );
    }
    _soft(
      canvas,
      (frame.glowCenter ?? size.center(Offset.zero)) + glowShift,
      glowRadius * side,
      palette.glow,
      glowOpacity * frame.ambient,
    );
  }

  static void _soft(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(center, radius, [
          color.withValues(alpha: color.a * opacity),
          color.withValues(alpha: 0),
        ]),
    );
  }
}
