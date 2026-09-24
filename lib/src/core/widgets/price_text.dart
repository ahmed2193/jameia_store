import 'package:flutter/material.dart';

import '../motion/motion_widgets.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Price display using the MT Digital Display digit font, with optional struck
/// original price — the Jameia campaign-price look (final price in red on discount).
///
/// Set [animate] to flip the amount when [price] changes (VIP-mode toggle,
/// free-delivery threshold, cart recalculation). Defaults OFF so list scrolling
/// doesn't trigger flip-storms — only opt in on surfaces where the price mutates
/// in place (shop SKU, checkout summary).
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.originalPrice = 0,
    this.size = 16,
    this.color,
    this.animate = false,
  });

  final double price;
  final double originalPrice;
  final double size;
  final Color? color;
  final bool animate;

  bool get _discounted => originalPrice > price && originalPrice > 0;

  @override
  Widget build(BuildContext context) {
    final main =
        color ?? (_discounted ? AppColors.finalPrice : AppColors.primaryText);
    final amount = Text(
      Formatters.amount(price),
      style: AppTextStyles.digits(
        size,
        weight: AppTextStyles.bold,
      ).copyWith(color: main),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          Formatters.currency,
          style: AppTextStyles.captionLarge.copyWith(color: main),
        ),
        const SizedBox(width: AppSpacing.s2),
        if (animate) FlipValue(flipKey: price, child: amount) else amount,
        if (_discounted) ...[
          const SizedBox(width: AppSpacing.s4),
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
