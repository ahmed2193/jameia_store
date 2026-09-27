import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Paints the five four-point stars of a `SparkleBurst` for one [progress]
/// (0 → 1): star `i` lives inside `Interval(i × 0.1, i × 0.1 + 0.5)`, grows
/// from nothing to its full size and back ([AppMotion.emphasized], a small
/// overshoot) and turns 45° while it lives. The stars sit at fixed fractions
/// of the painted box (top-start, top-end, end-middle, bottom-end,
/// start-middle), mirrored for RTL.
///
/// Repaints from [progress] alone (no widget rebuild per frame).
class SparklePainter extends CustomPainter {
  SparklePainter({
    required this.progress,
    required this.colors,
    required this.spread,
    required this.direction,
  }) : super(repaint: progress);

  /// Star centres as fractions of the painted box, in LTR.
  static const List<Offset> anchors = <Offset>[
    Offset(0.1, 0.1), // top-start
    Offset(0.9, 0.06), // top-end
    Offset(0.97, 0.5), // end-middle
    Offset(0.82, 0.94), // bottom-end
    Offset(0.03, 0.56), // start-middle
  ];

  /// Each star's size, as a share of the largest (half the [spread]).
  static const List<double> _sizes = <double>[1, 0.7, 0.85, 0.6, 0.75];

  /// Where star `i` starts inside the run, and how long it lives.
  static const double _stagger = 0.1;
  static const double _life = 0.5;

  /// Inner (waist) radius of a star as a share of its tip radius.
  static const double _waist = 0.3;
  static const double _quarterTurn = math.pi / 4;
  static const int _points = 4;

  final Animation<double> progress;
  final List<Color> colors;

  /// The ring around the child the stars live in; a star's tip radius is
  /// half of it.
  final double spread;
  final TextDirection direction;

  /// The centre of star [index] inside [size], mirrored for RTL.
  static Offset centerOf(int index, Size size, TextDirection direction) {
    final anchor = anchors[index];
    final x = direction == TextDirection.rtl ? 1 - anchor.dx : anchor.dx;
    return Offset(x * size.width, anchor.dy * size.height);
  }

  /// Star [index]'s life (0 → 1) at run [t], clamped.
  static double lifeOf(int index, double t) {
    final start = index * _stagger;
    return ((t - start) / _life).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    final t = progress.value;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < anchors.length; i++) {
      final life = lifeOf(i, t);
      if (life <= 0 || life >= 1) continue;
      // 0 → 1 → 0 across the star's life, with the pop's overshoot.
      final rise = 1 - (life * 2 - 1).abs();
      final scale = AppMotion.emphasized.transform(rise);
      final radius = spread / 2 * _sizes[i] * scale;
      if (radius <= 0) continue;
      paint.color = colors[i % colors.length];
      canvas.drawPath(
        _star(centerOf(i, size, direction), radius, life * _quarterTurn),
        paint,
      );
    }
  }

  static Path _star(Offset center, double radius, double turn) {
    final path = Path();
    const corners = _points * 2;
    for (var k = 0; k < corners; k++) {
      final angle = turn + k * math.pi / _points;
      final r = k.isEven ? radius : radius * _waist;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (k == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.spread != spread ||
      oldDelegate.direction != direction ||
      !_sameColors(oldDelegate.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
