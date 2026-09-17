import 'package:flutter/material.dart';

/// Staggered three-dot pulse painter behind [BrandedDotLoader].
class BrandedDotPainter extends CustomPainter {
  BrandedDotPainter(this.t, this.color, {this.animate = true});

  final double t;
  final Color color;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 3;
    final r = size.height / 2;
    final gap = (size.width - r * 2) / (count - 1);
    for (var i = 0; i < count; i++) {
      final phase = (t - i * 0.18) % 1.0;
      // 0→1→0 pulse using a smooth triangle.
      final pulse = animate ? (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0) : 0.4;
      final scale = 0.55 + 0.45 * pulse;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.4 + 0.6 * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(r + i * gap, size.height / 2), r * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BrandedDotPainter old) =>
      old.t != t || old.color != color;
}
