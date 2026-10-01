import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';
import 'hero_icon.dart';

/// An icon action at the end of a [HeroTitleBar] (search, history, mark all
/// read, call): the ink glyph in a 48 dp target with no fill — the round
/// outline belongs to the back button alone — its [tooltip] read out, and
/// the small dip of a round control. Disabled ([onPressed] null): grey.
class HeroBarAction extends StatelessWidget {
  const HeroBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onPressed != null,
      pressedScale: AppMotion.pressedScaleSmall,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(AppSize.s48),
          foregroundColor: AppColors.primaryText,
          disabledForegroundColor: AppColors.disabledText,
        ),
        icon: HeroIcon(icon, size: AppSize.s24),
      ),
    );
  }
}
