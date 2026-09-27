import 'package:flutter/material.dart';

import '../../../../../core/widgets/hero_summary_line.dart';
import 'cart_discount_amount.dart';

/// A discount in the cart's payment summary: "Coupon discount   - KD 0.500"
/// with the amount in deep green.
class CartDiscountLine extends StatelessWidget {
  const CartDiscountLine({super.key, required this.label, required this.kd});

  final String label;
  final double kd;

  @override
  Widget build(BuildContext context) {
    return HeroSummaryLine(
      label: label,
      value: CartDiscountAmount(kd: kd),
    );
  }
}
