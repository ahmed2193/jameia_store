import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../motion/motion.dart';
import '../../config/theme/app_colors.dart';

/// Shimmer SKELETON wrapper. Feed a static stand-in layout that mirrors the real
/// content; while [loading] is true it renders bones with Jameia's shimmer sweep
/// ([AppMotion.shimmer], ~1.1s). Reduced-motion → a solid (non-sweeping) bone so
/// the screen still reads as "loading" without movement.
class Skeletonized extends StatelessWidget {
  const Skeletonized({super.key, required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    return Skeletonizer(
      enabled: loading,
      effect: reduced
          ? SolidColorEffect(color: AppColors.divider)
          : ShimmerEffect(
              baseColor: AppColors.divider,
              highlightColor: AppColors.smallBackground,
              duration: AppMotion.shimmer,
            ),
      child: child,
    );
  }
}
