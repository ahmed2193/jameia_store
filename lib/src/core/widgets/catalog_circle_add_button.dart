import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../design/hero_icons.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// The floating round button on a product card: "+" for a product one tap can
/// add, the Hero options glyph ([options], three jar sizes —
/// [HeroIcons.options]) for a product that needs a choice first
/// (variants). It
/// sinks under the finger ([PressScale] at the small-button depth); the host
/// fires the haptic with the add.
class CatalogCircleAddButton extends StatelessWidget {
  const CatalogCircleAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = HeroIcons.plus,
    this.options = false,
  });

  /// Accessibility label.
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  /// Draws the options glyph instead of [icon].
  final bool options;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScaleSmall,
        child: Container(
          width: AppSize.s34,
          height: AppSize.s34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: options
              ? const HeroIcon(
                  HeroIcons.options,
                  size: AppSize.s20,
                  color: AppColors.brandForeground,
                )
              : HeroIcon(
                  icon,
                  size: AppSize.s20,
                  color: AppColors.brandForeground,
                ),
        ),
      ),
    );
  }
}
