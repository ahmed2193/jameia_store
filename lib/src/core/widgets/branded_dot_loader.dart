import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'branded_dot_painter.dart';

/// Three-dot pulse painted with a single [AnimationController] — cheap enough to
/// sit inside a button. Each dot scales/fades on a staggered phase.
class BrandedDotLoader extends StatefulWidget {
  const BrandedDotLoader({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<BrandedDotLoader> createState() => _BrandedDotLoaderState();
}

class _BrandedDotLoaderState extends State<BrandedDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.lottieDotLoader,
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.disableAnimations) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) {
      return CustomPaint(
        size: Size(widget.size, widget.size * 0.34),
        painter: BrandedDotPainter(0, widget.color, animate: false),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size(widget.size, widget.size * 0.34),
          painter: BrandedDotPainter(_c.value, widget.color),
        ),
      ),
    );
  }
}
