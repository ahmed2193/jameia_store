import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';

/// Round outlined back button for the white title bars (Rewards, coupons):
/// it dips on touch ([PressScale] around the button, which keeps its own tap
/// and ripple) and pops the current route. `Icons.arrow_back` mirrors under
/// RTL on its own.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key});

  static const double diameter = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: AppMotion.pressedScaleSmall,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(diameter),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.divider),
        ),
        icon: const Icon(Icons.arrow_back, size: AppSize.s22),
      ),
    );
  }
}
