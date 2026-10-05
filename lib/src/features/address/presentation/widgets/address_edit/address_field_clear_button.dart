import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The ⊗ at the end of a focused address field that holds text: one tap
/// empties it. A 40 dp target around an 18 dp glyph.
class AddressFieldClearButton extends StatelessWidget {
  const AddressFieldClearButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  /// What a screen reader hears ("Clear Street").
  final String label;
  final VoidCallback onTap;

  static const double _target = AppSize.s40;
  static const double _glyph = AppSize.s18;

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
        child: const SizedBox.square(
          dimension: _target,
          child: Center(
            child: HeroIcon(
              HeroIcons.closeCircle,
              size: _glyph,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
