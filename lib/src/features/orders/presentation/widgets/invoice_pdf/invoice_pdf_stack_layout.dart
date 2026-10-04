import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../invoice/invoice_file_card.dart';
import '../invoice/invoice_language_switch.dart';
import 'invoice_pdf_canvas.dart';

/// The invoice PDF on a phone held upright: the language and the file on
/// top, the pages under them taking the rest of the height (the actions sit
/// in the page's bottom bar).
class InvoicePdfStackLayout extends StatelessWidget {
  const InvoicePdfStackLayout({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s12,
            AppSpacing.gutter,
            0,
          ),
          child: InvoiceLanguageSwitch(),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.gutter),
          child: InvoiceFileCard(orderNumber: orderNumber),
        ),
        const Expanded(child: InvoicePdfCanvas()),
      ],
    );
  }
}
