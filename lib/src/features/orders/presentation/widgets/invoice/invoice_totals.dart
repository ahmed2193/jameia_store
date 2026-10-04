import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/order_invoice_summary.dart';
import 'invoice_charge_line.dart';
import 'invoice_loyalty_note.dart';
import 'invoice_perforation.dart';
import 'invoice_section.dart';

/// "Payment summary": the order's own totals — every figure comes from the
/// server, nothing is recomputed here. Which rows show is
/// [OrderInvoiceSummary]'s rule, the same the PDF invoice follows.
/// Deductions and "Free" read in brand deep green; money is one
/// left-to-right run.
class InvoiceTotals extends StatelessWidget {
  const InvoiceTotals({
    super.key,
    required this.order,
    this.trailing = const <Widget>[],
    this.perforated = false,
  });

  final OrderEntity order;

  /// More rows at the foot of the card (the order page adds how it is paid).
  final List<Widget> trailing;

  /// A receipt's dashed tear line above the total (the invoice page) instead
  /// of the plain hairline.
  final bool perforated;

  @override
  Widget build(BuildContext context) {
    final summary = OrderInvoiceSummary.of(order);
    final points = summary.points;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InvoiceSection(
          title: 'orders.summary_title'.tr(),
          children: [
            for (final charge in summary.charges)
              InvoiceChargeLine(charge: charge),
            if (perforated)
              const InvoicePerforation()
            else
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  vertical: AppSpacing.s8,
                ),
                child: ThinDivider(),
              ),
            HeroSummaryLine(
              label: 'orders.total'.tr(),
              emphasized: true,
              value: HeroMoneyText(kd: summary.totalKd),
            ),
            ...trailing,
          ],
        ),
        if (points != null)
          InvoiceLoyaltyNote(points: points.points, pending: points.pending),
      ],
    );
  }
}
