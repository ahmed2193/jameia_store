import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';

class RecenterButton extends StatelessWidget {
  const RecenterButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.medium,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          JameiaAssets.navigationIcon,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            JameiaIcons.location,
            size: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
