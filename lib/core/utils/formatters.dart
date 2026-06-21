/// Lightweight formatting helpers (currency, distance, counts).
///
/// KeeTa shows region currency; the clone uses Kuwaiti Dinar (KD, 3 decimals) as
/// the demo currency to match the GCC market in the reference.
class Formatters {
  Formatters._();

  static const String currency = 'KD';

  static String price(double v) => '$currency ${v.toStringAsFixed(3)}';

  /// Compact price without currency (for digit-font display).
  static String amount(double v) => v.toStringAsFixed(3);

  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  static String sold(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k+ sold';
    return '$n sold';
  }

  static String rating(double r) => r.toStringAsFixed(1);
}
