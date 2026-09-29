import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// A round outlined button of the catalogue app bar (back, search). Sinks
/// under the finger.
class CatalogRoundButton extends StatelessWidget {
  const CatalogRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          // Directional glyphs (back) flip with the reading direction.
          child: Icon(icon, size: _glyph, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
