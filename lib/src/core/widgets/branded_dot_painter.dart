import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../motion/motion.dart';

/// The two Hero loader dots — the bag's green and the cape's amber — circling
/// each other on a flat ring seen edge-on: they swap places twice a loop and
/// each passes in front once. The dot in front grows and the one behind
/// shrinks and dims, so a swap reads as depth; at speed a dot stretches a
/// little along its path, and after each swap both rest side by side for a
/// beat, so the loop breathes instead of spinning.
///
/// [phase] is the loop position (0 → 1 = one full circle; it repaints on
/// every tick of it without a rebuild). The box is `width × width / 2`
/// ([heightShare]); at phase 0 the dots sit side by side, [lead] first.
///
/// [opacity] (optional) fades both dots: the reduced-motion breathe that
/// replaces the orbit ([breatheOf]); the painter repaints on its ticks too.
class BrandedDotPainter extends CustomPainter {
  BrandedDotPainter({
    required this.phase,
    required this.lead,
    required this.trail,
    this.opacity,
  }) : super(
         repaint: opacity == null ? phase : Listenable.merge([phase, opacity]),
       );

  /// Box height for a given width.
  static const double heightShare = 0.5;

  /// The dim end of the reduced-motion breathe (the bright end is 1).
  static const double breatheLow = 0.4;

  /// The reduced-motion breathe for [opacity]: [loop] (repeating in reverse,
  /// [AppMotion.breathe] each way) eased between [breatheLow] and full.
  static Animation<double> breatheOf(Animation<double> loop) => loop.drive(
    Tween<double>(
      begin: breatheLow,
      end: 1,
    ).chain(CurveTween(curve: AppMotion.machEaseInOut)),
  );

  static const double _radiusShare = 0.2;
  static const double _ringShare = 0.29;

  /// The front dot grows by this share, the back one shrinks by it.
  static const double _depth = 0.2;

  /// Alpha the back dot loses at the far side of the ring.
  static const double _backDim = 0.25;

  /// Along-path stretch at top speed (the cross-axis squashes half of it).
  static const double _stretch = 0.18;

  /// Share of each swap the dots rest side by side.
  static const double _rest = 0.16;
  static const Curve _swap = Curves.easeInOutCubic;

  /// Slope of [_swap] (Flutter's bezier `easeInOutCubic`) at its steepest,
  /// the middle — measured.
  static const double _swapPeakSlope = 2.75;

  /// Step of the numeric slope that measures the speed.
  static const double _probe = 0.002;

  final Animation<double> phase;
  final Color lead;
  final Color trail;

  /// Both dots' opacity (0 → 1); null = full.
  final Animation<double>? opacity;

  /// Re-coloured per dot: a frame allocates nothing.
  final Paint _paint = Paint();

  /// How far through a swap the dots are (0 → 1) at [local] of its time.
  static double _progress(double local) {
    final moving = ((local - _rest / 2) / (1 - _rest)).clamp(0.0, 1.0);
    return _swap.transform(moving);
  }

  /// 0 at rest → 1 at the steepest point of a swap.
  static double _pace(double local) {
    final before = _progress((local - _probe).clamp(0.0, 1.0));
    final after = _progress((local + _probe).clamp(0.0, 1.0));
    return (after - before) / (2 * _probe) * (1 - _rest) / _swapPeakSlope;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * _radiusShare;
    final ring = size.width * _ringShare;
    final swaps = (phase.value % 1) * 2;
    final swap = swaps.floor();
    final local = swaps - swap;
    final angle = (swap + _progress(local)) * math.pi;
    final across = math.cos(angle);
    // +1: the lead dot is nearest; −1: the trail dot is.
    final depth = math.sin(angle);
    final speed = (depth.abs() * _pace(local)).clamp(0.0, 1.0);
    final leadX = center.dx - ring * across;
    final trailX = center.dx + ring * across;
    // The dot behind first, so the one in front covers it.
    if (depth >= 0) {
      _dot(canvas, trailX, center.dy, radius, -depth, speed, trail);
      _dot(canvas, leadX, center.dy, radius, depth, speed, lead);
    } else {
      _dot(canvas, leadX, center.dy, radius, depth, speed, lead);
      _dot(canvas, trailX, center.dy, radius, -depth, speed, trail);
    }
  }

  void _dot(
    Canvas canvas,
    double x,
    double y,
    double radius,
    double depth,
    double speed,
    Color color,
  ) {
    final diameter = radius * 2 * (1 + _depth * depth);
    final alpha =
        (depth < 0 ? 1 + _backDim * depth : 1.0) * (opacity?.value ?? 1);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: diameter * (1 + _stretch * speed),
        height: diameter * (1 - _stretch * speed / 2),
      ),
      _paint..color = color.withValues(alpha: color.a * alpha),
    );
  }

  @override
  bool shouldRepaint(covariant BrandedDotPainter old) =>
      old.phase != phase ||
      old.lead != lead ||
      old.trail != trail ||
      old.opacity != opacity;
}
