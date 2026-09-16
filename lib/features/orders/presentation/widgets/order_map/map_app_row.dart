import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

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
            const Icon(KeetaIcons.location, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(
              KeetaIcons.arrowRightSmall,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
