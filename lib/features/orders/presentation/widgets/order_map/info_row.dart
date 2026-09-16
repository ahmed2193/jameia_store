import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Compact label/value row used for the drop-off and platform-fee lines.
/// When [onTap] is non-null a chevron is shown and the row is tappable.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.tertiaryText),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.s4),
          const Icon(
            KeetaIcons.arrowRightSmall,
            size: 16,
            color: AppColors.tertiaryText,
          ),
        ],
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}
