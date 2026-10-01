import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A milestone of the deals track: a deep-green disc with a white tick once
/// [reached], an outlined ring before.
class CartDealNode extends StatelessWidget {
  const CartDealNode({super.key, required this.reached});

  final bool reached;

  static const double size = AppSize.s22;
  static const double _ring = AppSize.s2;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? AppColors.brandDeep : AppColors.white,
        border: Border.all(color: AppColors.brandDeep, width: _ring),
      ),
      child: reached
          ? const HeroIcon(
              HeroIcons.check,
              size: AppSize.s14,
              color: AppColors.white,
            )
          : null,
    );
  }
}
