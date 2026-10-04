/// The colour a piece of the invoice PDF reads in (mapped to the brand
/// palette by the layout).
enum InvoicePdfTone {
  /// Body ink.
  normal,

  /// Secondary grey (details, notes).
  muted,

  /// Brand deep green: a deduction, "Free", a replacement, "Paid".
  positive,

  /// Orange: money still due.
  warning,

  /// Red: unavailable, cancelled.
  negative,
}

/// One label / value pair of an info block ("Date" → "21 Sept 2026").
class InvoicePdfFactModel {
  const InvoicePdfFactModel(this.label, this.value);

  final String label;
  final String value;
}

/// A titled block of facts (the order info, where it goes).
class InvoicePdfBlockModel {
  const InvoicePdfBlockModel({required this.title, required this.facts});

  final String title;
  final List<InvoicePdfFactModel> facts;
}

/// Who and where the order is for: a bold [heading] (the customer's name)
/// over plain [lines] (the address, the phone).
class InvoicePdfPartyModel {
  const InvoicePdfPartyModel({
    required this.title,
    required this.heading,
    this.lines = const <String>[],
  });

  final String title;
  final String heading;
  final List<String> lines;
}

/// One row of the items table, every word and figure already written out.
class InvoicePdfLineModel {
  const InvoicePdfLineModel({
    required this.position,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.detail = '',
    this.note = '',
    this.noteTone = InvoicePdfTone.muted,
    this.struck = false,
    this.totalTone = InvoicePdfTone.normal,
  });

  /// "1", "2" … (empty for a free offer line).
  final String position;
  final String name;

  /// The variant and the SKU ("Full fat · SKU 6281…"), or empty.
  final String detail;

  /// What happened to the line ("Unavailable", "Replaced with …", "Free ·
  /// offer"), or empty.
  final String note;
  final InvoicePdfTone noteTone;

  /// The picker could not hand the line over as ordered.
  final bool struck;
  final String quantity;
  final String unitPrice;
  final String total;
  final InvoicePdfTone totalTone;
}

/// The items table: its column titles and rows.
class InvoicePdfTableModel {
  const InvoicePdfTableModel({
    required this.positionTitle,
    required this.itemTitle,
    required this.quantityTitle,
    required this.unitPriceTitle,
    required this.totalTitle,
    required this.lines,
  });

  final String positionTitle;
  final String itemTitle;
  final String quantityTitle;
  final String unitPriceTitle;
  final String totalTitle;
  final List<InvoicePdfLineModel> lines;
}

/// One row of the payment summary.
class InvoicePdfAmountModel {
  const InvoicePdfAmountModel(
    this.label,
    this.amount, {
    this.tone = InvoicePdfTone.normal,
  });

  final String label;
  final String amount;
  final InvoicePdfTone tone;
}

/// The payment summary: the rows, the total and the notes under it.
class InvoicePdfSummaryModel {
  const InvoicePdfSummaryModel({
    required this.title,
    required this.rows,
    required this.totalLabel,
    required this.totalAmount,
    this.notes = const <String>[],
  });

  final String title;
  final List<InvoicePdfAmountModel> rows;
  final String totalLabel;

  /// With its currency ("KD 12.500" / "12.500 د.ك").
  final String totalAmount;

  /// The wallet's share, the loyalty points.
  final List<String> notes;
}

/// The status stamp beside the title ("Paid", "Pay on delivery",
/// "Cancelled").
class InvoicePdfStampModel {
  const InvoicePdfStampModel(this.label, this.tone);

  final String label;
  final InvoicePdfTone tone;
}

/// An order's invoice, ready to lay out: every word in the chosen language,
/// every figure written out. Plain data, so it crosses to the isolate that
/// lays the PDF out.
class InvoicePdfModel {
  const InvoicePdfModel({
    required this.rtl,
    required this.documentTitle,
    required this.brandName,
    required this.title,
    required this.orderNumber,
    required this.stamp,
    required this.details,
    required this.recipient,
    required this.table,
    required this.summary,
    required this.thanks,
    required this.issued,
    required this.pageLabel,
  });

  /// `{page}` and `{pages}` in [pageLabel].
  static const String pageArg = '{page}';
  static const String pagesArg = '{pages}';

  /// Arabic: the page mirrors.
  final bool rtl;

  /// The PDF's own title (its metadata, shown by viewers).
  final String documentTitle;
  final String brandName;
  final String title;
  final String orderNumber;
  final InvoicePdfStampModel stamp;
  final InvoicePdfBlockModel details;
  final InvoicePdfPartyModel recipient;
  final InvoicePdfTableModel table;
  final InvoicePdfSummaryModel summary;
  final String thanks;

  /// "Downloaded on …".
  final String issued;

  /// "Page {page} of {pages}".
  final String pageLabel;
}
