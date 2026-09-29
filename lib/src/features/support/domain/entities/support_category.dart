/// `category` of a support ticket — the keys `GET /v1/support/categories`
/// lists (the API sends keys only; the app names them).
enum SupportCategory {
  order('order'),
  delivery('delivery'),
  payment('payment'),
  wallet('wallet'),
  account('account'),
  product('product'),
  subscription('subscription'),
  other('other');

  const SupportCategory(this.wireValue);

  final String wireValue;

  /// `null` for a key this build does not know (the row is left out).
  static SupportCategory? fromWire(String value) {
    for (final category in values) {
      if (category.wireValue == value) return category;
    }
    return null;
  }

  /// i18n key of the category's name (a group title on the help page).
  String get labelKey => 'support.category_$wireValue';
}

/// `subcategory` of a support ticket: what exactly went wrong.
enum SupportTopic {
  missingItems('missing_items'),
  wrongItems('wrong_items'),
  notReceived('not_received'),
  quantity('quantity'),
  late('late'),
  driver('driver'),
  wrongAddress('wrong_address'),
  failed('failed'),
  chargeDispute('charge_dispute'),
  doubleCharge('double_charge'),
  notProcessed('not_processed'),
  balance('balance'),
  creditMissing('credit_missing'),
  refundToWallet('refund_to_wallet'),
  login('login'),
  passwordReset('password_reset'),
  profile('profile'),
  accountDeletion('account_deletion'),
  damaged('damaged'),
  expired('expired'),
  quality('quality'),
  billing('billing'),
  cancellation('cancellation'),
  access('access');

  const SupportTopic(this.wireValue);

  final String wireValue;

  /// `null` for a key this build does not know (the row is left out).
  static SupportTopic? fromWire(String value) {
    for (final topic in values) {
      if (topic.wireValue == value) return topic;
    }
    return null;
  }

  /// i18n key of the topic's name (an option on the help page).
  String get labelKey => 'support.topic_$wireValue';
}
