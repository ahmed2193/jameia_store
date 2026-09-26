import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';

/// The round white "+" on a listing card's picture (or the options glyph for
/// a product whose size must be chosen first), floating on its own shadow
/// with no outline. Sinks under the finger.
class ShelfAddButton extends StatelessWidget {
  const ShelfAddButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  static const double size = AppSize.s40;
  static const double _glyph = AppSize.s24;
  static const double _pressedScale = 0.9;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        pressedScale: _pressedScale,
        // The tile sends its own click with the add.
        haptic: null,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: Icon(icon, size: _glyph, color: AppColors.primary),
        ),
      ),
    );
  }
}
