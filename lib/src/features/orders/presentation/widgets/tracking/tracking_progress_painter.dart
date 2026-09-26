import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/order_status.dart';

/// Paints the tracking journey: [OrderStatus.progressSteps] pill segments on
/// the to-do track, each filled in brand green from the START edge (mirrored
/// in RTL) by `clamp(fill − i, 0, 1)` of its width. The [current] segment's
/// fill breathes with [pulse] (alpha `1 − _pulseDepth × pulse`). Repaints on
/// [repaint] only — the widget above never rebuilds per frame.
class TrackingProgressPainter extends CustomPainter {
  TrackingProgressPainter({
    required this.fill,
    required this.pulse,
    required Listenable super.repaint,
    required this.current,
    required this.gap,
    required this.textDirection,
  });

  /// How much of the fill the current segment loses at the top of a breath.
  static const double _pulseDepth = 0.45;
  static const double _half = 0.5;
  static const double _full = 1;

  /// Filled segments, `0 … progressSteps` (fractional while it sweeps).
  final Animation<double> fill;

  /// `0` at rest, `1` at the top of a breath.
  final Animation<double> pulse;

  /// 0-based step of the order.
  final int current;
  final double gap;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const steps = OrderStatus.progressSteps;
    final segment = (size.width - gap * (steps - 1)) / steps;
    if (segment <= 0) return;
    final radius = Radius.circular(size.height * _half);
    final rtl = textDirection == TextDirection.rtl;
    final track = Paint()..color = AppColors.trackingLineTodo;
    final done = Paint();
    for (var i = 0; i < steps; i++) {
      final offset = i * (segment + gap);
      final left = rtl ? size.width - offset - segment : offset;
      canvas.drawRRect(
        RRect.fromLTRBR(left, 0, left + segment, size.height, radius),
        track,
      );
      final share = (fill.value - i).clamp(0, _full).toDouble();
      if (share <= 0) continue;
      final width = segment * share;
      final start = rtl ? left + segment - width : left;
      done.color = i == current
          ? AppColors.primary.withValues(
              alpha: _full - _pulseDepth * pulse.value,
            )
          : AppColors.primary;
      canvas.drawRRect(
        RRect.fromLTRBR(start, 0, start + width, size.height, radius),
        done,
      );
    }
  }

  @override
  bool shouldRepaint(TrackingProgressPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.pulse != pulse ||
      oldDelegate.current != current ||
      oldDelegate.gap != gap ||
      oldDelegate.textDirection != textDirection;
}
