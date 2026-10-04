import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// One plain cell of the items table: padded text, aligned against the page
/// (numbers sit at the end, the position in the middle).
class InvoicePdfCell extends pw.StatelessWidget {
  InvoicePdfCell(
    this.text, {
    required this.style,
    this.size = InvoicePdfStyle.body,
    this.bold = false,
    this.color,
    this.align = InvoicePdfAlign.start,
  });

  final String text;
  final InvoicePdfStyle style;
  final double size;
  final bool bold;
  final PdfColor? color;
  final InvoicePdfAlign align;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: InvoicePdfStyle.cellPaddingH,
        vertical: InvoicePdfStyle.cellPaddingV,
      ),
      child: InvoicePdfText(
        text,
        style: style,
        size: size,
        bold: bold,
        color: color,
        align: align,
      ),
    );
  }
}
