import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../../../core/widgets/thin_divider.dart';
import 'invoice_discount_line.dart';
import 'invoice_loyalty_note.dart';
import 'invoice_section.dart';

/// "Payment summary": the order's own totals — every figure comes from the
/// server, nothing is recomputed here. Deductions and "Free" read in brand
/// deep green; money is one left-to-right run.
class InvoiceTotals extends StatelessWidget {
  const InvoiceTotals({super.key, required this.order});

  static const TextStyle _freeStyle = TextStyle(color: AppColors.brandDeep);

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final coupon = order.coupon;
    final loyalty = order.loyalty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InvoiceSection(
          title: 'orders.summary_title'.tr(),
          children: [
            HeroSummaryLine(
              label: 'orders.subtotal'.tr(),
              value: HeroMoneyText(kd: order.subtotalKd),
            ),
            if (order.offerDiscountFils > 0)
              InvoiceDiscountLine(
                label: 'orders.offer_discount'.tr(),
                kd: order.offerDiscountKd,
              ),
            if (order.proDiscountFils > 0)
              InvoiceDiscountLine(
                label: 'orders.pro_discount'.tr(),
                kd: order.proDiscountKd,
              ),
            if (coupon != null)
              InvoiceDiscountLine(
                label: 'orders.coupon_discount'.tr(
                  namedArgs: {'code': coupon.code},
                ),
                kd: coupon.discountKd,
              ),
            if (loyalty.discountFils > 0)
              InvoiceDiscountLine(
                label: 'orders.loyalty_discount'.tr(),
                kd: loyalty.discountKd,
              ),
            HeroSummaryLine(
              label: 'orders.delivery_fee'.tr(),
              value: order.deliveryFeeFils <= 0
                  ? Text('orders.free'.tr(), style: _freeStyle)
                  : HeroMoneyText(kd: order.deliveryFeeKd),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
              child: ThinDivider(),
            ),
            HeroSummaryLine(
              label: 'orders.total'.tr(),
              emphasized: true,
              value: HeroMoneyText(kd: order.totalKd),
            ),
          ],
        ),
        if (loyalty.pointsEarned > 0)
          InvoiceLoyaltyNote(points: loyalty.pointsEarned),
      ],
    );
  }
}
