import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class DeliveryCodeDialog extends StatelessWidget {
  const DeliveryCodeDialog({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3), // 16dp popup
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR-ish placeholder square (bordered box w/ the delivery-code
                // icon) — stands in for the real scannable code.
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r5),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    KeetaAssets.deliveryCodeIcon,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      KeetaIcons.confirmReceipt,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'map.delivery_code'.tr(),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'map.delivery_code_explain'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                // Big code display.
                Text(
                  code,
                  style: AppTextStyles.headingLarge.copyWith(
                    fontWeight: AppTextStyles.bold,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.s14,
                      ),
                    ),
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(
                      'orders.got_it'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
