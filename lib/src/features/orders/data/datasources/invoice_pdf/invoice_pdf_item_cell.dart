import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The item column of one row: the product's name (struck through when the
/// picker could not hand it over as ordered), its variant and SKU, and what
/// happened to it ("Unavailable", "Replaced with …", the free offer).
class InvoicePdfItemCell extends pw.StatelessWidget {
  InvoicePdfItemCell(this.line, {required this.style});

  final InvoicePdfLineModel line;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: InvoicePdfStyle.cellPaddingH,
        vertical: InvoicePdfStyle.cellPaddingV,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          InvoicePdfText(
            line.name,
            style: style,
            struck: line.struck,
            color: line.struck ? InvoicePdfStyle.muted : null,
          ),
          if (line.detail.isNotEmpty) ...[
            pw.SizedBox(height: InvoicePdfStyle.gapXs),
            InvoicePdfText(
              line.detail,
              style: style,
              size: InvoicePdfStyle.small,
              color: InvoicePdfStyle.muted,
            ),
          ],
          if (line.note.isNotEmpty) ...[
            pw.SizedBox(height: InvoicePdfStyle.gapXs),
            InvoicePdfText(
              line.note,
              style: style,
              size: InvoicePdfStyle.small,
              color: InvoicePdfStyle.colorOf(line.noteTone),
            ),
          ],
        ],
      ),
    );
  }
}
