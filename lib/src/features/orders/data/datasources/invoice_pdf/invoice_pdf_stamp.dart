import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// Where the payment stands, as a tinted pill with a dot under the title:
/// green "Paid", orange "Pay on delivery", red "Not charged".
class InvoicePdfStamp extends pw.StatelessWidget {
  InvoicePdfStamp(this.stamp, {required this.style});

  final InvoicePdfStampModel stamp;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    final color = InvoicePdfStyle.colorOf(stamp.tone);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: InvoicePdfStyle.stampPaddingH,
        vertical: InvoicePdfStyle.stampPaddingV,
      ),
      decoration: pw.BoxDecoration(
        color: InvoicePdfStyle.tintOf(stamp.tone),
        borderRadius: pw.BorderRadius.circular(InvoicePdfStyle.pillRadius),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: InvoicePdfStyle.stampDot,
            height: InvoicePdfStyle.stampDot,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: InvoicePdfStyle.gapS),
          InvoicePdfText(
            stamp.label,
            style: style,
            size: InvoicePdfStyle.label,
            bold: true,
            color: color,
          ),
        ],
      ),
    );
  }
}
