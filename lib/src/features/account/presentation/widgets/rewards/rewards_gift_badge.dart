import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Amber → orange disc with a white gift that bobs gently ([FloatLoop]; still
/// under reduced motion) — the badge of the "Redeem your points" tile.
class RewardsGiftBadge extends StatelessWidget {
  const RewardsGiftBadge({super.key});

  static const double _diameter = AppSize.s44;
  static const double _floatAmplitude = AppSpacing.s3;
  static const List<Color> _gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kJameiaPillPin,
  ];

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: FloatLoop(
        amplitude: _floatAmplitude,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: _gradient,
            ),
          ),
          child: SizedBox.square(
            dimension: _diameter,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: AppSize.s22,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
