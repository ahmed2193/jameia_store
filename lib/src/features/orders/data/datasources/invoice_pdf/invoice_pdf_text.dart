import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf_bidi.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text_run.dart';

/// Where a piece of text sits across its box, read against the page's
/// direction: start = left on an English page, right on an Arabic one.
enum InvoicePdfAlign { start, end, center }

/// Every piece of text on the invoice PDF, set in its own direction.
///
/// - No Arabic letter: one left-to-right run in the Latin face, even on an
///   Arabic page (an order number, a phone, a price keep `HM-1001`, `+965…`
///   in order).
/// - Arabic only: one right-to-left run in the Arabic face, brackets
///   mirrored (the pdf package mirrors none).
/// - Arabic beside Latin letters or digits: word by word in a wrap that
///   flows the line's way ([InvoicePdfBidi]) — the pdf package mis-sets such
///   runs whole.
///
/// The pdf package shapes right-to-left glyphs only from a run's primary
/// font, so each run is set in its own script's face. The alignment follows
/// the page, not the run.
class InvoicePdfText extends pw.StatelessWidget {
  InvoicePdfText(
    this.text, {
    required this.style,
    this.size = InvoicePdfStyle.body,
    this.bold = false,
    this.color,
    this.struck = false,
    this.align = InvoicePdfAlign.start,
  });

  final String text;
  final InvoicePdfStyle style;
  final double size;
  final bool bold;
  final PdfColor? color;
  final bool struck;
  final InvoicePdfAlign align;

  @override
  pw.Widget build(pw.Context context) {
    final pageRtl = pw.Directionality.of(context) == pw.TextDirection.rtl;
    final right = switch (align) {
      InvoicePdfAlign.start => pageRtl,
      InvoicePdfAlign.end => !pageRtl,
      InvoicePdfAlign.center => null,
    };
    final textAlign = switch (right) {
      null => pw.TextAlign.center,
      true => pw.TextAlign.right,
      false => pw.TextAlign.left,
    };
    pw.TextStyle styleOf({required bool arabic}) => style.textStyle(
      arabic: arabic,
      bold: bold,
      size: size,
      color: color,
      struck: struck,
    );
    if (!InvoicePdfBidi.hasArabic(text)) {
      return InvoicePdfTextRun(
        text,
        rtl: false,
        textStyle: styleOf(arabic: false),
        textAlign: textAlign,
      );
    }
    if (!InvoicePdfBidi.isMixed(text)) {
      return InvoicePdfTextRun(
        InvoicePdfBidi.mirrored(text),
        rtl: true,
        textStyle: styleOf(arabic: true),
        textAlign: textAlign,
      );
    }
    final latinStyle = styleOf(arabic: false);
    final arabicStyle = styleOf(arabic: true);
    final line = InvoicePdfBidi.lineOf(text, pageRtl: pageRtl);
    return pw.Directionality(
      textDirection: line.rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Wrap(
        // The wrap's start is the line's side: right for an Arabic line.
        alignment: switch (right) {
          null => pw.WrapAlignment.center,
          true => line.rtl ? pw.WrapAlignment.start : pw.WrapAlignment.end,
          false => line.rtl ? pw.WrapAlignment.end : pw.WrapAlignment.start,
        },
        spacing: size * InvoicePdfStyle.wordSpace,
        runSpacing: InvoicePdfStyle.lineGap,
        children: [
          for (final word in line.words)
            InvoicePdfTextRun(
              word.text,
              rtl: word.arabic,
              textStyle: word.arabic ? arabicStyle : latinStyle,
            ),
        ],
      ),
    );
  }
}
