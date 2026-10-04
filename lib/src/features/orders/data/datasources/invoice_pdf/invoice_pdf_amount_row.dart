import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// One row of the payment summary: the label at the start, the figure at
/// the end (a deduction or "Free" in brand green).
class InvoicePdfAmountRow extends pw.StatelessWidget {
  InvoicePdfAmountRow(this.row, {required this.style});

  final InvoicePdfAmountModel row;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: InvoicePdfStyle.gapXs),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: InvoicePdfText(row.label, style: style)),
          pw.SizedBox(width: InvoicePdfStyle.gapM),
          InvoicePdfText(
            row.amount,
            style: style,
            color: InvoicePdfStyle.colorOf(row.tone),
            align: InvoicePdfAlign.end,
          ),
        ],
      ),
    );
  }
}
