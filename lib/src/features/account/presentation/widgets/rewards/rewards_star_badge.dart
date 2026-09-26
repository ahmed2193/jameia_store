import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// The points star at the corner of the balance card: a white disc with the
/// star and a soft breathing glow behind it ([GlowPulse]; a still glow under
/// reduced motion). Decorative only.
class RewardsStarBadge extends StatelessWidget {
  const RewardsStarBadge({super.key});

  static const double _glowDiameter = AppSize.s80;
  static const double _discDiameter = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox.square(
        dimension: _glowDiameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GlowPulse(color: AppColors.white, diameter: _glowDiameter),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: _discDiameter,
                child: Icon(
                  Icons.stars_rounded,
                  size: AppSize.s32,
                  color: AppColors.accent3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
