import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/widgets/jameia_money_text.dart';

/// A cart row's unit price — deep green on a deal — and the struck "was"
/// price after it. When the pair does not fit the row (a narrow phone, large
/// text), the struck price wraps to its own line instead of overflowing.
class CartLinePrice extends StatelessWidget {
  const CartLinePrice({super.key, required this.line});

  final CartLineEntity line;

  @override
  Widget build(BuildContext context) {
    final deal = line.hasDiscount;
    return Wrap(
      spacing: AppSpacing.s6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        JameiaMoneyText(
          kd: line.unitPriceKd,
          style: AppTextStyles.label,
          color: deal ? AppColors.brandDeep : AppColors.primaryText,
        ),
        if (deal)
          JameiaMoneyText(
            kd: line.compareAtKd,
            style: AppTextStyles.meta,
            strike: true,
          ),
      ],
    );
  }
}
