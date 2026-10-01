import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// A round outlined icon button (back, search, share) for headers that sit
/// on a picture or a tinted band. Sinks under the finger and reads as one
/// labelled button. Directional glyphs (back) flip with the reading
/// direction.
class RoundOutlinedButton extends StatelessWidget {
  const RoundOutlinedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fill = AppColors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// The disc's fill (white by default; a translucent white over a picture).
  final Color fill;

  static const double size = AppSize.s44;
  static const double _glyph = AppSize.s22;

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
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: HeroIcon(icon, size: _glyph, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
