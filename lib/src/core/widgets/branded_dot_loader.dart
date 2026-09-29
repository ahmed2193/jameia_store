import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import 'branded_dot_painter.dart';

/// The Hero loader dots ([BrandedDotPainter]) on a loop of
/// [AppMotion.loaderOrbit]: one controller that repaints without a rebuild,
/// cheap enough for a button or a list row. [size] is the width; the box is
/// half as tall. On a light surface the defaults (the bag's green, the cape's
/// amber) read best; on a brand fill use [BrandedLoader.inline].
///
/// Reduced motion (iOS "Reduce Motion") → the orbit is replaced by a slow
/// opacity breathe of the two dots side by side
/// ([BrandedDotPainter.breatheOf], [AppMotion.breathe] each way), so the
/// loader still says "working". Motion off (`disableAnimations`) → the two
/// dots still, no ticker.
class BrandedDotLoader extends StatefulWidget {
  const BrandedDotLoader({
    super.key,
    required this.size,
    this.color = AppColors.primary,
    this.trailColor = AppColors.proAmber,
  });

  final double size;

  /// The lead dot.
  final Color color;

  /// The dot circling it.
  final Color trailColor;

  @override
  State<BrandedDotLoader> createState() => _BrandedDotLoaderState();
}

class _BrandedDotLoaderState extends State<BrandedDotLoader>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.loaderOrbit,
  );

  /// Runs only under reduced motion (not off): the breathe's clock.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AppMotion.breathe,
    value: 1,
  );
  late final Animation<double> _opacity = BrandedDotPainter.breatheOf(_breath);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read per dependency change: an OS toggle (or a MediaQuery override)
    // switches between the orbit, the breathe and the still pose.
    if (MotionGuard.off(context)) {
      _rest(_loop);
      _rest(_breath, at: 1);
    } else if (MotionGuard.reduced(context)) {
      _rest(_loop);
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _rest(_breath, at: 1);
      if (!_loop.isAnimating) _loop.repeat();
    }
  }

  static void _rest(AnimationController controller, {double at = 0}) =>
      controller
        ..stop()
        ..value = at;

  @override
  void dispose() {
    _loop.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, widget.size * BrandedDotPainter.heightShare),
        painter: BrandedDotPainter(
          phase: _loop,
          lead: widget.color,
          trail: widget.trailColor,
          opacity: _opacity,
        ),
      ),
    );
  }
}
