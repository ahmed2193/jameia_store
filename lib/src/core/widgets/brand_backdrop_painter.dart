import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../config/theme/app_colors.dart';
import 'brand_backdrop_ring.dart';

/// Paints the moving layer of a brand backdrop: the spread of groceries
/// around the logo, turning slowly and breathing in and out like a camera
/// easing over a table ([time]). [reveal] fades and settles the spread in
/// when the page opens. The green and the light under it are a still layer
/// of their own (`BrandBackdropBasePainter`, BX-02), so a frame here is one
/// transformed picture ([BrandBackdropRing]); the reveal's fade is a layer
/// bounded to this box.
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

  final BrandBackdropRing ring;

  /// The header band the spread frames, in this painter's coordinates; the
  /// spread turns about its centre.
  final Rect band;
  final ValueListenable<Duration> time;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final shown = reveal.value;
    if (shown <= 0) return;
    final center = band.center;
    final micros = time.value.inMicroseconds;
    final turn = _loop(micros, turnPeriod) * 2 * math.pi;
    final breath = math.sin(_loop(micros, breathPeriod) * 2 * math.pi);
    final scale =
        (1 + breathDepth * breath) * (settleFrom + (1 - settleFrom) * shown);
    final fading = shown < 1;
    if (fading) {
      // Bounded to the backdrop, never an unbounded offscreen buffer.
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = AppColors.black.withValues(alpha: shown),
      );
    }
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turn)
      ..scale(scale)
      ..drawPicture(ring.pictureFor(band.size))
      ..restore();
    if (fading) canvas.restore();
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
