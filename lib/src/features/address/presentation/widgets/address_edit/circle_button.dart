import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

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
      elevation: 2,
      shadowColor: AppColors.overlayDivider,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
