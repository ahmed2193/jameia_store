import 'package:equatable/equatable.dart';

/// A stretch of a suggestion's text that matched what the customer typed:
/// [start] inclusive, [end] exclusive, in characters.
class TextMatch extends Equatable {
  const TextMatch(this.start, this.end);

  final int start;
  final int end;

  /// Whether the stretch lies inside a text [length] characters long.
  bool fits(int length) => start >= 0 && start < end && end <= length;

  /// Where the words [typed] start words of [text], whatever the case — the
  /// bold of a Google Maps answer: "sal" in "Sabah Al-Salem" is the start of
  /// "Salem", never the "sal" inside a word; an Arabic word may start after
  /// its article ("سالم" in "السالم"). One stretch per typed word, its first
  /// such place.
  static List<TextMatch> wordStartsIn(String text, String typed) {
    final haystack = text.toLowerCase();
    // Lower-casing may change the length (rare letters): no bold then.
    if (haystack.length != text.length) return const [];
    return [
      for (final word in typed.toLowerCase().split(_spaces))
        if (word.isNotEmpty) ?_firstWordStart(haystack, word),
    ];
  }

  /// [matches] ready to be shown in bold over [text]: those that fit it,
  /// grown to whole words where they start or end inside an Arabic word (a
  /// bold stretch must not cut joined letters apart), in order, those that
  /// overlap or touch merged.
  static List<TextMatch> boldStretchesIn(String text, List<TextMatch> matches) {
    final grown = [
      for (final match in matches)
        if (match.fits(text.length)) match._overArabicWordsOf(text),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <TextMatch>[];
    for (final match in grown) {
      final last = merged.isEmpty ? null : merged.last;
      if (last == null || match.start > last.end) {
        merged.add(match);
      } else if (match.end > last.end) {
        merged.last = TextMatch(last.start, match.end);
      }
    }
    return merged;
  }

  TextMatch _overArabicWordsOf(String text) {
    bool joins(int at) =>
        at >= 0 && at < text.length && _arabicLetter.hasMatch(text[at]);
    var from = start;
    var to = end;
    while (joins(from - 1) && joins(from)) {
      from--;
    }
    while (joins(to - 1) && joins(to)) {
      to++;
    }
    return TextMatch(from, to);
  }

  static TextMatch? _firstWordStart(String text, String word) {
    var at = text.indexOf(word);
    while (at >= 0) {
      if (_startsWord(text, at)) return TextMatch(at, at + word.length);
      at = text.indexOf(word, at + 1);
    }
    return null;
  }

  static bool _startsWord(String text, int at) {
    if (at == 0 || !_wordCharacter.hasMatch(text[at - 1])) return true;
    final article = at - _arabicArticle.length;
    return article >= 0 &&
        text.startsWith(_arabicArticle, article) &&
        (article == 0 || !_wordCharacter.hasMatch(text[article - 1]));
  }

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _wordCharacter = RegExp(
    r'[\p{L}\p{N}\p{M}]',
    unicode: true,
  );
  static const String _arabicArticle = 'ال';

  /// Arabic letters (and their marks) join their neighbours.
  static final RegExp _arabicLetter = RegExp(
    '[\u0610-\u061A\u0620-\u065F\u066E-\u06D3\u06D5-\u06EF\u06FA-\u06FF]',
  );

  @override
  List<Object?> get props => [start, end];
}
