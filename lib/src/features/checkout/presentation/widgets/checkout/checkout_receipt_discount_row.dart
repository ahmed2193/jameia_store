import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import 'checkout_receipt_row.dart';

/// A receipt line that takes money off (offers, coupon, points): shown only
/// while [visible] (it opens and closes in place), its amount negative in
/// the final-price colour.
class CheckoutReceiptDiscountRow extends StatelessWidget {
  const CheckoutReceiptDiscountRow({
    super.key,
    required this.visible,
    required this.label,
    required this.kd,
  });

  final bool visible;
  final String label;
  final double kd;

  @override
  Widget build(BuildContext context) {
    return CollapseReveal(
      visible: visible,
      child: CheckoutReceiptRow(
        label: label,
        value: JameiaMoneyText(
          kd: kd,
          negative: true,
          color: AppColors.finalPrice,
        ),
      ),
    );
  }
}
