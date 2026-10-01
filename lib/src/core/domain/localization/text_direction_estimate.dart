/// The direction a piece of text reads in, estimated from its WORDS — not
/// the app locale (an English-locale customer may type Arabic, an Arabic
/// one English) and not the first strong character ("Almarai حليب كامل
/// الدسم" is an Arabic sentence that starts with a Latin brand). Like intl's
/// `estimateDirectionOfText`: right-to-left when more than 40 % of the words
/// that carry a letter are Arabic / Hebrew. Used by the assistant and the
/// rider chat.
abstract final class TextDirectionEstimate {
  static const double _rtlThreshold = 0.4;

  /// `true` right-to-left, `false` left-to-right, `null` when [text] has no
  /// letter at all (digits, punctuation, emoji) — follow the app then.
  static bool? isRtl(String text) {
    var rtlWords = 0;
    var letterWords = 0;
    for (final word in text.split(_space)) {
      final rtl = _wordIsRtl(word);
      if (rtl == null) continue;
      letterWords++;
      if (rtl) rtlWords++;
    }
    if (letterWords == 0) return null;
    return rtlWords > letterWords * _rtlThreshold;
  }

  static final RegExp _space = RegExp(r'\s+');

  // A word's direction is its first strong letter.
  static bool? _wordIsRtl(String word) {
    for (final rune in word.runes) {
      if (_isRtl(rune)) return true;
      if (_isLtr(rune)) return false;
    }
    return null;
  }

  // Hebrew, Arabic, Syriac, Thaana, NKo, Samaritan … and the Arabic
  // presentation forms.
  static bool _isRtl(int rune) =>
      (rune >= 0x0590 && rune <= 0x08FF) ||
      (rune >= 0xFB1D && rune <= 0xFDFF) ||
      (rune >= 0xFE70 && rune <= 0xFEFF);

  // Latin letters (basic + Latin-1 / extended) and the other left-to-right
  // alphabets up to the Arabic block.
  static bool _isLtr(int rune) =>
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      (rune >= 0x00C0 && rune <= 0x024F && rune != 0x00D7 && rune != 0x00F7) ||
      (rune >= 0x0370 && rune <= 0x058F);
}
