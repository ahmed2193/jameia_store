import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// One round − / + / delete button of [CatalogPillStepper]. It sinks under
/// the finger ([PressScale] at the small-button depth); the host fires the
/// haptic with the cart change. A new [icon] (minus ↔ bin) cross-fades in.
class CatalogStepButton extends StatelessWidget {
  const CatalogStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Accessibility label.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScaleSmall,
        child: Container(
          width: AppSize.s28,
          height: AppSize.s28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: MotionGuard.duration(context, AppMotion.fast),
            child: HeroIcon(
              icon,
              key: ValueKey<IconData>(icon),
              size: AppSize.s16,
              color: AppColors.brandForeground,
            ),
          ),
        ),
      ),
    );
  }
}
