import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// The close button under a centred popup: a white ring with a white × on
/// the scrim, inside a 48 dp touch target.
class HomePopupCloseRing extends StatelessWidget {
  const HomePopupCloseRing({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _target = AppSize.s48;
  static const double _ring = AppSize.s36;
  static const double _stroke = AppSize.s2;
  static const double _glyph = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'home.welcome_popup_close'.tr(),
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScaleSmall,
        child: SizedBox.square(
          dimension: _target,
          child: Center(
            child: Container(
              width: _ring,
              height: _ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: _stroke),
              ),
              child: const HeroIcon(
                HeroIcons.close,
                size: _glyph,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
