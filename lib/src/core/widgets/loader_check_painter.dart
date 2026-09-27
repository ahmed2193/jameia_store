import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// A check drawing itself: the short stroke, then the long one, with round
/// ends, [progress] of the way (0 → 1) — the tick inside [LoaderDoneMark].
class LoaderCheckPainter extends CustomPainter {
  LoaderCheckPainter({required this.progress, required this.color})
    : super(repaint: progress);

  // The tick's three points as shares of the box.
  static const Offset _start = Offset(0.27, 0.53);
  static const Offset _corner = Offset(0.44, 0.69);
  static const Offset _end = Offset(0.74, 0.36);
  static const double _strokeShare = 0.1;

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = progress.value.clamp(0.0, 1.0);
    if (drawn == 0) return;
    Offset at(Offset share) =>
        Offset(share.dx * size.width, share.dy * size.height);
    final tick = Path()
      ..moveTo(at(_start).dx, at(_start).dy)
      ..lineTo(at(_corner).dx, at(_corner).dy)
      ..lineTo(at(_end).dx, at(_end).dy);
    final metric = tick.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * drawn),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * _strokeShare
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant LoaderCheckPainter old) =>
      old.progress != progress || old.color != color;
}
