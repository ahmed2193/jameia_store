import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';

/// The order's own totals — every figure comes from the server, nothing is
/// recomputed here.
class InvoiceTotals extends StatelessWidget {
  const InvoiceTotals({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final coupon = order.coupon;
    final loyalty = order.loyalty;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'orders.subtotal'.tr(),
            value: Formatters.price(order.subtotalKd),
          ),
          if (order.offerDiscountFils > 0)
            SummaryRow(
              label: 'orders.offer_discount'.tr(),
              value: '- ${Formatters.price(order.offerDiscountKd)}',
              valueColor: AppColors.success,
            ),
          if (order.proDiscountFils > 0)
            SummaryRow(
              label: 'orders.pro_discount'.tr(),
              value: '- ${Formatters.price(order.proDiscountKd)}',
              valueColor: AppColors.success,
            ),
          if (coupon != null)
            SummaryRow(
              label: 'orders.coupon_discount'.tr(
                namedArgs: {'code': coupon.code},
              ),
              value: '- ${Formatters.price(coupon.discountKd)}',
              valueColor: AppColors.success,
            ),
          if (loyalty.discountFils > 0)
            SummaryRow(
              label: 'orders.loyalty_discount'.tr(),
              value: '- ${Formatters.price(loyalty.discountKd)}',
              valueColor: AppColors.success,
            ),
          SummaryRow(
            label: 'orders.delivery_fee'.tr(),
            value: order.deliveryFeeFils <= 0
                ? 'orders.free'.tr()
                : Formatters.price(order.deliveryFeeKd),
            valueColor: order.deliveryFeeFils <= 0
                ? AppColors.freeDelivery
                : null,
          ),
          SummaryRow(
            label: 'orders.total'.tr(),
            value: Formatters.price(order.totalKd),
            emphasized: true,
          ),
          if (loyalty.pointsEarned > 0)
            Text(
              'orders.loyalty_earned'.tr(
                namedArgs: {'points': '${loyalty.pointsEarned}'},
              ),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}
