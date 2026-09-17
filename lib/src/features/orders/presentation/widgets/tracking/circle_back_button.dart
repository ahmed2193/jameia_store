import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';

class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayDivider,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: Icon(JameiaIcons.back, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}
