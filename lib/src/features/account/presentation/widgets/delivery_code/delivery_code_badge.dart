import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Warm amber → orange disc with the rider glyph, heading the code card.
class DeliveryCodeBadge extends StatelessWidget {
  const DeliveryCodeBadge({super.key});

  static const List<Color> _gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kHeroPillPin,
  ];

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: AppSize.s44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: _gradient,
          ),
        ),
        child: HeroIcon(
          HeroIcons.delivery,
          size: AppSize.s22,
          color: AppColors.white,
        ),
      ),
    );
  }
}
