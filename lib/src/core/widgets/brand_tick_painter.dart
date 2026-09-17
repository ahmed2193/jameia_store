import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// A circle that draws itself, then a check stroke that traces in — the classic
/// success tick. [t] 0→1 drives both phases.
class BrandTickPainter extends CustomPainter {
  BrandTickPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Phase 1 (0→0.5): ring scales in. Phase 2 (0.5→1): check traces.
    final ringT = (t / 0.5).clamp(0.0, 1.0);
    final checkT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r * ringT, ringPaint);

    if (checkT > 0) {
      final p1 = Offset(c.dx - r * 0.42, c.dy + r * 0.02);
      final mid = Offset(c.dx - r * 0.10, c.dy + r * 0.34);
      final p2 = Offset(c.dx + r * 0.44, c.dy - r * 0.30);
      final path = Path()..moveTo(p1.dx, p1.dy);
      // First leg fully drawn over the first half of checkT, second over the rest.
      if (checkT <= 0.5) {
        final f = checkT / 0.5;
        path.lineTo(p1.dx + (mid.dx - p1.dx) * f, p1.dy + (mid.dy - p1.dy) * f);
      } else {
        final f = (checkT - 0.5) / 0.5;
        path.lineTo(mid.dx, mid.dy);
        path.lineTo(
          mid.dx + (p2.dx - mid.dx) * f,
          mid.dy + (p2.dy - mid.dy) * f,
        );
      }
      final checkPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BrandTickPainter old) =>
      old.t != t || old.color != color;
}
