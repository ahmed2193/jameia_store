import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../config/theme/app_colors.dart';
import '../../models/invoice_pdf_assets_model.dart';
import '../../models/invoice_pdf_model.dart';

/// The invoice PDF's look: the brand palette (read from [AppColors], so paper
/// and screen share one source), the type scale and the measures — all in PDF
/// points (1/72 in). Built once per document, around its fonts.
class InvoicePdfStyle {
  InvoicePdfStyle._({
    required this.rtl,
    required this._latin,
    required this._latinBold,
    required this._arabic,
    required this._arabicBold,
  });

  factory InvoicePdfStyle.of(
    InvoicePdfAssetsModel assets, {
    required bool rtl,
  }) => InvoicePdfStyle._(
    rtl: rtl,
    latin: pw.Font.ttf(assets.latinRegular),
    latinBold: pw.Font.ttf(assets.latinBold),
    arabic: pw.Font.ttf(assets.arabicRegular),
    arabicBold: pw.Font.ttf(assets.arabicBold),
  );

  /// The page reads right to left (an Arabic invoice).
  final bool rtl;
  final pw.Font _latin;
  final pw.Font _latinBold;
  final pw.Font _arabic;
  final pw.Font _arabicBold;

  /// The page default, for text with no style of its own.
  pw.ThemeData get theme => pw.ThemeData.withFont(
    base: rtl ? _arabic : _latin,
    bold: rtl ? _arabicBold : _latinBold,
    fontFallback: rtl ? [_latin, _latinBold] : [_arabic, _arabicBold],
  );

  /// A run of text in its script's own font. The pdf package shapes and
  /// orders right-to-left glyphs only from a run's primary font — glyphs a
  /// fallback font supplies come out reversed — so an Arabic run is set in
  /// the Arabic face and a Latin run in the Latin one, each with the other
  /// as a fallback for stray characters.
  pw.TextStyle textStyle({
    required bool arabic,
    bool bold = false,
    double size = body,
    PdfColor? color,
    bool struck = false,
  }) => pw.TextStyle(
    font: arabic
        ? (bold ? _arabicBold : _arabic)
        : (bold ? _latinBold : _latin),
    fontFallback: [
      if (arabic)
        (bold ? _latinBold : _latin)
      else
        (bold ? _arabicBold : _arabic),
    ],
    fontSize: size,
    lineSpacing: lineGap,
    color: color ?? ink,
    decoration: struck ? pw.TextDecoration.lineThrough : null,
  );

  // ── Palette ───────────────────────────────────────────────────────────────
  static final PdfColor brand = _pdf(AppColors.primary);
  static final PdfColor brandDeep = _pdf(AppColors.brandDeep);
  static final PdfColor brandWash = _pdf(AppColors.brandWash);
  static final PdfColor brandTint = _pdf(AppColors.brandLightBg);
  static final PdfColor ink = _pdf(AppColors.primaryText);
  static final PdfColor muted = _pdf(AppColors.secondaryText);
  static final PdfColor hairline = _pdf(AppColors.divider);
  static final PdfColor warning = _pdf(AppColors.warn);
  static final PdfColor warningTint = _pdf(AppColors.warnBg);
  static final PdfColor negative = _pdf(AppColors.errorDeep);
  static final PdfColor negativeTint = _pdf(AppColors.errorBg);

  static PdfColor _pdf(Color color) => PdfColor.fromInt(color.toARGB32());

  static PdfColor colorOf(InvoicePdfTone tone) => switch (tone) {
    InvoicePdfTone.normal => ink,
    InvoicePdfTone.muted => muted,
    InvoicePdfTone.positive => brandDeep,
    InvoicePdfTone.warning => warning,
    InvoicePdfTone.negative => negative,
  };

  static PdfColor tintOf(InvoicePdfTone tone) => switch (tone) {
    InvoicePdfTone.positive => brandTint,
    InvoicePdfTone.warning => warningTint,
    InvoicePdfTone.negative => negativeTint,
    InvoicePdfTone.normal || InvoicePdfTone.muted => brandWash,
  };

  // ── Type scale ────────────────────────────────────────────────────────────
  static const double caption = 7.5;
  static const double small = 8;
  static const double label = 8.5;
  static const double body = 9.5;
  static const double emphasis = 11;
  static const double heading = 15;
  static const double total = 16;
  static const double display = 24;

  /// Extra room between wrapped lines.
  static const double lineGap = 1.5;

  /// A space, as a share of the font size (Noto's space is 0.26 em): the
  /// gap between the words of a line set word by word.
  static const double wordSpace = 0.26;

  // ── Measures ──────────────────────────────────────────────────────────────
  static const double pageGutter = 36;
  static const double pageTop = 40;
  static const double pageBottom = 28;

  /// The brand band across the top edge of every page.
  static const double accentBar = 5;
  static const double logo = 36;
  static const double logoRadius = 9;
  static const double gapXs = 2;
  static const double gapS = 4;
  static const double gapM = 8;
  static const double gapL = 12;
  static const double gapXl = 16;
  static const double section = 22;
  static const double radius = 8;
  static const double pillRadius = 10;
  static const double stampPaddingH = 8;
  static const double stampPaddingV = 3;
  static const double stampDot = 5;
  static const double hairlineWidth = 0.6;
  static const double cellPaddingH = 6;
  static const double cellPaddingV = 6;
  static const double numberColumn = 22;
  static const double quantityColumn = 34;
  static const double priceColumn = 64;
  static const double totalColumn = 68;
  static const double summaryWidth = 232;
  static const int factLabelFlex = 2;
  static const int factValueFlex = 3;

  /// Pages one invoice may run to (an order of hundreds of lines).
  static const int maxPages = 40;
}
