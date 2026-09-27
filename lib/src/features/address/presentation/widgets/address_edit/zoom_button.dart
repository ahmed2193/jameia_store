import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// White circular zoom +/- control (matches the recenter pill / FAB styling).
class ZoomButton extends StatelessWidget {
  const ZoomButton({super.key, required this.icon, required this.onTap});
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
          child: Icon(icon, size: AppSize.s22, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
