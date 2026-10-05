import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_icons.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// Round outlined back button for the white title bars (Rewards, coupons):
/// it dips on touch ([PressScale] around the button, which keeps its own tap
/// and ripple) and pops the current route — or does [onPressed] instead (a
/// page with steps of its own goes back a step). `HeroIcons.back` mirrors
/// under RTL on its own.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const double diameter = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: AppMotion.pressedScaleSmall,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => context.pop(),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(diameter),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.divider),
        ),
        icon: const HeroIcon(HeroIcons.back, size: AppSize.s22),
      ),
    );
  }
}
