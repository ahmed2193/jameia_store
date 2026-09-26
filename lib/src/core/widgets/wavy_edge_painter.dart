import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Fills its box with [color] down to a soft hand-drawn wave along the
/// bottom: the torn-paper edge where a collection's tinted hero meets the
/// white page. The wave is fixed (a seeded mix of two ripples), so it looks
/// the same on every frame and every screen width.
class WavyEdgePainter extends CustomPainter {
  const WavyEdgePainter({required this.color, required this.depth});

  final Color color;

  /// How far the wave dips below the band's straight bottom.
  final double depth;

  /// Ripple lengths, as shares of the width, and their mix.
  static const double _longWave = 0.9;
  static const double _shortWave = 0.23;
  static const double _shortShare = 0.35;
  static const int _steps = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final band = size.height - depth;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, band);
    for (var i = _steps; i >= 0; i--) {
      final x = size.width * i / _steps;
      final t = x / size.width;
      final ripple =
          math.sin(t * math.pi * 2 / _longWave) * (1 - _shortShare) +
          math.sin(t * math.pi * 2 / _shortWave) * _shortShare;
      // Ripple −1…1 → a dip of 0…depth below the band.
      path.lineTo(x, band + depth * (ripple + 1) / 2);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(WavyEdgePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.depth != depth;
}
