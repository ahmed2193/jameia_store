import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class HelpRow extends StatelessWidget {
  const HelpRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // a15c8b: padding=14dp vertical, 20dp horizontal — wider than standard 16dp.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r3),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryText),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                label,
                // KeeTa help-row label: Regular 14dp primaryText
                style: AppTextStyles.bodyLarge,
              ),
            ),
            const Icon(
              KeetaIcons.arrowRight,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
