import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// The end of the "Coupons & offers" page: how offers work ("Offers apply
/// by themselves once your basket qualifies.") and "That's everything for
/// now" — or, with no offer at all, "No offers are running right now".
class CheckoutVouchersFooter extends StatelessWidget {
  const CheckoutVouchersFooter({super.key, required this.hasOffers});

  final bool hasOffers;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.s24,
        bottom: AppSpacing.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasOffers) ...[
            Text(
              'checkout.offers_auto_note'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          Text(
            hasOffers
                ? 'checkout.vouchers_end'.tr()
                : 'checkout.vouchers_empty'.tr(),
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
      ),
    );
  }
}
