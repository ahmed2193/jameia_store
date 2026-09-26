import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// The light band a [sweep] (0 → 1) carries across its box, start edge to
/// end edge (mirrored in RTL): a tilted white gradient stripe, translated at
/// paint time only, clipped to the box (or [borderRadius]). Driven by
/// `LightSweep`.
class LightSweepBand extends StatelessWidget {
  const LightSweepBand({
    super.key,
    required this.sweep,
    this.peakAlpha = defaultPeakAlpha,
    this.borderRadius,
  });

  static const double defaultPeakAlpha = 0.28;

  /// Where the stripe fades in / peaks / fades out across the box.
  static const List<double> _stops = [0.38, 0.5, 0.62];

  /// Tilt of the stripe (a fraction of the height per half width).
  static const double _tilt = 0.6;

  final Animation<double> sweep;
  final double peakAlpha;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final clear = AppColors.white.withValues(alpha: 0);
    final band = IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: sweep,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -_tilt),
                end: const Alignment(1, _tilt),
                stops: _stops,
                colors: [
                  clear,
                  AppColors.white.withValues(alpha: peakAlpha),
                  clear,
                ],
              ),
            ),
          ),
          // -1 = the band parked off the start edge, 1 = off the end edge.
          builder: (context, child) => FractionalTranslation(
            translation: Offset((sweep.value * 2 - 1) * direction, 0),
            child: child,
          ),
        ),
      ),
    );
    final radius = borderRadius;
    return radius == null
        ? ClipRect(child: band)
        : ClipRRect(borderRadius: radius, child: band);
  }
}
