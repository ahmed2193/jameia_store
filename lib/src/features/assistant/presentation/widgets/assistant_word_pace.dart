import '../../../../core/motion/motion.dart';
import 'assistant_motion.dart';

/// The pace of a whole-word reveal of known text (docs/motion §9.6 §2.3,
/// local mode): [words] are the text's whitespace-delimited tokens (each
/// keeps the spaces after it, so the words joined give the text back);
/// word `i` starts fading in `i × step` after the first and takes
/// [AppMotion.fast]. The step is `revealMax / words`, kept between
/// `wordStepMin` and `wordStepMax`: a long line goes faster per word, and
/// no line takes much more than `revealMax`. Never per letter, so an Arabic
/// word keeps its joined forms and a price shows whole.
class AssistantWordPace {
  AssistantWordPace(String text) : words = split(text);

  /// The pace of words already split (e.g. only the new tail of a text).
  AssistantWordPace.of(this.words);

  static final RegExp _word = RegExp(r'\s*\S+\s*');

  final List<String> words;

  /// [text]'s whole-word tokens, spaces kept: joined they give [text] back
  /// (minus nothing but a text that is only spaces). The one tokenizer of
  /// both reveal modes.
  static List<String> split(String text) => [
    for (final match in _word.allMatches(text)) match.group(0)!,
  ];

  /// Time between two words starting.
  Duration get step {
    if (words.isEmpty) return Duration.zero;
    final even = AssistantMotion.revealMax.inMicroseconds ~/ words.length;
    return Duration(
      microseconds: even.clamp(
        AssistantMotion.wordStepMin.inMicroseconds,
        AssistantMotion.wordStepMax.inMicroseconds,
      ),
    );
  }

  /// The whole reveal: the last word starts, then fades in.
  Duration get length => words.isEmpty
      ? Duration.zero
      : step * (words.length - 1) + AppMotion.fast;

  /// How far word [index] has faded in [elapsed] into the reveal (`0..1`).
  double alphaAt(int index, Duration elapsed) {
    final fade = AppMotion.fast.inMicroseconds;
    final since = elapsed.inMicroseconds - step.inMicroseconds * index;
    return (since / fade).clamp(0.0, 1.0);
  }
}
