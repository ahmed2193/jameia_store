import '../../../../core/motion/motion.dart';
import 'assistant_motion.dart';

/// The pace of the chat's streamed reply — the NETWORK mode of the word
/// reveal (docs/motion §9.6 §2.3). The chat cubit draws the stream at most
/// once per [AssistantMotion.streamFlush] and only in whole words; this
/// spreads the words of each flush evenly over the next flush window, so the
/// reply flows instead of jumping by bursts and trails the network by about
/// one window. Each word then fades in over [AppMotion.fast].
///
/// Never holds text back: when more than [AssistantMotion.streamMaxLag] of
/// words wait (a burst after a tool call), every waiting word starts now —
/// one fade — and [finish] (`message_end`, a stop, an error) does the same
/// with whatever is left. [immediate] (reduced motion): every word is whole
/// the moment it is known.
///
/// Times are an outside clock's (the reveal widget's ticker); words are
/// counted by ordinal across the whole reply (`AssistantWordPace.split` per
/// text run).
class AssistantStreamPace {
  AssistantStreamPace({this.immediate = false});

  /// Reduced motion: no fades, no pacing.
  bool immediate;

  /// When each known word starts fading in, by ordinal (never decreasing).
  final List<Duration> _starts = <Duration>[];

  /// How many words are known.
  int get count => _starts.length;

  Duration get _last => _starts.isEmpty ? Duration.zero : _starts.last;

  /// [words] words are known at [now]. New ones are released evenly over
  /// the next window (after any still waiting from the flush before);
  /// fewer than known (a re-parse) changes nothing.
  void reveal(int words, Duration now) {
    final added = words - _starts.length;
    if (added <= 0) return;
    if (immediate) {
      _starts.addAll(List<Duration>.filled(added, now - AppMotion.fast));
      return;
    }
    final step = AssistantMotion.streamFlush ~/ added;
    var at = _last > now ? _last + step : now;
    for (var i = 0; i < added; i++) {
      _starts.add(at);
      at += step;
    }
    if (_last - now > AssistantMotion.streamMaxLag) _releaseAll(now);
  }

  /// The stream ended: every word still waiting starts now.
  void finish(Duration now) => _releaseAll(now);

  void _releaseAll(Duration now) {
    for (var i = 0; i < _starts.length; i++) {
      if (_starts[i] > now) _starts[i] = now;
    }
  }

  /// How far word [index] has faded in at [now] (`0..1`); an unknown word
  /// is whole.
  double alphaAt(int index, Duration now) {
    if (index < 0 || index >= _starts.length) return 1;
    final since = (now - _starts[index]).inMicroseconds;
    return (since / AppMotion.fast.inMicroseconds).clamp(0.0, 1.0);
  }

  /// Every word up to and including [index] is whole at [now].
  bool settledThrough(int index, Duration now) {
    if (_starts.isEmpty || index < 0) return true;
    final last = index >= _starts.length ? _starts.last : _starts[index];
    return now - last >= AppMotion.fast;
  }

  /// Every known word is whole at [now].
  bool settledAt(Duration now) => settledThrough(_starts.length - 1, now);
}
