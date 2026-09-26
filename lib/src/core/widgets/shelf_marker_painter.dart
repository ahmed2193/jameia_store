import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A hand-drawn marker stroke along the bottom of its box, drawn from the
/// reading start as [progress] runs 0 → 1 — the lime swoosh under a deal
/// price.
class ShelfMarkerPainter extends CustomPainter {
  ShelfMarkerPainter({
    required this.progress,
    required this.color,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final ui.TextDirection textDirection;

  /// Stroke thickness, and where it rides, as shares of the box height.
  static const double _thickness = 0.22;
  static const double _rideStart = 0.86;
  static const double _rideEnd = 0.78;
  static const double _sag = 0.98;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || size.isEmpty) return;
    final ltr = textDirection == ui.TextDirection.ltr;
    final from = Offset(ltr ? 0 : size.width, size.height * _rideStart);
    final to = Offset(ltr ? size.width : 0, size.height * _rideEnd);
    final stroke = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(size.width / 2, size.height * _sag, to.dx, to.dy);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height * _thickness;
    for (final metric in stroke.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(ShelfMarkerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.textDirection != textDirection;
}
