import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class MapAppRow extends StatelessWidget {
  const MapAppRow({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            const Icon(
              JameiaIcons.location,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(
              JameiaIcons.arrowRightSmall,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
