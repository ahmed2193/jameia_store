import 'dart:math' as math;

/// When each letter of a line shows as the mascot "types" it: a steady hand
/// with a little unevenness, a beat between words and a longer one after a
/// comma or a full stop — so it reads like someone typing, not like a
/// progress bar. The unevenness is seeded by the line itself, so a line
/// always types the same way.
class AssistantBuddyTypingRhythm {
  AssistantBuddyTypingRhythm(List<String> letters) : _at = _schedule(letters);

  static const int _letterMs = 40;
  static const int _jitterMs = 15;
  static const int _spaceMs = 70;
  static const int _pauseMs = 220;
  static const Set<String> _pauses = {'.', ',', '!', '?', ':', '…', '،', '؟'};

  /// Milliseconds after the start at which each letter shows.
  final List<int> _at;

  /// How long the whole line takes.
  Duration get length => Duration(milliseconds: _at.isEmpty ? 0 : _at.last);

  /// How many letters show [elapsed] into the typing.
  int shownAt(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    var count = 0;
    while (count < _at.length && _at[count] <= ms) {
      count++;
    }
    return count;
  }

  static List<int> _schedule(List<String> letters) {
    final random = math.Random(letters.join().hashCode);
    final at = <int>[];
    var elapsed = 0;
    String? previous;
    for (final letter in letters) {
      elapsed += switch (letter) {
        _ when _pauses.contains(previous) => _pauseMs,
        ' ' => _spaceMs,
        _ => _letterMs + random.nextInt(_jitterMs * 2 + 1) - _jitterMs,
      };
      at.add(elapsed);
      previous = letter;
    }
    return at;
  }
}
