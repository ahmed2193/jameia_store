import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Price display using the MT Digital Display digit font, with optional struck
/// original price — the KeeTa campaign-price look (final price in red on discount).
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.originalPrice = 0,
    this.size = 16,
    this.color,
  });

  final double price;
  final double originalPrice;
  final double size;
  final Color? color;

  bool get _discounted => originalPrice > price && originalPrice > 0;

  @override
  Widget build(BuildContext context) {
    final main = color ?? (_discounted ? AppColors.finalPrice : AppColors.primaryText);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(Formatters.currency,
            style: AppTextStyles.captionLarge.copyWith(color: main)),
        const SizedBox(width: 2),
        Text(
          Formatters.amount(price),
          style: AppTextStyles.digits(size, weight: AppTextStyles.bold)
              .copyWith(color: main),
        ),
        if (_discounted) ...[
          const SizedBox(width: 4),
          Text(
            Formatters.amount(originalPrice),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
