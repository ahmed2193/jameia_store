import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_assets_model.dart';
import '../../models/invoice_pdf_file_model.dart';
import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_footer.dart';
import 'invoice_pdf_info.dart';
import 'invoice_pdf_items_table.dart';
import 'invoice_pdf_masthead.dart';
import 'invoice_pdf_running_header.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_summary.dart';

/// Lays an invoice out as A4 pages: a brand band across the top edge, the
/// masthead, the order info and the recipient, the items table (it runs on
/// to more pages with its header repeated and a slim page header), the
/// payment summary, and a footer with the page count. Pure Dart, so it runs
/// on a background isolate.
abstract final class InvoicePdfDocument {
  static Future<InvoicePdfFileModel> layOut(
    InvoicePdfModel invoice,
    InvoicePdfAssetsModel assets,
  ) async {
    final style = InvoicePdfStyle.of(assets, rtl: invoice.rtl);
    final logo = pw.MemoryImage(assets.logoPng);
    final document = pw.Document(
      title: invoice.documentTitle,
      author: invoice.brandName,
      creator: invoice.brandName,
      subject: invoice.title,
    );
    document.addPage(
      pw.MultiPage(
        maxPages: InvoicePdfStyle.maxPages,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            InvoicePdfStyle.pageGutter,
            InvoicePdfStyle.pageTop,
            InvoicePdfStyle.pageGutter,
            InvoicePdfStyle.pageBottom,
          ),
          textDirection: invoice.rtl
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          theme: style.theme,
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  height: InvoicePdfStyle.accentBar,
                  color: InvoicePdfStyle.brand,
                ),
              ],
            ),
          ),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : InvoicePdfRunningHeader(invoice: invoice, style: style),
        footer: (context) => InvoicePdfFooter(
          invoice: invoice,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
          style: style,
        ),
        build: (_) => [
          InvoicePdfMasthead(invoice: invoice, logo: logo, style: style),
          pw.SizedBox(height: InvoicePdfStyle.section),
          InvoicePdfInfo(
            details: invoice.details,
            recipient: invoice.recipient,
            style: style,
          ),
          pw.SizedBox(height: InvoicePdfStyle.section),
          InvoicePdfItemsTable(invoice.table, style),
          pw.SizedBox(height: InvoicePdfStyle.section),
          InvoicePdfSummary(invoice.summary, style: style),
        ],
      ),
    );
    final bytes = await document.save();
    return InvoicePdfFileModel(
      bytes: bytes,
      pageCount: document.document.pdfPageList.pages.length,
    );
  }
}
