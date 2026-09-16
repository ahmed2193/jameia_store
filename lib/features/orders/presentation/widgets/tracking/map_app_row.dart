import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class MapAppRow extends StatelessWidget {
  const MapAppRow({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasize = true,
    this.center = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool emphasize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (emphasize) ...[
              const Icon(
                KeetaIcons.location,
                size: 20,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s12),
            ],
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: center ? AppColors.secondaryText : AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
