/// Pure digit normalisation shared by every rule that reads typed numbers
/// (phone, one-time code, quantities).
///
/// Arabic keyboards type Arabic-Indic (`٠١٢٣٤٥٦٧٨٩`, U+0660–U+0669) or, on
/// Persian layouts, Extended Arabic-Indic (`۰۱۲۳۴۵۶۷۸۹`, U+06F0–U+06F9)
/// digits. The backend only accepts ASCII `0-9`, and Dart's `\d` does not
/// match the other two sets, so they are mapped before any `\D` filtering.
library;

const int _asciiZero = 0x30;
const int _asciiNine = 0x39;
const int _arabicIndicZero = 0x0660;
const int _arabicIndicNine = 0x0669;
const int _persianZero = 0x06F0;
const int _persianNine = 0x06F9;

/// The ASCII code unit for a digit in any of the three sets; `null` for
/// anything that is not a digit.
int? asciiDigitUnit(int unit) {
  if (unit >= _asciiZero && unit <= _asciiNine) return unit;
  if (unit >= _arabicIndicZero && unit <= _arabicIndicNine) {
    return _asciiZero + unit - _arabicIndicZero;
  }
  if (unit >= _persianZero && unit <= _persianNine) {
    return _asciiZero + unit - _persianZero;
  }
  return null;
}

/// Only the ASCII digits of [raw] (after mapping the other digit sets).
String asciiDigitsOnly(String raw) =>
    String.fromCharCodes(raw.codeUnits.map(asciiDigitUnit).whereType<int>());
