import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';

class CircleFab extends StatelessWidget {
  const CircleFab({super.key, required this.icon, required this.onTap});
  final IconData icon;
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
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
