import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';

/// An [amount] widget (its digits laid out left-to-right) with the smaller
/// currency label where the language puts it: `KD 12.500` in English,
/// `12.500 د.ك` in Arabic (the label stays outside the number run).
class MineCurrencyAmount extends StatelessWidget {
  const MineCurrencyAmount({super.key, required this.amount});

  static const String _arabic = 'ar';

  final Widget amount;

  @override
  Widget build(BuildContext context) {
    final currency = Text(
      Formatters.currency,
      style: AppTextStyles.captionLarge.copyWith(
        fontWeight: AppTextStyles.bold,
        color: AppColors.secondaryText,
      ),
    );
    const gap = SizedBox(width: AppSpacing.s2);
    final amountFirst = context.locale.languageCode == _arabic;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: amountFirst ? [amount, gap, currency] : [currency, gap, amount],
    );
  }
}
