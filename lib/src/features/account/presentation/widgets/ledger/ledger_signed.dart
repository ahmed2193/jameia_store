import '../../../../../core/utils/formatters.dart';

/// Signed amounts of the history rows and the balance delta, laid out for
/// the reading direction: the sign stays glued to the digits and the digits
/// run left-to-right inside an Arabic line, while the currency follows the
/// line ("+KD 1.250" in English, "د.ك +1.250" read right-to-left in Arabic).
abstract final class LedgerSigned {
  static const String _plus = '+';

  /// A real minus sign (U+2212), as wide as the plus.
  static const String _minus = '−';

  static String sign(num value) => value < 0 ? _minus : _plus;

  /// "+120" / "−40", isolated as one left-to-right run under [rtl].
  static String number(int value, {required bool rtl}) =>
      _ltr('${sign(value)}${value.abs()}', rtl: rtl);

  /// Signed dinar: "+KD 1.250" in English, "+1.250 د.ك" (digits kept as one
  /// left-to-right run) in Arabic.
  static String money(double kd, {required bool rtl}) {
    final amount = Formatters.amount(kd.abs());
    return rtl
        ? '${_ltr('${sign(kd)}$amount', rtl: true)} ${Formatters.currency}'
        : '${sign(kd)}${Formatters.currency} $amount';
  }

  static String _ltr(String run, {required bool rtl}) =>
      rtl ? Formatters.isolate(run) : run;
}
