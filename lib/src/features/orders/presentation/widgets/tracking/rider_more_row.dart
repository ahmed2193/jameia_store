import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class RiderMoreRow extends StatelessWidget {
  const RiderMoreRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primaryText;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
