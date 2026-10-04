import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../domain/entities/order_invoice_summary.dart';
import 'invoice_discount_line.dart';

/// One row of the payment summary: the subtotal, a deduction (brand deep
/// green, minus), or the delivery fee ("Free" in green when nothing).
class InvoiceChargeLine extends StatelessWidget {
  const InvoiceChargeLine({super.key, required this.charge});

  static const TextStyle _freeStyle = TextStyle(color: AppColors.brandDeep);

  final InvoiceCharge charge;

  String get _label =>
      charge.kind.labelKey.tr(namedArgs: {'code': charge.couponCode});

  @override
  Widget build(BuildContext context) {
    if (charge.isDeduction) {
      return InvoiceDiscountLine(label: _label, kd: charge.kd);
    }
    return HeroSummaryLine(
      label: _label,
      value: charge.isFree
          ? Text('orders.free'.tr(), style: _freeStyle)
          : HeroMoneyText(kd: charge.kd),
    );
  }
}
