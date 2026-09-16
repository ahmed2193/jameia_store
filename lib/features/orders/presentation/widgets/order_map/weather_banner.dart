import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

// ── Bad-weather banner ───────────────────────────────────────────────────────

class WeatherBanner extends StatelessWidget {
  const WeatherBanner({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s12,
        end: AppSpacing.s8,
        top: AppSpacing.s8,
        bottom: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, size: 18, color: AppColors.warn),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'map.weather_delay'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                KeetaIcons.closeSmall,
                size: 16,
                color: AppColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
