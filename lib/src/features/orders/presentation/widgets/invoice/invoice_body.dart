import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../order_lines_sliver.dart';
import 'invoice_header.dart';
import 'invoice_totals.dart';

/// The receipt on the white page: order info, the lines as sold (a lazy
/// sliver, no invoice link — this is the invoice), and the payment summary.
/// A document: nothing on it moves.
class InvoiceBody extends StatelessWidget {
  const InvoiceBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: InvoiceHeader(order: order)),
        OrderLinesSliver(
          orderId: order.id,
          lines: order.lines,
          offerLines: order.offerLines,
          totalKd: order.totalKd,
          showInvoiceLink: false,
        ),
        SliverToBoxAdapter(child: InvoiceTotals(order: order)),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
    );
  }
}
