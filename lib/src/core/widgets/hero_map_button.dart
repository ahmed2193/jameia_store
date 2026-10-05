import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/motion.dart';
import '../motion/press_scale.dart';
import '../responsive/app_size.dart';
import 'app_loader.dart';
import 'hero_icon.dart';

/// The round white button that floats over every Hero map (back, "find
/// me"): one size, one lift, so the address picker and the live rider map
/// carry the same chrome. It dips on touch; [busy] swaps the glyph for the
/// Hero dots and takes no tap. A screen reader hears [tooltip].
class HeroMapButton extends StatelessWidget {
  const HeroMapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  static const double diameter = AppSize.s48;
  static const double _glyph = AppSize.s22;
  static const double _dots = AppSize.s24;

  @override
  Widget build(BuildContext context) {
    final onTap = busy ? null : onPressed;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScaleSmall,
        child: Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: busy
              ? const AppLoader.inline(size: _dots)
              : HeroIcon(icon, size: _glyph, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
