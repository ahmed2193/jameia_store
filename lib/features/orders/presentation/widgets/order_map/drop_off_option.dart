import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class DropOffOption extends StatelessWidget {
  const DropOffOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: selected ? AppColors.smallBackground : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryText),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                KeetaIcons.confirm,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
