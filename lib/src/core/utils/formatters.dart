import 'package:easy_localization/easy_localization.dart';

/// Lightweight formatting helpers (currency, distance, counts).
///
/// Hero shows region currency; the clone uses Kuwaiti Dinar (KD / د.ك, 3
/// decimals) as the demo currency to match the GCC market in the reference.
///
/// Locale awareness: the currency **label** and its placement follow the active
/// locale (via [Intl.defaultLocale], synced by `LocalizationCubit`). The
/// **numerals stay Western** on purpose — the coupon stubs and the price
/// digits render amounts in HeroDigits (Fredoka), which ships no Arabic-Indic
/// glyphs, so forcing `٠١٢٣` there would render tofu.
class Formatters {
  Formatters._();

  static String get _appLanguage => Intl.defaultLocale ?? 'en';

  static bool _isArabic(String languageCode) => languageCode.startsWith('ar');

  /// Between two short parts of one line ("Home · Salmiya", "Tomorrow ·
  /// 10:00 – 12:00"); the same in both languages.
  static const String middot = ' · ';

  /// Localized currency label: `KD` (en) ↔ `د.ك` (ar).
  static String get currency => currencyIn(_appLanguage);

  /// [currency] in [languageCode] whatever the app shows — for a document
  /// written in a language of the customer's choice (the invoice PDF).
  static String currencyIn(String languageCode) =>
      _isArabic(languageCode) ? 'د.ك' : 'KD';

  /// 3-decimal amount without a currency label (for digit-font display). Western
  /// digits — see the class note.
  static String amount(double v) => v.toStringAsFixed(3);

  /// Price with the localized currency label. Arabic places the label AFTER the
  /// amount (`12.500 د.ك`); English before (`KD 12.500`). Money the customer
  /// compares in a line of its own goes through `HeroMoneyText` (one LTR run).
  static String price(double v) => priceOf(amount(v));

  /// [price] around an amount already written out (e.g. the number slot of a
  /// `RollingNumberText`).
  static String priceOf(String amount) =>
      _isArabic(_appLanguage) ? '$amount $currency' : '$currency $amount';

  /// Price for a run laid out in `Directionality.ltr` (tabular money): the
  /// label always leads, so it reads `KD 12.500` / `د.ك 12.500` — in Arabic
  /// the label sits right of the amount, where [price] inside an RTL
  /// sentence puts it on the left (see [priceInline]).
  static String priceLtr(double v) => priceLtrIn(_appLanguage, v);

  /// [priceLtr] in [languageCode] whatever the app shows (see [currencyIn]):
  /// the invoice PDF reads its money the way the app's columns do.
  static String priceLtrIn(String languageCode, double v) =>
      '${currencyIn(languageCode)} ${amount(v)}';

  /// Money inside a sentence on a page whose money columns go through
  /// `HeroMoneyText` (the invoice: "KD 0.899 each" under a line total, "You
  /// saved KD 1.250" under the receipt's total): [priceLtr] in its own
  /// isolate, so Arabic reads `د.ك 0.899` like the column beside it.
  static String priceInline(double v) => isolate(priceLtr(v));

  static final Map<String, DateFormat> _dateTimeFormats =
      <String, DateFormat>{};

  /// "21 Sept 2026, 10:42" in [languageCode]'s own pattern (Arabic keeps its
  /// month names and ص / م), Western digits like every other number in the
  /// app; empty without a date. The format is cached per language because
  /// `DateFormat` parses its skeleton on construction and a list builds
  /// dozens of rows.
  static String dateTime(String languageCode, DateTime? at) {
    if (at == null) return '';
    final format = _dateTimeFormats.putIfAbsent(
      languageCode,
      () => DateFormat.yMMMd(languageCode).add_jm()..useNativeDigits = false,
    );
    return format.format(at.toLocal());
  }

  static final Map<String, DateFormat> _clockFormats = <String, DateFormat>{};

  /// A clock time, "5:55 PM", in [languageCode]'s own `jm` pattern with
  /// Western digits (Arabic reads "1:25 ص"; the same policy as
  /// [dateTime]); [at] is shown in local time. Cached per language, like
  /// [dateTime].
  static String clock(String languageCode, DateTime at) {
    final format = _clockFormats.putIfAbsent(
      languageCode,
      () => DateFormat.jm(languageCode)..useNativeDigits = false,
    );
    return format.format(at.toLocal());
  }

  /// First-strong isolate markers: `U+2068 … U+2069`. Text between them is
  /// laid out on its own, so an Arabic paragraph cannot pull a neutral
  /// character out of a Latin run.
  static const String _isolateStart = '\u2068';
  static const String _isolateEnd = '\u2069';

  /// [text] kept in its own direction inside a sentence of the other one.
  ///
  /// Without this, RTL bidi moves the neutral characters of a Latin run to
  /// the visual edge of the paragraph: `+96550001110` reads `96550001110+`,
  /// `10:00 - 12:00` reads `12:00 - 10:00`, and an order number runs into
  /// the date beside it. Empty text passes through unchanged so a caller can
  /// isolate an optional field without producing two stray markers.
  static String isolate(String text) =>
      text.isEmpty ? text : '$_isolateStart$text$_isolateEnd';

  /// "Tue, 22 Sept 2026" in [languageCode]'s own pattern (Arabic keeps its
  /// day and month names), Western digits; empty without a date.
  static String date(String languageCode, DateTime? at) {
    if (at == null) return '';
    final format = _dateFormats.putIfAbsent(
      languageCode,
      () => DateFormat.yMMMEd(languageCode)..useNativeDigits = false,
    );
    return format.format(at.toLocal());
  }

  static final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};

  /// "22 Sept" in [languageCode]'s own pattern (Arabic keeps its month
  /// names), Western digits — a date near enough to need no year (a renewal,
  /// the last day of a membership); empty without a date.
  static String dayMonth(String languageCode, DateTime? at) {
    if (at == null) return '';
    final format = _dayMonthFormats.putIfAbsent(
      languageCode,
      () => DateFormat.MMMd(languageCode)..useNativeDigits = false,
    );
    return format.format(at.toLocal());
  }

  static final Map<String, DateFormat> _dayMonthFormats =
      <String, DateFormat>{};

  static String distance(double km) => km < 1
      ? 'home.distance_m'.tr(namedArgs: {'count': '${(km * 1000).round()}'})
      : 'home.distance_km'.tr(namedArgs: {'count': km.toStringAsFixed(1)});

  static String sold(int n) {
    if (n >= 1000) {
      return 'home.sold_k'.tr(
        namedArgs: {'count': (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)},
      );
    }
    return 'home.sold_count'.tr(namedArgs: {'count': '$n'});
  }

  static String rating(double r) => r.toStringAsFixed(1);
}
