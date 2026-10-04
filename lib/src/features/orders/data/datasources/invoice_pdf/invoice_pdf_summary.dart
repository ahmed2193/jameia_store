import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_amount_row.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The payment summary at the end side under the table: the rows, the total
/// on a green wash band, then the notes (the wallet's share, the points).
/// One block: it moves to the next page whole rather than split.
class InvoicePdfSummary extends pw.StatelessWidget {
  InvoicePdfSummary(this.summary, {required this.style});

  final InvoicePdfSummaryModel summary;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Spacer(),
        pw.SizedBox(
          width: InvoicePdfStyle.summaryWidth,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              InvoicePdfText(
                summary.title,
                style: style,
                size: InvoicePdfStyle.small,
                bold: true,
                color: InvoicePdfStyle.brandDeep,
              ),
              pw.SizedBox(height: InvoicePdfStyle.gapS),
              for (final row in summary.rows)
                InvoicePdfAmountRow(row, style: style),
              pw.SizedBox(height: InvoicePdfStyle.gapM),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: InvoicePdfStyle.gapL,
                  vertical: InvoicePdfStyle.gapM,
                ),
                decoration: pw.BoxDecoration(
                  color: InvoicePdfStyle.brandWash,
                  borderRadius: pw.BorderRadius.circular(
                    InvoicePdfStyle.radius,
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: InvoicePdfText(
                        summary.totalLabel,
                        style: style,
                        size: InvoicePdfStyle.emphasis,
                        bold: true,
                      ),
                    ),
                    InvoicePdfText(
                      summary.totalAmount,
                      style: style,
                      size: InvoicePdfStyle.total,
                      bold: true,
                      color: InvoicePdfStyle.brandDeep,
                      align: InvoicePdfAlign.end,
                    ),
                  ],
                ),
              ),
              for (final note in summary.notes) ...[
                pw.SizedBox(height: InvoicePdfStyle.gapS),
                InvoicePdfText(
                  note,
                  style: style,
                  size: InvoicePdfStyle.small,
                  color: InvoicePdfStyle.muted,
                  align: InvoicePdfAlign.end,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
