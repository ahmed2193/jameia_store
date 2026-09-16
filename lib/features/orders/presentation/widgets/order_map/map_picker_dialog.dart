import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/common.dart';
import 'map_app_row.dart';

// ── Map-app picker dialog ────────────────────────────────────────────────────

class MapPickerDialog extends StatelessWidget {
  const MapPickerDialog({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'map.open_in_maps'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            MapAppRow(
              label: 'map.google'.tr(),
              onTap: () => onPick('map.google'.tr()),
            ),
            const ThinDivider(),
            MapAppRow(
              label: 'map.apple'.tr(),
              onTap: () => onPick('map.apple'.tr()),
            ),
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              label: 'common.cancel'.tr(),
              color: AppColors.smallBackground,
              foreground: AppColors.primaryText,
              onPressed: () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    );
  }
}
