import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf_cell.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// A column title of the items table: small, bold, brand deep green.
class InvoicePdfHeaderCell extends pw.StatelessWidget {
  InvoicePdfHeaderCell(
    this.title, {
    required this.style,
    this.align = InvoicePdfAlign.start,
  });

  final String title;
  final InvoicePdfStyle style;
  final InvoicePdfAlign align;

  @override
  pw.Widget build(pw.Context context) {
    return InvoicePdfCell(
      title,
      style: style,
      size: InvoicePdfStyle.small,
      bold: true,
      color: InvoicePdfStyle.brandDeep,
      align: align,
    );
  }
}
