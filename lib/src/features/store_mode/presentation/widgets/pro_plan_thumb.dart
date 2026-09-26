import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';

/// The dark selection pill under the plan tabs: glides to [start] / [width]
/// (the selected tab's slot) whenever the selection moves. A direct child of
/// the tabs' `Stack`; directional, so it mirrors in RTL.
class ProPlanThumb extends StatelessWidget {
  const ProPlanThumb({super.key, required this.start, required this.width});

  final double start;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositionedDirectional(
      duration: MotionGuard.duration(context, AppMotion.page),
      curve: AppMotion.emphasizedDecelerate,
      start: start,
      width: width,
      top: 0,
      bottom: 0,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryText,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          boxShadow: AppShadows.medium,
        ),
      ),
    );
  }
}
