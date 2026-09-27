import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../design/hero_mark.dart';
import '../design/hero_mark_idle.dart';
import '../design/hero_mark_painting.dart';

/// Paints the Hero mark alone, at ease at [idle] (`HeroMarkIdle`): fitted
/// into its box with room for the bob, and centred.
class HeroWavingMarkPainter extends CustomPainter {
  HeroWavingMarkPainter({required this.idle, required this.colors})
    : super(repaint: idle);

  /// Share of the box the mark's bounds fill.
  static const double fill = 0.88;

  final Animation<double> idle;
  final HeroMarkColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = HeroMark.bounds;
    final widthUnit = size.width / bounds.width;
    final heightUnit = size.height / (bounds.height + 2 * HeroMarkIdle.bob);
    final unit = (widthUnit < heightUnit ? widthUnit : heightUnit) * fill;
    HeroMarkPainting.paint(
      canvas,
      center: size.center(Offset.zero),
      unit: unit,
      colors: colors,
      pose: HeroMarkIdle.poseAt(idle.value),
    );
  }

  @override
  bool shouldRepaint(covariant HeroWavingMarkPainter old) =>
      old.idle != idle || old.colors != colors;
}
