import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// An × drawing itself: the falling stroke, then the rising one, with round
/// ends, [progress] of the way (0 → 1) — the mark inside [LoaderFailMark],
/// the same stroke weight as [LoaderCheckPainter]'s tick.
class LoaderCrossPainter extends CustomPainter {
  LoaderCrossPainter({required this.progress, required this.color})
    : super(repaint: progress);

  // The two strokes' ends as shares of the box.
  static const double _near = 0.34;
  static const double _far = 0.66;
  static const double _strokeShare = 0.1;

  /// Each stroke takes half of the draw.
  static const double _half = 0.5;

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = progress.value.clamp(0.0, 1.0);
    if (drawn == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * _strokeShare
      ..strokeCap = StrokeCap.round;
    Offset at(double x, double y) => Offset(x * size.width, y * size.height);
    final first = (drawn / _half).clamp(0.0, 1.0);
    final from = at(_near, _near);
    canvas.drawLine(from, Offset.lerp(from, at(_far, _far), first)!, paint);
    final second = ((drawn - _half) / _half).clamp(0.0, 1.0);
    if (second == 0) return;
    final start = at(_far, _near);
    canvas.drawLine(start, Offset.lerp(start, at(_near, _far), second)!, paint);
  }

  @override
  bool shouldRepaint(covariant LoaderCrossPainter old) =>
      old.progress != progress || old.color != color;
}
