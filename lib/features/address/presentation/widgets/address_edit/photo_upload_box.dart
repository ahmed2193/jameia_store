import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Pale-yellow photo-attach prompt (tap = a stub SnackBar).
class PhotoUploadBox extends StatelessWidget {
  const PhotoUploadBox({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('addr.photo_attached'.tr()))),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.brandLightBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const Icon(
              KeetaIcons.camera,
              size: 22,
              color: AppColors.primaryText,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                'addr.field.photo'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
