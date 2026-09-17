import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class RiderAction extends StatelessWidget {
  const RiderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });
  final IconData icon;
  final VoidCallback onTap;

  /// Unread count rendered as a small red badge (0 = hidden).
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.black),
          ),
          if (badgeCount > 0)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: AppTextStyles.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
