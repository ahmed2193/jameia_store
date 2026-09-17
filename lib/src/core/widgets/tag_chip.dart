import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Colored promo / tag chip (free delivery, % off, etc.).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.bg = AppColors.freeDeliveryBg,
    this.fg = AppColors.freeDelivery,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.s11, color: fg),
            const SizedBox(width: AppSpacing.s2),
          ],
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: fg,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ],
      ),
    );
  }
}
