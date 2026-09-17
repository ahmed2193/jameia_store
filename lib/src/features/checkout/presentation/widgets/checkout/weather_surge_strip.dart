import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Subtle warn strip shown above the price summary.
class WeatherSurgeStrip extends StatelessWidget {
  const WeatherSurgeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    // Always-shown advisory strip → a one-shot entrance reveal (fade + small
    // slide) as the checkout list builds. Shares the [StaggerEntrance] primitive
    // (gated via MotionGuard), so the previous static [AnimatedSize] — which
    // never replayed over an unchanging child — is replaced by motion that
    // actually fires without inventing a surge-toggle state.
    return StaggerEntrance(
      index: 0,
      child: Container(
        width: double.infinity,
        color: AppColors.warnBg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s10,
        ),
        child: Row(
          children: [
            const Icon(JameiaIcons.alert, size: 16, color: AppColors.warn),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'checkout.weather_warning'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.warn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
