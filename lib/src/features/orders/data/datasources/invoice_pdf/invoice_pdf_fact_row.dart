import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// One fact of the order-info block: the grey label at the start, the value
/// beside it; a long value wraps in its own column.
class InvoicePdfFactRow extends pw.StatelessWidget {
  InvoicePdfFactRow(this.fact, {required this.style});

  final InvoicePdfFactModel fact;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: InvoicePdfStyle.gapS),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: InvoicePdfStyle.factLabelFlex,
            child: InvoicePdfText(
              fact.label,
              style: style,
              size: InvoicePdfStyle.label,
              color: InvoicePdfStyle.muted,
            ),
          ),
          pw.SizedBox(width: InvoicePdfStyle.gapM),
          pw.Expanded(
            flex: InvoicePdfStyle.factValueFlex,
            child: InvoicePdfText(fact.value, style: style),
          ),
        ],
      ),
    );
  }
}
