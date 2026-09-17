import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// Half-height modal sheet for the on-time delivery promise.
class OnTimePromiseSheet extends StatelessWidget {
  const OnTimePromiseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        top: topPadding > 0 ? topPadding : AppSpacing.s24,
        bottom: AppSpacing.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent2Light,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: const Icon(
                  JameiaIcons.deliveryTime,
                  size: 22,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                'checkout.ontime_title'.tr(),
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'checkout.ontime_body1'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'checkout.ontime_body2'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.promotionTagLightBg,
              borderRadius: BorderRadius.circular(AppRadius.r6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_num_outlined,
                  size: 18,
                  color: AppColors.accent3,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'checkout.ontime_coupon_note'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.promotionTagFgOnLight,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'checkout.got_it'.tr(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
