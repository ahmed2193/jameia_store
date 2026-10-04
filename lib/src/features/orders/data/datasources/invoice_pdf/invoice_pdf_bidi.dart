/// One word of a mixed-script line, ready to set: in the order it is laid
/// out, its brackets and edge punctuation already turned the way the line
/// reads.
class InvoicePdfWord {
  const InvoicePdfWord(this.text, {required this.arabic});

  final String text;

  /// Set right to left in the Arabic face (the pdf package shapes it);
  /// anything else is set left to right in the Latin face.
  final bool arabic;
}

/// A line of mixed Arabic and Latin / numbers, cut into words in the order
/// they are laid out along [rtl].
class InvoicePdfLine {
  const InvoicePdfLine({required this.rtl, required this.words});

  /// The line's own direction (its first letter's script).
  final bool rtl;
  final List<InvoicePdfWord> words;
}

/// The Unicode bidirectional algorithm at word level, for the invoice PDF.
///
/// The pdf package sets right-to-left text well one word at a time, but in a
/// run of several it misplaces the space between an Arabic word and a
/// number or a Latin word (`صفحة 1 من 1` prints `صفحة1 من1`) and reverses
/// Latin letters inside it (`خصم Pro` prints `خصم orP`). So a mixed line is
/// cut into words and laid out word by word: each word set alone in its own
/// direction, the words ordered as the algorithm orders their runs. Pure
/// Arabic or pure Latin text never comes here — one text run sets it fine.
abstract final class InvoicePdfBidi {
  /// Arabic, its supplement and extension, and the presentation forms.
  static final RegExp _arabic = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Basic Latin letters and the accented ones of Latin-1 and Extended-A/B.
  static final RegExp _latin = RegExp(r'[A-Za-z\u00C0-\u024F]');

  /// Western, Arabic-Indic and Eastern Arabic-Indic digits.
  static const String _digits = r'[0-9\u0660-\u0669\u06F0-\u06F9]';
  static final RegExp _digit = RegExp(_digits);
  static final RegExp _space = RegExp(r'\s+');

  /// From the first digit to the last one ("10:42", "2.000", "3" of "3,").
  static final RegExp _number = RegExp('$_digits(?:.*$_digits)?');

  static const Map<String, String> _mirror = {
    '(': ')',
    ')': '(',
    '[': ']',
    ']': '[',
    '{': '}',
    '}': '{',
    '<': '>',
    '>': '<',
    '«': '»',
    '»': '«',
  };

  static bool hasArabic(String text) => _arabic.hasMatch(text);

  /// Arabic next to Latin letters or digits: set word by word.
  static bool isMixed(String text) =>
      hasArabic(text) && (_latin.hasMatch(text) || _digit.hasMatch(text));

  /// [text]'s brackets turned around — what right-to-left text needs, as the
  /// pdf package mirrors none.
  static String mirrored(String text) =>
      text.split('').map((char) => _mirror[char] ?? char).join();

  /// [text] as words in layout order. [pageRtl] is the direction of a line
  /// with no letter at all.
  static InvoicePdfLine lineOf(String text, {required bool pageRtl}) {
    final words = text.split(_space).where((word) => word.isNotEmpty).toList();
    final strong = [for (final word in words) _strongOf(word)];
    final rtl =
        strong.firstWhere((dir) => dir != null, orElse: () => null) ?? pageRtl;

    // Numbers take the side of the strong word before them (W2 / W7).
    final resolved = List<bool?>.of(strong);
    bool? before;
    for (var i = 0; i < words.length; i++) {
      if (strong[i] != null) {
        before = strong[i];
      } else if (_digit.hasMatch(words[i])) {
        resolved[i] = before ?? rtl;
      }
    }
    // A lone mark sides with its neighbours when they agree, else the line
    // (N1 / N2).
    for (var i = 0; i < words.length; i++) {
      if (resolved[i] != null) continue;
      final previous = _nearest(resolved, i, -1) ?? rtl;
      final next = _nearest(resolved, i, 1) ?? rtl;
      resolved[i] = previous == next ? previous : rtl;
    }

    final ordered = <InvoicePdfWord>[];
    var i = 0;
    while (i < words.length) {
      // A run against the line's direction reads backwards along it (L2).
      var end = i;
      while (end < words.length && resolved[end] != rtl) {
        end++;
      }
      if (end > i) {
        for (var j = end - 1; j >= i; j--) {
          ordered.add(_wordOf(words[j], rtl: resolved[j]!));
        }
        i = end;
      } else {
        ordered.add(_wordOf(words[i], rtl: resolved[i]!));
        i++;
      }
    }
    return InvoicePdfLine(rtl: rtl, words: ordered);
  }

  /// `true` = Arabic, `false` = Latin, `null` = neither (numbers, marks).
  static bool? _strongOf(String word) {
    if (_arabic.hasMatch(word)) return true;
    if (_latin.hasMatch(word)) return false;
    return null;
  }

  static bool? _nearest(List<bool?> resolved, int from, int step) {
    for (var i = from + step; i >= 0 && i < resolved.length; i += step) {
      final dir = resolved[i];
      if (dir != null) return dir;
    }
    return null;
  }

  /// An Arabic word keeps its letters (the pdf package reverses them) with
  /// its brackets mirrored. A number read right to left keeps its digits
  /// but swaps the marks at its edges ("3," → ",3"), so the comma still
  /// follows it.
  static InvoicePdfWord _wordOf(String word, {required bool rtl}) {
    if (hasArabic(word)) return InvoicePdfWord(mirrored(word), arabic: true);
    if (!rtl || _latin.hasMatch(word)) {
      return InvoicePdfWord(word, arabic: false);
    }
    final number = _number.firstMatch(word);
    final lead = number == null ? word : word.substring(0, number.start);
    final core = number?[0] ?? '';
    final trail = number == null ? '' : word.substring(number.end);
    String flipped(String marks) => mirrored(marks.split('').reversed.join());
    return InvoicePdfWord(
      '${flipped(trail)}$core${flipped(lead)}',
      arabic: false,
    );
  }
}
