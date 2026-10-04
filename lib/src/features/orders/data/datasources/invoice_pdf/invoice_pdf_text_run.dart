import 'package:pdf/widgets.dart' as pw;

/// One run of [InvoicePdfText]: text of one script, set in that script's
/// direction with a style whose primary font is that script's face (the pdf
/// package shapes right-to-left glyphs only from a run's primary font).
class InvoicePdfTextRun extends pw.StatelessWidget {
  InvoicePdfTextRun(
    this.text, {
    required this.rtl,
    required this.textStyle,
    this.textAlign,
  });

  final String text;
  final bool rtl;
  final pw.TextStyle textStyle;
  final pw.TextAlign? textAlign;

  @override
  pw.Widget build(pw.Context context) {
    final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    return pw.Directionality(
      textDirection: direction,
      child: pw.Text(
        text,
        textDirection: direction,
        textAlign: textAlign,
        style: textStyle,
      ),
    );
  }
}
