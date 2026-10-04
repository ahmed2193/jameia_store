/// The language an order's PDF invoice is written in: either of the app's
/// two, whatever the app itself shows — a customer reading the app in Arabic
/// may need the invoice in English for work, and the other way round.
enum InvoiceLanguage {
  english('en'),
  arabic('ar');

  const InvoiceLanguage(this.code);

  /// The language code (`en` / `ar`) the document's words come in.
  final String code;

  /// Arabic reads right to left: the whole page mirrors.
  bool get isRtl => this == InvoiceLanguage.arabic;

  /// The language for [languageCode] (`ar…` → Arabic, anything else →
  /// English), so the app's own language is the first choice.
  static InvoiceLanguage of(String languageCode) =>
      languageCode.startsWith(arabic.code) ? arabic : english;
}
