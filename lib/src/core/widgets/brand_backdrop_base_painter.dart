import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../config/theme/app_colors.dart';

/// The still layer of a brand backdrop (BX-02): the Hero green (lighter at
/// the top start, deeper at the bottom end) and a soft light behind the
/// logo, framing [band]. It never listens to anything, so in its own
/// `RepaintBoundary` it is recorded once and only composited while the
/// spread turns above it (`BrandBackdropPainter`).
class BrandBackdropBasePainter extends CustomPainter {
  const BrandBackdropBasePainter({required this.band});

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

  /// The header band the backdrop frames, in this painter's coordinates.
  final Rect band;

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
    const glow = AppColors.brandDarkBg;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(center, glowRadius, [
          glow.withValues(alpha: glowOpacity),
          glow.withValues(alpha: 0),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant BrandBackdropBasePainter old) =>
      old.band != band;
}
