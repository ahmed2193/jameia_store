import 'package:flutter/painting.dart';

/// Emphasis inside one translated sentence: the formatted amount or time in
/// "Arrives around 1:25 PM" / "KD 0.200 saved with SAVE" set in its own
/// style while the words stay plain, without splitting the sentence into
/// separate translation keys (word order differs between languages).
abstract final class SpanEmphasis {
  /// [text] as one span whose first occurrence of [part] carries
  /// [emphasis]; the rest inherits the enclosing style. When [part] is
  /// empty or not in [text], a plain span of [text]. The plain text of the
  /// result is always [text], so `find.text` and screen readers see the
  /// sentence unchanged.
  static TextSpan around(
    String text,
    String part, {
    required TextStyle emphasis,
  }) {
    final at = part.isEmpty ? -1 : text.indexOf(part);
    if (at < 0) return TextSpan(text: text);
    final end = at + part.length;
    return TextSpan(
      children: <InlineSpan>[
        if (at > 0) TextSpan(text: text.substring(0, at)),
        TextSpan(text: part, style: emphasis),
        if (end < text.length) TextSpan(text: text.substring(end)),
      ],
    );
  }
}
