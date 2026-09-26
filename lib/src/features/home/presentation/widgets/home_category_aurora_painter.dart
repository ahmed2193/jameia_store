import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../../config/theme/app_colors.dart';

/// The moving backdrop of an aisle tile: a rounded pale [base] with two soft
/// glows — one in the tile's [glow] colour, one of light — circling opposite
/// corners in opposite directions, one lap per cycle of [progress]. [phase]
/// (0–1) is where on the lap this tile starts, so neighbours never move in
/// step.
///
/// Repaints on [progress] ticks only — nothing rebuilds — and makes its two
/// glow shaders once per size.
class HomeCategoryAuroraPainter extends CustomPainter {
  HomeCategoryAuroraPainter({
    required this.progress,
    required this.phase,
    required this.base,
    required this.glow,
    required this.radius,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double phase;
  final Color base;
  final Color glow;

  /// Corner radius of the tile.
  final double radius;

  /// Radius of each glow, as a share of the tile's side.
  static const double _glowShare = 0.62;
  static const double _lightShare = 0.5;

  /// Where each glow circles, and how far out, as shares of the side.
  static const Offset _glowCentre = Offset(0.24, 0.22);
  static const Offset _lightCentre = Offset(0.8, 0.8);
  static const double _orbitShare = 0.14;

  static const double _glowAlpha = 0.42;
  static const double _lightAlpha = 0.85;

  Size? _preparedFor;
  late Paint _basePaint;
  late Paint _glowPaint;
  late Paint _lightPaint;

  void _prepare(Size size) {
    if (_preparedFor == size) return;
    _preparedFor = size;
    final side = size.shortestSide;
    _basePaint = Paint()..color = base;
    _glowPaint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, side * _glowShare, [
        glow.withValues(alpha: _glowAlpha),
        glow.withValues(alpha: 0),
      ]);
    _lightPaint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, side * _lightShare, [
        AppColors.white.withValues(alpha: _lightAlpha),
        AppColors.white.withValues(alpha: 0),
      ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _prepare(size);
    final side = size.shortestSide;
    final angle = (progress.value + phase) * 2 * math.pi;
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      )
      ..drawPaint(_basePaint);
    _drawGlow(canvas, size, _glowCentre, angle, side * _glowShare, _glowPaint);
    _drawGlow(
      canvas,
      size,
      _lightCentre,
      -angle,
      side * _lightShare,
      _lightPaint,
    );
    canvas.restore();
  }

  /// Draws one glow ([paint]'s shader is centred on the origin) at its place
  /// on its circle.
  void _drawGlow(
    Canvas canvas,
    Size size,
    Offset centre,
    double angle,
    double glowRadius,
    Paint paint,
  ) {
    final orbit = size.shortestSide * _orbitShare;
    canvas
      ..save()
      ..translate(
        size.width * centre.dx + orbit * math.cos(angle),
        size.height * centre.dy + orbit * math.sin(angle),
      )
      ..drawCircle(Offset.zero, glowRadius, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(HomeCategoryAuroraPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.base != base ||
      oldDelegate.glow != glow ||
      oldDelegate.radius != radius;
}
