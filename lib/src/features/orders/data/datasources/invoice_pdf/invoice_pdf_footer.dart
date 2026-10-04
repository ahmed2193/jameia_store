import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The foot of every page: a hairline, the thank-you and the "Downloaded on"
/// line at the start, "Page 1 of 2" at the end.
class InvoicePdfFooter extends pw.StatelessWidget {
  InvoicePdfFooter({
    required this.invoice,
    required this.pageNumber,
    required this.pagesCount,
    required this.style,
  });

  final InvoicePdfModel invoice;
  final int pageNumber;
  final int pagesCount;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    final page = invoice.pageLabel
        .replaceAll(InvoicePdfModel.pageArg, '$pageNumber')
        .replaceAll(InvoicePdfModel.pagesArg, '$pagesCount');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(
          color: InvoicePdfStyle.hairline,
          thickness: InvoicePdfStyle.hairlineWidth,
          height: InvoicePdfStyle.gapXl,
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  InvoicePdfText(
                    invoice.thanks,
                    style: style,
                    size: InvoicePdfStyle.small,
                    bold: true,
                  ),
                  pw.SizedBox(height: InvoicePdfStyle.gapXs),
                  InvoicePdfText(
                    invoice.issued,
                    style: style,
                    size: InvoicePdfStyle.caption,
                    color: InvoicePdfStyle.muted,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: InvoicePdfStyle.gapL),
            InvoicePdfText(
              page,
              style: style,
              size: InvoicePdfStyle.caption,
              color: InvoicePdfStyle.muted,
              align: InvoicePdfAlign.end,
            ),
          ],
        ),
      ],
    );
  }
}
