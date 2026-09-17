import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entities/coupon_entity.dart';

/// Price breakdown: subtotal / delivery / tip / total.
/// Jameia price label rows from g48e14: padding 12dp 0dp, border-top 0.5dp.
class PriceSummary extends StatelessWidget {
  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.tip,
    required this.freeDelivery,
    this.discount = 0,
    this.coupon,
  });
  final double subtotal;
  final double deliveryFee;
  final double tip;
  final bool freeDelivery;
  final double discount;
  final CouponEntity? coupon;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const Spacer(),
          value,
        ],
      ),
    );

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          // Summary numbers recompute in place (tip/VIP/delivery changes) →
          // flip the amount with `animate: true`.
          row(
            'checkout.subtotal'.tr(),
            PriceText(price: subtotal, size: 14, animate: true),
          ),
          row(
            'checkout.delivery_fee'.tr(),
            freeDelivery
                ? Text(
                    'checkout.free'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.freeDelivery,
                    ),
                  )
                : PriceText(price: deliveryFee, size: 14, animate: true),
          ),
          if (tip > 0)
            row(
              'checkout.rider_tip'.tr(),
              PriceText(price: tip, size: 14, animate: true),
            ),
          if (discount > 0)
            row(
              'checkout.coupon_discount'.tr(),
              Text(
                '- ${Formatters.price(discount)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.freeDelivery,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          // Min-spend hint: a coupon is selected but the cart is below its gate.
          if (coupon != null && discount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'checkout.coupon_min_spend'.tr(
                        namedArgs: {
                          'amount': Formatters.price(coupon!.minSpend),
                        },
                      ),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const ThinDivider(),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Row(
              children: [
                Text(
                  'checkout.total'.tr(),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const Spacer(),
                PriceText(
                  price: (subtotal - discount + deliveryFee + tip).clamp(
                    0.0,
                    double.infinity,
                  ),
                  size: 18,
                  animate: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
