import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';

class MapBackButton extends StatelessWidget {
  const MapBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.medium,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: Icon(JameiaIcons.back, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
