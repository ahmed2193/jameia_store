import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../order_lines_card.dart';
import 'invoice_header.dart';
import 'invoice_totals.dart';

/// The receipt: order meta, the lines as sold, and the totals.
class InvoiceBody extends StatelessWidget {
  const InvoiceBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      children: [
        InvoiceHeader(order: order),
        const SizedBox(height: AppSpacing.s8),
        OrderLinesCard(order: order, showInvoiceLink: false),
        const SizedBox(height: AppSpacing.s8),
        InvoiceTotals(order: order),
      ],
    );
  }
}
