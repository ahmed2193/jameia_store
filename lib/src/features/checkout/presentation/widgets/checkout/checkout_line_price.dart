import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/widgets/hero_money_text.dart';

/// The bottom line of an items-sheet row: "2x KD 0.600" (the count left to
/// right in Arabic too), the struck "was" price of a line on a deal, and the
/// line total at the end. When the pair does not fit (a narrow phone, large
/// text), the struck price wraps under it instead of overflowing.
class CheckoutLinePrice extends StatelessWidget {
  const CheckoutLinePrice({super.key, required this.line});

  final CartLineEntity line;

  @override
  Widget build(BuildContext context) {
    final strong = AppTextStyles.label.copyWith(
      fontWeight: AppTextStyles.bold,
      color: AppColors.primaryText,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'checkout.qty_times'.tr(
                    namedArgs: {'count': '${line.quantity}'},
                  ),
                  maxLines: 1,
                  style: strong.copyWith(fontFeatures: AppTextStyles.tabular),
                ),
              ),
              HeroMoneyText(kd: line.unitPriceKd, style: strong),
              if (line.hasDiscount)
                HeroMoneyText(
                  kd: line.compareAtKd,
                  strike: true,
                  style: AppTextStyles.bodySmall,
                  color: AppColors.tertiaryText,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        HeroMoneyText(kd: line.lineTotalKd, style: strong),
      ],
    );
  }
}
