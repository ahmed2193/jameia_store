import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../../../../../config/theme/app_colors.dart';

/// Paints the journey as [segments] rounded bars split by [gap]: the first
/// [fill] segments in [fillColor] (fractional while a new stage fills in),
/// the rest in the todo grey. While a stage is in progress its segment also
/// carries a [fillColor] run from its start edge: a short stub at rest
/// ([sweep] 0) that grows across the segment as [sweep] rises to 1 and back
/// — the "working on it" cue, continuous at both ends of a lap. Mirrors in
/// RTL. Repaints through [repaint] only (no rebuilds).
class TrackingStageBarPainter extends CustomPainter {
  TrackingStageBarPainter({
    required this.fill,
    required this.sweep,
    required this.segments,
    required this.current,
    required this.inProgress,
    required this.gap,
    required this.fillColor,
    required this.textDirection,
    super.repaint,
  });

  /// Segments filled (fractional during a fill).
  final Animation<double> fill;

  /// How far the in-progress run reaches, 0 (the resting stub) → 1 (the
  /// whole segment).
  final Animation<double> sweep;
  final int segments;

  /// The segment of the stage in progress, or `null`.
  final int? current;
  final bool inProgress;
  final double gap;
  final Color fillColor;
  final TextDirection textDirection;

  /// The resting stub of an in-progress segment, as a share of it.
  static const double restShare = 0.3;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (segments <= 0 || size.isEmpty) return;
    final width = (size.width - gap * (segments - 1)) / segments;
    if (width <= 0) return;
    final radius = Radius.circular(size.height / 2);
    final filled = fill.value;
    for (var i = 0; i < segments; i++) {
      final start = i * (width + gap);
      final rect = _mirror(Rect.fromLTWH(start, 0, width, size.height), size);
      final track = RRect.fromRectAndRadius(rect, radius);
      _paint.color = AppColors.trackingLineTodo;
      canvas.drawRRect(track, _paint);

      final share = (filled - i).clamp(0.0, 1.0);
      if (share > 0) {
        _paint.color = fillColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            _mirror(Rect.fromLTWH(start, 0, width * share, size.height), size),
            radius,
          ),
          _paint,
        );
      }
      if (inProgress && i == current && share < 1) {
        _paintRun(canvas, start, width, size, radius);
      }
    }
  }

  /// The in-progress run inside its segment: from the start edge to the
  /// stub, or further while [sweep] is up.
  void _paintRun(
    Canvas canvas,
    double start,
    double width,
    Size size,
    Radius radius,
  ) {
    final reach = restShare + (1 - restShare) * sweep.value.clamp(0.0, 1.0);
    _paint.color = fillColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _mirror(Rect.fromLTWH(start, 0, width * reach, size.height), size),
        radius,
      ),
      _paint,
    );
  }

  Rect _mirror(Rect rect, Size size) => textDirection == TextDirection.rtl
      ? Rect.fromLTRB(
          size.width - rect.right,
          rect.top,
          size.width - rect.left,
          rect.bottom,
        )
      : rect;

  @override
  bool shouldRepaint(TrackingStageBarPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.current != current ||
      oldDelegate.inProgress != inProgress ||
      oldDelegate.gap != gap ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.fill != fill ||
      oldDelegate.sweep != sweep;
}
