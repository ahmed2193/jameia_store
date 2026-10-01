import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// White circular leading button used in the address-edit top bar.
class CircleButton extends StatelessWidget {
  const CircleButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: AppSize.s2,
      shadowColor: AppColors.overlayDivider,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: AppSize.s40,
          height: AppSize.s40,
          child: HeroIcon(
            icon,
            size: AppSize.s20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
