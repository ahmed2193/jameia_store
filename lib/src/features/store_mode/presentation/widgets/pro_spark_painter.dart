import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';

/// Three short strokes bursting away from the box's bottom-end corner — the
/// "spark" doodle beside the hero arch. [mirrored] flips it for RTL so the
/// burst still points away from the arch.
///
/// The strokes pop out one after another as [progress] runs 0 → 1 (each one
/// grows from its inner end with a slight overshoot); at 1 all three rest at
/// full length. Repaints only this painter.
class ProSparkPainter extends CustomPainter {
  ProSparkPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
    this.mirrored = false,
  }) : super(repaint: progress);

  /// Stroke directions: towards the start, the top-start diagonal, the top.
  static const List<double> _angles = [math.pi, math.pi * 1.25, math.pi * 1.5];

  /// Where each stroke starts and ends, as fractions of the box's side.
  static const double _inner = 0.35;
  static const double _outer = 0.9;

  /// Share of [progress] each stroke takes to grow, and the offset between
  /// two strokes' starts (the last one ends exactly at 1).
  static const double _growShare = 0.5;
  static const double _stagger = 0.25;

  final Color color;
  final double strokeWidth;
  final Animation<double> progress;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final focus = Offset(mirrored ? 0 : size.width, size.height);
    final direction = mirrored ? -1.0 : 1.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final t = progress.value;
    for (var i = 0; i < _angles.length; i++) {
      final local = ((t - i * _stagger) / _growShare).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final grown = AppSprings.snappy.transform(local);
      final angle = _angles[i];
      final unit = Offset(math.cos(angle) * direction, math.sin(angle));
      final start = side * _inner;
      final end = start + side * (_outer - _inner) * grown;
      canvas.drawLine(focus + unit * start, focus + unit * end, paint);
    }
  }

  @override
  bool shouldRepaint(ProSparkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.progress != progress;
}
