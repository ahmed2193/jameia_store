import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// One perk of the Pro programme: icon + text on the dark hero card.
class ProPerkRow extends StatelessWidget {
  const ProPerkRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
      child: Row(
        children: [
          Icon(icon, size: AppSize.s20, color: AppColors.accent4),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
