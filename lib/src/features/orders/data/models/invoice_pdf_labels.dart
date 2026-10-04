/// The keys the invoice PDF reads, all in the app's `orders` section, so the
/// PDF and the invoice page share their words. The `invoice_pdf_*` ones are
/// the PDF's own.
abstract final class InvoicePdfKeys {
  static const String brand = 'orders.invoice_pdf_brand';
  static const String title = 'orders.invoice_title';
  static const String infoTitle = 'orders.info_title';
  static const String number = 'orders.invoice_number';
  static const String date = 'orders.invoice_date';
  static const String payment = 'orders.invoice_payment';
  static const String status = 'orders.invoice_status';
  static const String type = 'orders.invoice_pdf_type';
  static const String store = 'orders.invoice_pdf_store';
  static const String slot = 'orders.invoice_pdf_slot';
  static const String slotWindow = 'orders.slot_window';
  static const String deliverTo = 'orders.invoice_pdf_deliver_to';
  static const String customer = 'orders.invoice_pdf_customer';
  static const String columnNumber = 'orders.invoice_pdf_col_number';
  static const String columnItem = 'orders.invoice_pdf_col_item';
  static const String columnQuantity = 'orders.invoice_pdf_col_qty';
  static const String columnPrice = 'orders.invoice_pdf_col_price';
  static const String columnTotal = 'orders.invoice_pdf_col_total';
  static const String sku = 'orders.invoice_pdf_sku';
  static const String unavailable = 'orders.line_unavailable';
  static const String replacedWith = 'orders.line_replaced_with';
  static const String summaryTitle = 'orders.summary_title';
  static const String free = 'orders.free';
  static const String total = 'orders.total';
  static const String walletShare = 'orders.payment_wallet_share';
  static const String pointsEarned = 'orders.loyalty_earned';
  static const String pointsPending = 'orders.loyalty_pending';
  static const String thanks = 'orders.invoice_pdf_thanks';
  static const String issued = 'orders.invoice_pdf_issued';
  static const String page = 'orders.invoice_pdf_page';

  /// Every key above; each must be in both language files (a test checks,
  /// with the keys the PDF reads through the `labelKey` of the order status,
  /// the payment method, the payment standing, the summary rows and the order
  /// type).
  static const List<String> all = [
    brand,
    title,
    infoTitle,
    number,
    date,
    payment,
    status,
    type,
    store,
    slot,
    slotWindow,
    deliverTo,
    customer,
    columnNumber,
    columnItem,
    columnQuantity,
    columnPrice,
    columnTotal,
    sku,
    unavailable,
    replacedWith,
    summaryTitle,
    free,
    total,
    walletShare,
    pointsEarned,
    pointsPending,
    thanks,
    issued,
    page,
  ];
}

/// The invoice PDF's words in one language — that language's `orders.*`
/// strings (full keys, `orders.subtotal`), with `{name}` arguments filled the
/// way easy_localization fills `namedArgs`. A missing key reads as the key
/// itself, like in the app, so a gap shows instead of a blank.
class InvoicePdfLabels {
  const InvoicePdfLabels(this._strings);

  final Map<String, String> _strings;

  String call(String key, [Map<String, String> args = const {}]) {
    var text = _strings[key] ?? key;
    for (final MapEntry(:key, :value) in args.entries) {
      text = text.replaceAll('{$key}', value);
    }
    return text;
  }
}
