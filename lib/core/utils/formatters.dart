import 'package:easy_localization/easy_localization.dart';

/// Lightweight formatting helpers (currency, distance, counts).
///
/// KeeTa shows region currency; the clone uses Kuwaiti Dinar (KD / د.ك, 3
/// decimals) as the demo currency to match the GCC market in the reference.
///
/// Locale awareness: the currency **label** and its placement follow the active
/// locale (via [Intl.defaultLocale], synced by `LocalizationCubit`). The
/// **numerals stay Western** on purpose — PriceText and the coupon stubs render
/// amounts in the MT Digital Display digit font, which ships no Arabic-Indic
/// glyphs, so forcing `٠١٢٣` there would render tofu.
class Formatters {
  Formatters._();

  static bool get _isAr => (Intl.defaultLocale ?? 'en').startsWith('ar');

  /// Localized currency label: `KD` (en) ↔ `د.ك` (ar).
  static String get currency => _isAr ? 'د.ك' : 'KD';

  /// 3-decimal amount without a currency label (for digit-font display). Western
  /// digits — see the class note.
  static String amount(double v) => v.toStringAsFixed(3);

  /// Price with the localized currency label. Arabic places the label AFTER the
  /// amount (`12.500 د.ك`); English before (`KD 12.500`). For the digit-font
  /// pill use [PriceText], which localizes the symbol and mirrors under RTL.
  static String price(double v) =>
      _isAr ? '${amount(v)} $currency' : '$currency ${amount(v)}';

  static String distance(double km) => km < 1
      ? 'home.distance_m'.tr(namedArgs: {'count': '${(km * 1000).round()}'})
      : 'home.distance_km'.tr(namedArgs: {'count': km.toStringAsFixed(1)});

  static String sold(int n) {
    if (n >= 1000) {
      return 'home.sold_k'.tr(namedArgs: {
        'count': (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1),
      });
    }
    return 'home.sold_count'.tr(namedArgs: {'count': '$n'});
  }

  static String rating(double r) => r.toStringAsFixed(1);
}
