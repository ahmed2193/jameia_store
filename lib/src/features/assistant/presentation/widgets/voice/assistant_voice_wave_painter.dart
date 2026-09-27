import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';

/// The recording's waveform: one round-capped bar per level, the newest at
/// the end of the line, older ones toward the start; slots with no level
/// yet are dots on a lighter track (WhatsApp's dotted line).
class AssistantVoiceWavePainter extends CustomPainter {
  const AssistantVoiceWavePainter({
    required this.levels,
    required this.color,
    required this.trackColor,
    required this.textDirection,
  });

  /// Oldest first, each 0..1.
  final List<double> levels;
  final Color color;
  final Color trackColor;
  final TextDirection textDirection;

  static const double barWidth = AppSize.s3;
  static const double gap = AppSize.s2;

  @override
  void paint(Canvas canvas, Size size) {
    const step = barWidth + gap;
    final slots = ((size.width + gap) / step).floor();
    if (slots <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final middle = size.height / 2;
    // A round cap adds half a bar at each end: a level of 0 is a dot.
    final reach = math.max(0.0, size.height - barWidth);
    final rtl = textDirection == TextDirection.rtl;
    for (var slot = 0; slot < slots; slot++) {
      final index = levels.length - 1 - slot;
      final heard = index >= 0;
      final half = heard ? reach * levels[index] / 2 : 0.0;
      final x = rtl
          ? barWidth / 2 + slot * step
          : size.width - barWidth / 2 - slot * step;
      paint.color = heard ? color : trackColor;
      canvas.drawLine(
        Offset(x, middle - half),
        Offset(x, middle + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AssistantVoiceWavePainter oldDelegate) =>
      !identical(levels, oldDelegate.levels) ||
      color != oldDelegate.color ||
      trackColor != oldDelegate.trackColor ||
      textDirection != oldDelegate.textDirection;

  /// Pure drawing, no meaning: a screen reader need not hear of each bar.
  @override
  bool shouldRebuildSemantics(AssistantVoiceWavePainter oldDelegate) => false;
}
