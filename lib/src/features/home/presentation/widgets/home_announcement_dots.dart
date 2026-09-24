import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';

/// How far through the announcements the strip is: the dot of the line on
/// screen stretches into a bar, the others stay dots. It animates on its own,
/// so the strip never has to re-run its own transition to move it.
class HomeAnnouncementDots extends StatelessWidget {
  const HomeAnnouncementDots({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  static const double _dot = AppSize.s4;
  static const double _activeWidth = AppSize.s10;
  static const double _idleAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var dot = 0; dot < count; dot++)
          AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: AppMotion.signature,
            width: dot == index ? _activeWidth : _dot,
            height: _dot,
            margin: EdgeInsetsDirectional.only(
              start: dot == 0 ? 0 : AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: dot == index
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: _idleAlpha),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
