import 'package:flutter/widgets.dart';

/// The speed lines streaming out behind the first-order rider: three rounded
/// strokes that leave the rider's back, travel towards the start edge and
/// fade as they go — two passes per lap of [progress], so a lap ends where
/// it began (the resting pose draws them at their starting places). Mirrors
/// for [textDirection] RTL (the rider rides the other way). Repaints from
/// [progress] alone.
class HomeSpeedLinesPainter extends CustomPainter {
  HomeSpeedLinesPainter({
    required this.progress,
    required this.color,
    required this.textDirection,
    required this.strokeWidth,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final TextDirection textDirection;
  final double strokeWidth;

  /// Per line: height (share of the box), length (share of the width) and
  /// where on its pass it starts, so the three never move as one.
  static const List<double> _rows = <double>[0.3, 0.52, 0.74];
  static const List<double> _lengths = <double>[0.42, 0.62, 0.36];
  static const List<double> _offsets = <double>[0, 0.4, 0.72];
  static const double _passesPerLap = 2;

  /// How far a line travels on a pass, as a share of the width.
  static const double _travel = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final rtl = textDirection == TextDirection.rtl;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _rows.length; i++) {
      final pass = (progress.value * _passesPerLap + _offsets[i]) % 1;
      // The line's head leaves the rider's back (the end side of the box)
      // and drifts towards the start edge, shrinking and fading.
      final head = size.width * (1 - _travel * pass);
      final length = size.width * _lengths[i] * (1 - pass / 2);
      final tail = (head - length).clamp(0.0, size.width);
      final y = size.height * _rows[i];
      paint.color = color.withValues(alpha: color.a * (1 - pass));
      canvas.drawLine(
        Offset(rtl ? size.width - tail : tail, y),
        Offset(rtl ? size.width - head : head, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HomeSpeedLinesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.strokeWidth != strokeWidth;
}
