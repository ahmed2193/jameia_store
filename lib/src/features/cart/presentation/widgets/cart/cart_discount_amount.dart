import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/widgets/jameia_money_text.dart';

/// A saving as the cart shows it everywhere — "- KD 0.500" in deep green —
/// under the coupon and the points, and in the payment summary. [style]
/// defaults to the surrounding text style.
class CartDiscountAmount extends StatelessWidget {
  const CartDiscountAmount({super.key, required this.kd, this.style});

  final double kd;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return JameiaMoneyText(
      kd: kd,
      negative: true,
      color: AppColors.brandDeep,
      style: style,
    );
  }
}
