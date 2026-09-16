import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Out-of-service-area banner (RE `address_outofserviceareatoast`).
class NotServiceableBanner extends StatelessWidget {
  const NotServiceableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(KeetaIcons.location, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'addr.outside_area'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.error,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
