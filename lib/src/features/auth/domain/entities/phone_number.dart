import 'package:equatable/equatable.dart';

import '../../../../core/domain/text/ascii_digits.dart';

/// A customer phone number as the login flow handles it: a dial code plus the
/// local digits the user typed. Hero serves Kuwait, so the only constructor
/// is [PhoneNumber.kuwait]; the entity owns the parsing and validity rules and
/// the E.164 form the backend receives.
class PhoneNumber extends Equatable {
  const PhoneNumber.kuwait(this.localDigits) : dialCode = kuwaitDialCode;

  static const String kuwaitDialCode = '+965';

  static const String _kuwaitCountryCode = '965';
  static const String _internationalPrefix = '00';

  /// Kuwait mobile numbers are 8 digits.
  static const int kuwaitLocalLength = 8;

  static const PhoneNumber empty = PhoneNumber.kuwait('');

  /// Builds a Kuwait number from anything the user typed, pasted or had
  /// autofilled: Arabic-Indic / Persian digits become ASCII, separators go,
  /// a leading `+965` / `965` / `00965` is dropped once the input is longer
  /// than a local number, and the local part is capped at
  /// [kuwaitLocalLength] digits.
  factory PhoneNumber.parseKuwait(String raw) {
    var digits = asciiDigitsOnly(raw);
    if (digits.length > kuwaitLocalLength &&
        digits.startsWith(_internationalPrefix)) {
      digits = digits.substring(_internationalPrefix.length);
    }
    if (digits.length > kuwaitLocalLength &&
        digits.startsWith(_kuwaitCountryCode)) {
      digits = digits.substring(_kuwaitCountryCode.length);
    }
    if (digits.length > kuwaitLocalLength) {
      digits = digits.substring(0, kuwaitLocalLength);
    }
    return PhoneNumber.kuwait(digits);
  }

  /// The local digits [raw] parses to — the rule the phone input applies on
  /// every keystroke, so the field never holds more than a local number.
  static String localDigitsOf(String raw) =>
      PhoneNumber.parseKuwait(raw).localDigits;

  final String dialCode;
  final String localDigits;

  bool get isEmpty => localDigits.isEmpty;

  /// Exactly [kuwaitLocalLength] digits, nothing else.
  bool get isValid =>
      localDigits.length == kuwaitLocalLength &&
      localDigits.codeUnits.every(_isAsciiDigit);

  /// What the API receives (`+96512345678`).
  String get e164 => '$dialCode$localDigits';

  /// What the user sees (`+965 12345678`).
  String get display => '$dialCode $localDigits';

  static bool _isAsciiDigit(int unit) => asciiDigitUnit(unit) == unit;

  @override
  List<Object?> get props => [dialCode, localDigits];
}
