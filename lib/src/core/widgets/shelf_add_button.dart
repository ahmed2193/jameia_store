import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../design/hero_assets.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import 'hero_svg_glyph.dart';

/// The round white "+" on a listing card's picture (or, with [options], the
/// Hero "choose options" glyph — three jar sizes, [HeroAssets.productOptions]
/// — for a product whose size must be chosen first), floating on its own
/// shadow with no outline. Sinks under the finger.
class ShelfAddButton extends StatelessWidget {
  const ShelfAddButton({
    super.key,
    required this.label,
    this.icon = Icons.add_rounded,
    this.options = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;

  /// Draws the options glyph instead of [icon].
  final bool options;
  final VoidCallback onTap;

  static const double size = AppSize.s40;
  static const double _glyph = AppSize.s24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScaleSmall,
        // The tile sends its own click with the add.
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: options
              ? const HeroSvgGlyph.mono(
                  HeroAssets.productOptions,
                  size: _glyph,
                  color: AppColors.primaryDark,
                )
              : Icon(icon, size: _glyph, color: AppColors.primary),
        ),
      ),
    );
  }
}
