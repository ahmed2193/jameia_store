import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_fact_row.dart';
import 'invoice_pdf_panel.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The two blocks under the masthead: the order's facts at the start, who
/// and where it is for at the end. Laid out as a one-row table so both
/// cards take the taller one's height; reversed on an Arabic page.
class InvoicePdfInfo extends pw.StatelessWidget {
  InvoicePdfInfo({
    required this.details,
    required this.recipient,
    required this.style,
  });

  final InvoicePdfBlockModel details;
  final InvoicePdfPartyModel recipient;
  final InvoicePdfStyle style;

  @override
  pw.Widget build(pw.Context context) {
    final cells = <pw.Widget>[
      InvoicePdfPanel(
        title: details.title,
        style: style,
        children: [
          for (final fact in details.facts)
            InvoicePdfFactRow(fact, style: style),
        ],
      ),
      pw.SizedBox(width: InvoicePdfStyle.gapXl),
      InvoicePdfPanel(
        title: recipient.title,
        style: style,
        children: [
          InvoicePdfText(
            recipient.heading,
            style: style,
            size: InvoicePdfStyle.emphasis,
            bold: true,
          ),
          for (final line in recipient.lines) ...[
            pw.SizedBox(height: InvoicePdfStyle.gapXs),
            InvoicePdfText(line, style: style),
          ],
        ],
      ),
    ];
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(InvoicePdfStyle.gapXl),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.full,
          children: style.rtl ? cells.reversed.toList() : cells,
        ),
      ],
    );
  }
}
