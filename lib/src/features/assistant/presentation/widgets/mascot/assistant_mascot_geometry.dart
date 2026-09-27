import 'package:flutter/painting.dart';

import '../../../../../config/theme/app_colors.dart';

/// The mascot's fixed shapes at one drawing size — body, sprout, their
/// paints and the body gradient — built once per size and shared by every
/// mascot of that size.
///
/// Laid out in pixels: nothing relies on a large canvas scale for its size.
class AssistantMascotGeometry {
  AssistantMascotGeometry._(this.unit)
    : body = _bodyPath(unit),
      stem = _stemPath(unit),
      leftLeaf = _leaf(unit, _leftLeafFrom, _leftLeafTo, _leftBulge),
      rightLeaf = _leaf(unit, _rightLeafFrom, _rightLeafTo, _rightBulge),
      leftVein = _veinPath(unit),
      bodyFill = Paint()
        ..shader = const LinearGradient(
          begin: _lightFrom,
          end: _lightTo,
          colors: [
            AppColors.brandDarkBg,
            AppColors.primary,
            AppColors.primaryDark,
          ],
          stops: [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(0, 0, unit, unit)),
      rim = _stroke(AppColors.white, rimWidth * 2 * unit),
      stemPaint = _stroke(AppColors.brandDeep, _stemWidth * unit),
      veinPaint = _stroke(AppColors.brandDarkBg, _veinWidth * unit),
      leafFill = Paint()..color = AppColors.brandDeep;

  /// The geometry for a drawing [unit] pixels wide.
  static AssistantMascotGeometry of(double unit) {
    final cached = _cache[unit];
    if (cached != null) return cached;
    if (_cache.length >= _maxSizes) _cache.clear();
    return _cache[unit] = AssistantMascotGeometry._(unit);
  }

  static final Map<double, AssistantMascotGeometry> _cache = {};
  static const int _maxSizes = 12;

  /// The light falls on the body from the top left. A linear gradient on
  /// purpose: a radial one crashes the emulator's GPU (Impeller on
  /// SwiftShader), and the gloss already gives the body its roundness.
  static const Alignment _lightFrom = Alignment(-0.5, -0.8);
  static const Alignment _lightTo = Alignment(0.5, 0.9);

  /// Half the white sticker rim, in units.
  static const double rimWidth = 0.075;
  static const double _stemWidth = 0.034;
  static const double _veinWidth = 0.01;

  static const Offset _leftLeafFrom = Offset(0.505, 0.13);
  static const Offset _leftLeafTo = Offset(0.3, 0.07);
  static const double _leftBulge = 0.075;
  static const Offset _rightLeafFrom = Offset(0.515, 0.125);
  static const Offset _rightLeafTo = Offset(0.67, 0.075);
  static const double _rightBulge = -0.05;
  static const double _backBulge = 0.35;

  final double unit;
  final Path body;
  final Path stem;
  final Path leftLeaf;
  final Path rightLeaf;
  final Path leftVein;
  final Paint bodyFill;
  final Paint rim;
  final Paint stemPaint;
  final Paint veinPaint;
  final Paint leafFill;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Path _bodyPath(double u) => Path()
    ..moveTo(0.1 * u, 0.6 * u)
    ..cubicTo(0.1 * u, 0.36 * u, 0.28 * u, 0.22 * u, 0.5 * u, 0.22 * u)
    ..cubicTo(0.72 * u, 0.22 * u, 0.9 * u, 0.36 * u, 0.9 * u, 0.6 * u)
    ..cubicTo(0.9 * u, 0.84 * u, 0.74 * u, 0.94 * u, 0.5 * u, 0.94 * u)
    ..cubicTo(0.26 * u, 0.94 * u, 0.1 * u, 0.84 * u, 0.1 * u, 0.6 * u)
    ..close();

  static Path _stemPath(double u) => Path()
    ..moveTo(0.5 * u, 0.25 * u)
    ..quadraticBezierTo(0.47 * u, 0.18 * u, 0.51 * u, 0.125 * u);

  static Path _veinPath(double u) => Path()
    ..moveTo(0.49 * u, 0.125 * u)
    ..quadraticBezierTo(0.4 * u, 0.085 * u, 0.33 * u, 0.078 * u);

  /// A leaf from [from] to [to] (units), its belly bulging by [bulge].
  static Path _leaf(double u, Offset from, Offset to, double bulge) {
    final mid = (from + to) / 2;
    final along = to - from;
    final normal = Offset(-along.dy, along.dx) / along.distance * bulge;
    final a = (mid + normal) * u;
    final b = (mid - normal * _backBulge) * u;
    final start = from * u;
    final end = to * u;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(a.dx, a.dy, end.dx, end.dy)
      ..quadraticBezierTo(b.dx, b.dy, start.dx, start.dy)
      ..close();
  }
}
