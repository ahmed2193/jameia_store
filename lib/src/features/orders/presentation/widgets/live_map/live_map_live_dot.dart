import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/ambient_loop.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The "live" dot: brand green, a ring breathing out of it at the Hero
/// loader's pace while it is on screen — a few laps (the ambient budget),
/// then it rests; still under reduced motion.
class LiveMapLiveDot extends StatelessWidget {
  const LiveMapLiveDot({super.key});

  static const double _dot = AppSize.s8;
  static const double _ringScale = 2.6;

  @override
  Widget build(BuildContext context) {
    const dot = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(dimension: _dot),
    );
    return SizedBox.square(
      dimension: _dot * _ringScale,
      child: AmbientLoop(
        period: AppMotion.loaderOrbit,
        builder: (context, loop, child) => Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: ReverseAnimation(loop),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: _ringScale).animate(loop),
                child: child,
              ),
            ),
            dot,
          ],
        ),
        child: dot,
      ),
    );
  }
}
