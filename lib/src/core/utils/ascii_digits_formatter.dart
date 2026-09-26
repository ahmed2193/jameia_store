import 'package:flutter/services.dart';

import '../domain/text/ascii_digits.dart';

/// Digits-only [TextInputFormatter] that also accepts Arabic keyboards: every
/// Arabic-Indic (`٠-٩`) or Persian (`۰-۹`) digit becomes its ASCII twin, every
/// other character is dropped (what `FilteringTextInputFormatter.digitsOnly`
/// would silently throw away for an Arabic keyboard is kept as a digit).
///
/// [normalize] runs a domain rule over the digits (e.g. drop a pasted `+965`
/// and cap at a local number); [maxLength] caps the result. The caret keeps
/// its place among the digits unless the rule rewrote the run, then it goes
/// to the end.
class AsciiDigitsFormatter extends TextInputFormatter {
  const AsciiDigitsFormatter({this.maxLength, this.normalize});

  /// Longest allowed result; `null` = no cap.
  final int? maxLength;

  /// Rule applied to the digit run before the cap.
  final String Function(String digits)? normalize;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final caretAt = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : text.length;
    final units = <int>[];
    var caret = 0;
    for (var i = 0; i < text.length; i++) {
      final ascii = asciiDigitUnit(text.codeUnitAt(i));
      if (ascii == null) continue;
      units.add(ascii);
      if (i < caretAt) caret++;
    }
    final digits = String.fromCharCodes(units);
    var result = normalize?.call(digits) ?? digits;
    final cap = maxLength;
    if (cap != null && result.length > cap) result = result.substring(0, cap);
    if (result == text) return newValue;
    if (!digits.startsWith(result) || caret > result.length) {
      caret = result.length;
    }
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}
