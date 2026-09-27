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
/// Reduced motion → the two dots side by side, still (no ticker).
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.loaderOrbit,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion (the OS flag or a MediaQuery override) → no ticker, the
    // resting pose.
    if (MotionGuard.reduced(context)) {
      _loop
        ..stop()
        ..value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
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
        ),
      ),
    );
  }
}
