import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// A hairline card with a small green title — the shell of the order-info
/// and the "Deliver to" blocks, so both share one rhythm.
class InvoicePdfPanel extends pw.StatelessWidget {
  InvoicePdfPanel({
    required this.title,
    required this.children,
    required this.style,
  });

  final String title;
  final List<pw.Widget> children;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(InvoicePdfStyle.gapL),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: InvoicePdfStyle.hairline,
          width: InvoicePdfStyle.hairlineWidth,
        ),
        borderRadius: pw.BorderRadius.circular(InvoicePdfStyle.radius),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          InvoicePdfText(
            title,
            style: style,
            size: InvoicePdfStyle.small,
            bold: true,
            color: InvoicePdfStyle.brandDeep,
          ),
          pw.SizedBox(height: InvoicePdfStyle.gapM),
          ...children,
        ],
      ),
    );
  }
}
