import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

/// The hero's dome: a filled arch with a round top and straight-ish sides that
/// run past the bottom of its box, outlined by a thick stroke (the bottom is
/// not stroked — the band's wavy edge cuts it).
///
/// The outline draws itself: [draw] (0 → 1) grows both sides from their feet
/// up to the crown at once, so the doodle reads the same in LTR and RTL. The
/// fill blends from [fromFill] to [fill] with [fillIn]. Both animations only
/// repaint this painter — no widget rebuilds.
class ProArchPainter extends CustomPainter {
  ProArchPainter({
    required this.fill,
    required this.fromFill,
    required this.stroke,
    required this.strokeWidth,
    required this.sideInset,
    required this.draw,
    required this.fillIn,
  }) : super(repaint: Listenable.merge([draw, fillIn]));

  /// Where the sides stop being vertical, as a fraction of the height.
  static const double _shoulder = 0.3;

  /// How far the crown's handles reach towards the sides (0 = pointed top,
  /// 1 = flat top).
  static const double _crown = 0.45;

  final Color fill;

  /// Fill the arch starts from (the previous plan's, or a transparent one).
  final Color fromFill;
  final Color stroke;
  final double strokeWidth;

  /// Gap between the box's sides and the arch's sides.
  final double sideInset;
  final Animation<double> draw;
  final Animation<double> fillIn;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final left = sideInset + half;
    final right = size.width - sideInset - half;
    final top = half;
    final bottom = size.height + strokeWidth;
    final mid = size.width / 2;
    final shoulder = size.height * _shoulder;
    final startSide = Path()
      ..moveTo(left, bottom)
      ..cubicTo(left, shoulder, left + (mid - left) * _crown, top, mid, top);
    final endSide = Path()
      ..moveTo(right, bottom)
      ..cubicTo(right, shoulder, right - (right - mid) * _crown, top, mid, top);
    final dome = Path()
      ..moveTo(left, bottom)
      ..cubicTo(left, shoulder, left + (mid - left) * _crown, top, mid, top)
      ..cubicTo(
        right - (right - mid) * _crown,
        top,
        right,
        shoulder,
        right,
        bottom,
      )
      ..close();
    final fillColor = Color.lerp(fromFill, fill, fillIn.value) ?? fill;
    canvas.drawPath(dome, Paint()..color = fillColor);

    final progress = draw.value;
    if (progress <= 0) return;
    final outline = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final side in [startSide, endSide]) {
      for (final PathMetric metric in side.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          outline,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ProArchPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.fromFill != fromFill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.sideInset != sideInset ||
      oldDelegate.draw != draw ||
      oldDelegate.fillIn != fillIn;
}
