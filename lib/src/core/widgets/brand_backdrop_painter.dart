import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../config/theme/app_colors.dart';
import 'brand_backdrop_ring.dart';

/// Paints a brand backdrop: the Hero green (lighter at the top start,
/// deeper at the bottom end), a soft light behind the logo, and the spread
/// of groceries around it, turning slowly and breathing in and out like a
/// camera easing over a table ([time]). [reveal] fades and settles the
/// spread in when the page opens.
///
/// Everything but the turn is fixed, and the spread itself is a recorded
/// picture ([BrandBackdropRing]), so a frame is one gradient, one glow and
/// one transformed picture.
class BrandBackdropPainter extends CustomPainter {
  BrandBackdropPainter({
    required this.ring,
    required this.band,
    required this.time,
    required this.reveal,
  }) : super(repaint: Listenable.merge([time, reveal]));

  /// One full turn of the spread, and one breath (in and out).
  static const Duration turnPeriod = Duration(seconds: 70);
  static const Duration breathPeriod = Duration(seconds: 13);

  /// How far a breath zooms in, and the scale the spread settles from.
  static const double breathDepth = 0.035;
  static const double settleFrom = 0.94;

  /// The light behind the logo: radius as a share of the band's shorter
  /// side, and its strength.
  static const double glowShare = 0.62;
  static const double glowOpacity = 0.8;

  static const List<Color> _gradient = [
    AppColors.brandDarkBg,
    AppColors.primary,
    AppColors.primaryDark,
  ];
  static const List<double> _gradientStops = [0, 0.55, 1];

  final BrandBackdropRing ring;

  /// The header band the spread frames, in this painter's coordinates; the
  /// spread turns about its centre.
  final Rect band;
  final ValueListenable<Duration> time;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          band.topLeft,
          band.bottomRight,
          _gradient,
          _gradientStops,
        ),
    );
    final center = band.center;
    final glowRadius = band.shortestSide * glowShare;
    final glow = AppColors.brandDarkBg;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(center, glowRadius, [
          glow.withValues(alpha: glowOpacity),
          glow.withValues(alpha: 0),
        ]),
    );

    final shown = reveal.value;
    if (shown <= 0) return;
    final micros = time.value.inMicroseconds;
    final turn = _loop(micros, turnPeriod) * 2 * math.pi;
    final breath = math.sin(_loop(micros, breathPeriod) * 2 * math.pi);
    final scale =
        (1 + breathDepth * breath) * (settleFrom + (1 - settleFrom) * shown);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turn)
      ..scale(scale);
    final fading = shown < 1;
    if (fading) {
      canvas.saveLayer(
        null,
        Paint()..color = AppColors.black.withValues(alpha: shown),
      );
    }
    canvas.drawPicture(ring.pictureFor(band.size));
    if (fading) canvas.restore();
    canvas.restore();
  }

  /// Where [micros] falls in one [period], 0 → 1.
  static double _loop(int micros, Duration period) =>
      (micros % period.inMicroseconds) / period.inMicroseconds;

  @override
  bool shouldRepaint(covariant BrandBackdropPainter old) =>
      old.ring != ring ||
      old.band != band ||
      old.time != time ||
      old.reveal != reveal;
}
