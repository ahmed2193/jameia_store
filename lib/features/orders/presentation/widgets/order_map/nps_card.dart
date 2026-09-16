import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

// ── NPS / rate-your-experience card ──────────────────────────────────────────

class NpsCard extends StatelessWidget {
  const NpsCard({super.key, required this.onRate, required this.onClose});
  final ValueChanged<int> onRate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        boxShadow: AppShadows.high,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'map.rate_experience'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  KeetaIcons.closeSmall,
                  size: 16,
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => onRate(i),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      KeetaIcons.star,
                      size: 32,
                      color: AppColors.warn,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
