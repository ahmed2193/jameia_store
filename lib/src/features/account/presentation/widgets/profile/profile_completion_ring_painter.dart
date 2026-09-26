import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints the completion ring: a full [trackColor] circle and, from twelve
/// o'clock clockwise, a [progress] (0..1) arc in [color] with round caps.
class ProfileCompletionRingPainter extends CustomPainter {
  const ProfileCompletionRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  static const double _fullTurn = 2 * math.pi;
  static const double _twelveOClock = -math.pi / 2;

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawOval(rect, track);
    final sweep = progress.clamp(0, 1) * _fullTurn;
    if (sweep <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, _twelveOClock, sweep, false, arc);
  }

  @override
  bool shouldRepaint(ProfileCompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
