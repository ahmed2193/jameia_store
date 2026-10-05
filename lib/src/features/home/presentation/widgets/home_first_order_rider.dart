import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/motion/ambient_loop.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_svg_glyph.dart';
import 'home_speed_lines_painter.dart';

/// The Hero rider of the first-order free-delivery bar (and its dialog),
/// [width] wide, with the speed lines streaming out behind it.
///
/// It drives in once from the start edge as it mounts ([AppMotion.slow],
/// emphasized decelerate) — the lines fade in behind it — then rides: two
/// little hops a lap over a bumpy road, a lean into each, the lines
/// streaming back. The ride is an [AmbientLoop]: on screen only, within the
/// ambient budget each time it comes back on screen, still under reduced
/// motion or with a screen reader (the rider then simply stands in place).
class HomeFirstOrderRider extends StatefulWidget {
  const HomeFirstOrderRider({
    super.key,
    required this.width,
    this.lineColor = AppColors.white,
  });

  /// The rider's own width; the lines take [trailShare] of it more on the
  /// start side.
  final double width;
  final Color lineColor;

  /// The drawing is 64 × 44.
  static const double aspectRatio = 64 / 44;

  /// The speed lines' room behind the rider, as a share of [width].
  static const double trailShare = 0.4;

  /// How much of the lines' room tucks under the rider's box.
  static const double _tuck = 0.5;

  /// One lap of the ride: two hops. A one-off rhythm (a quick scooter
  /// bounce), between [AppMotion.slow] and [AppMotion.shimmer].
  static const Duration _lap = Duration(milliseconds: 1000);
  static const int _hopsPerLap = 2;

  /// A hop's height and lean, as shares of [width] / radians.
  static const double _hop = 0.03;
  static const double _lean = 0.035;

  /// How far behind its place the rider starts its drive in (× [width]).
  static const double _driveFrom = 0.9;

  /// The lines grow out of the rider's back over the second half of it.
  static const Interval _linesIn = Interval(0.5, 1);
  static const Interval _riderIn = Interval(0, 0.6);

  @override
  State<HomeFirstOrderRider> createState() => _HomeFirstOrderRiderState();
}

class _HomeFirstOrderRiderState extends State<HomeFirstOrderRider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final CurvedAnimation _drive = CurvedAnimation(
    parent: _arrive,
    curve: AppMotion.emphasizedDecelerate,
  );
  late final CurvedAnimation _riderFade = CurvedAnimation(
    parent: _arrive,
    curve: HomeFirstOrderRider._riderIn,
  );
  late final CurvedAnimation _linesFade = CurvedAnimation(
    parent: _arrive,
    curve: HomeFirstOrderRider._linesIn,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionGuard.reduced(context)) {
      _arrive.value = 1;
    } else {
      _arrive.forward();
    }
  }

  @override
  void dispose() {
    _drive.dispose();
    _riderFade.dispose();
    _linesFade.dispose();
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width / HomeFirstOrderRider.aspectRatio;
    final trail = width * HomeFirstOrderRider.trailShare;
    final direction = Directionality.of(context);
    final forward = direction == TextDirection.rtl ? -1.0 : 1.0;
    return SizedBox(
      width: width + trail,
      height: height,
      child: RepaintBoundary(
        child: AmbientLoop(
          period: HomeFirstOrderRider._lap,
          child: HeroSvgGlyph.art(
            HeroAssets.promoRider,
            size: width,
            height: height,
            matchTextDirection: true,
          ),
          builder: (context, loop, rider) => Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: trail + width * HomeFirstOrderRider._tuck,
                child: FadeTransition(
                  opacity: _linesFade,
                  child: CustomPaint(
                    painter: HomeSpeedLinesPainter(
                      progress: loop,
                      color: widget.lineColor,
                      textDirection: direction,
                      strokeWidth: AppSize.s2,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                width: width,
                child: FadeTransition(
                  opacity: _riderFade,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([loop, _drive]),
                    child: rider,
                    builder: (context, rider) {
                      final wave = math.sin(
                        loop.value * math.pi * HomeFirstOrderRider._hopsPerLap,
                      );
                      final behind =
                          (1 - _drive.value) * HomeFirstOrderRider._driveFrom;
                      return Transform.translate(
                        offset: Offset(
                          -behind * width * forward,
                          -wave.abs() * width * HomeFirstOrderRider._hop,
                        ),
                        child: Transform.rotate(
                          angle: -wave * HomeFirstOrderRider._lean * forward,
                          alignment: Alignment.bottomCenter,
                          child: rider,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
