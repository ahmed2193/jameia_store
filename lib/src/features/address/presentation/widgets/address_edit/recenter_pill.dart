import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// White "Locate me" recenter pill.
class RecenterPill extends StatelessWidget {
  const RecenterPill({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 2,
      shadowColor: AppColors.overlayDivider,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                JameiaIcons.location,
                size: 18,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s6),
              Text(
                'map.recenter'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
