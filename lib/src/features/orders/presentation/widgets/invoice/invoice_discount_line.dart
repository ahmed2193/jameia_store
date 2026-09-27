import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';

/// A deduction on the invoice (offer, Pro, coupon, loyalty): the label and
/// the minus amount in brand deep green, one left-to-right money run.
class InvoiceDiscountLine extends StatelessWidget {
  const InvoiceDiscountLine({super.key, required this.label, required this.kd});

  final String label;
  final double kd;

  @override
  Widget build(BuildContext context) {
    return HeroSummaryLine(
      label: label,
      value: HeroMoneyText(
        kd: kd,
        negative: true,
        color: AppColors.brandDeep,
      ),
    );
  }
}
