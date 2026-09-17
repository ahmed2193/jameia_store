import 'package:equatable/equatable.dart';

/// A customer phone number as the login flow handles it: a dial code plus the
/// local digits the user typed. Jameia serves Kuwait, so the only constructor
/// is [PhoneNumber.kuwait]; the entity owns the parsing and validity rules and
/// the E.164 form the backend receives.
class PhoneNumber extends Equatable {
  const PhoneNumber.kuwait(this.localDigits) : dialCode = kuwaitDialCode;

  static const String kuwaitDialCode = '+965';

  /// Flag shown next to the dial code (not translatable text).
  static const String kuwaitFlag = '🇰🇼';
  static const String _kuwaitCountryCode = '965';

  /// Kuwait mobile numbers are 8 digits.
  static const int kuwaitLocalLength = 8;

  static const PhoneNumber empty = PhoneNumber.kuwait('');

  static final RegExp _nonDigits = RegExp(r'\D');

  /// Builds a Kuwait number from anything the user typed or pasted: drops
  /// separators, a leading `+965` / `965` / `00965`, and caps the local part
  /// at [kuwaitLocalLength] digits.
  factory PhoneNumber.parseKuwait(String raw) {
    var digits = raw.replaceAll(_nonDigits, '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length > kuwaitLocalLength &&
        digits.startsWith(_kuwaitCountryCode)) {
      digits = digits.substring(_kuwaitCountryCode.length);
    }
    if (digits.length > kuwaitLocalLength) {
      digits = digits.substring(0, kuwaitLocalLength);
    }
    return PhoneNumber.kuwait(digits);
  }

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

  static bool _isAsciiDigit(int unit) => unit >= 0x30 && unit <= 0x39;

  @override
  List<Object?> get props => [dialCode, localDigits];
}
