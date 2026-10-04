import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/utils/formatters.dart';
import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The slim header of a page after the first: the brand at the start, the
/// title and order number at the end — a loose page still says whose it is.
class InvoicePdfRunningHeader extends pw.StatelessWidget {
  InvoicePdfRunningHeader({required this.invoice, required this.style});

  final InvoicePdfModel invoice;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: InvoicePdfStyle.gapXl),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: InvoicePdfText(
              invoice.brandName,
              style: style,
              size: InvoicePdfStyle.small,
              bold: true,
            ),
          ),
          InvoicePdfText(
            [invoice.title, invoice.orderNumber].join(Formatters.middot),
            style: style,
            size: InvoicePdfStyle.small,
            color: InvoicePdfStyle.muted,
            align: InvoicePdfAlign.end,
          ),
        ],
      ),
    );
  }
}
