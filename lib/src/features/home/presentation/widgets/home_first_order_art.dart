import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/float_loop.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_close_button.dart';
import 'home_first_order_rider.dart';

/// The head of the first-order dialog: the bar's brand-deep green, the Hero
/// rider riding in large over a breathing glow, and the ✕ ([onClose]) in
/// the end corner.
class HomeFirstOrderArt extends StatelessWidget {
  const HomeFirstOrderArt({super.key, required this.onClose});

  final VoidCallback onClose;

  static const double _height = AppSize.s150;
  static const double _rider = AppSize.s120;
  static const double _glow = AppSize.s200;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ColoredBox(
        color: AppColors.brandDeep,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const FloatLoop.glow(color: AppColors.primary, diameter: _glow),
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.s16),
              child: HomeFirstOrderRider(width: _rider),
            ),
            PositionedDirectional(
              top: AppSpacing.s4,
              end: AppSpacing.s4,
              child: HeroCloseButton(
                onPressed: onClose,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
