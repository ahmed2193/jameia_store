import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_stamp.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The top of the first page: the logo and the brand at the start; the
/// title, the order number and the payment stamp at the end.
class InvoicePdfMasthead extends pw.StatelessWidget {
  InvoicePdfMasthead({
    required this.invoice,
    required this.logo,
    required this.style,
  });

  final InvoicePdfModel invoice;
  final pw.ImageProvider logo;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: InvoicePdfStyle.logoRadius,
          verticalRadius: InvoicePdfStyle.logoRadius,
          child: pw.Image(
            logo,
            width: InvoicePdfStyle.logo,
            height: InvoicePdfStyle.logo,
          ),
        ),
        pw.SizedBox(width: InvoicePdfStyle.gapL),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: InvoicePdfStyle.gapM),
            child: InvoicePdfText(
              invoice.brandName,
              style: style,
              size: InvoicePdfStyle.heading,
              bold: true,
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            InvoicePdfText(
              invoice.title,
              style: style,
              size: InvoicePdfStyle.display,
              bold: true,
              align: InvoicePdfAlign.end,
            ),
            pw.SizedBox(height: InvoicePdfStyle.gapXs),
            InvoicePdfText(
              invoice.orderNumber,
              style: style,
              size: InvoicePdfStyle.emphasis,
              color: InvoicePdfStyle.muted,
              align: InvoicePdfAlign.end,
            ),
            pw.SizedBox(height: InvoicePdfStyle.gapM),
            InvoicePdfStamp(invoice.stamp, style: style),
          ],
        ),
      ],
    );
  }
}
