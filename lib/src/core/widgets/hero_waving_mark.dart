import 'package:flutter/widgets.dart';

import '../design/hero_mark_painting.dart';
import '../motion/idle_loop.dart';
import 'hero_waving_mark_painter.dart';

/// The Hero mark on its own, [size] dp square, at ease: its cape ripples and
/// the bag bobs while it is on screen (still under reduced motion). For an
/// offer card or an invitation that speaks for the brand. Decorative.
class HeroWavingMark extends StatelessWidget {
  const HeroWavingMark({
    super.key,
    required this.size,
    this.colors = HeroMarkColors.onWhite,
  });

  final double size;
  final HeroMarkColors colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: IdleLoop(
          builder: (context, loop) => CustomPaint(
            size: Size.square(size),
            painter: HeroWavingMarkPainter(idle: loop, colors: colors),
          ),
        ),
      ),
    );
  }
}
