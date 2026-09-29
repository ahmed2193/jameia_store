import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import '../assistant_stream_pace.dart';
import '../assistant_word_pace.dart';
import 'assistant_stream_reveal_scope.dart';

/// The word reveal's NETWORK mode (docs/motion §9.6 §2.3) around a reply
/// that streams in this session: the words of each flush arrive evenly over
/// the next flush window, each fading in over [AppMotion.fast] by its span
/// colour only ([AssistantStreamPace]; the text blocks read it through
/// [AssistantStreamRevealScope]); a burst over the lag limit, and whatever
/// is left when the stream ends, comes in one fade. The caret fades out
/// over `fast` once [streaming] turns off, then goes.
///
/// Decided at mount: a reply that was not streaming then (history, a
/// stored reply) is plain text, with no clock at all. The ticker runs only
/// while a word is still fading. Reduced motion: words are whole the moment
/// they arrive, and the caret goes at once.
class AssistantStreamReveal extends StatefulWidget {
  const AssistantStreamReveal({
    super.key,
    required this.richText,
    required this.streaming,
    required this.child,
  });

  final AssistantRichText richText;
  final bool streaming;
  final Widget child;

  /// How many reveal words [block] holds (`AssistantWordPace.split` per
  /// run): the one count both the reveal and the blocks use.
  static int wordsInBlock(AssistantRichBlock block) {
    var count = 0;
    for (final run in block.runs) {
      count += AssistantWordPace.split(run.text).length;
    }
    return count;
  }

  static int wordsIn(AssistantRichText text) {
    var count = 0;
    for (final block in text.blocks) {
      count += wordsInBlock(block);
    }
    return count;
  }

  @override
  State<AssistantStreamReveal> createState() => _AssistantStreamRevealState();
}

class _AssistantStreamRevealState extends State<AssistantStreamReveal>
    with TickerProviderStateMixin {
  late final bool _active = widget.streaming;
  final AssistantStreamPace _pace = AssistantStreamPace();
  final ValueNotifier<Duration> _clock = ValueNotifier<Duration>(Duration.zero);
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _caret = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMotion.fast,
  );
  late final CurvedAnimation _caretOpacity = CurvedAnimation(
    parent: _caret,
    curve: AppMotion.linear,
    reverseCurve: AppMotion.exit.flipped,
  );

  /// The clock: time banked while the ticker slept, plus its last tick.
  Duration _epoch = Duration.zero;
  Duration _elapsed = Duration.zero;
  bool _caretShown = true;
  bool _started = false;

  Duration get _now => _epoch + _elapsed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_active) return;
    _pace.immediate = MotionGuard.reduced(context);
    if (_started) return;
    _started = true;
    _reveal();
  }

  @override
  void didUpdateWidget(AssistantStreamReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active) return;
    if (!identical(oldWidget.richText, widget.richText)) _reveal();
    if (oldWidget.streaming && !widget.streaming) _finish();
  }

  void _reveal() {
    _pace.reveal(AssistantStreamReveal.wordsIn(widget.richText), _now);
    if (!widget.streaming) _finish();
    _tick();
  }

  /// The stream ended: the rest in one fade, the caret fades away.
  void _finish() {
    _pace.finish(_now);
    _tick();
    if (!_caretShown || _caret.status == AnimationStatus.reverse) return;
    if (MotionGuard.reduced(context)) {
      _caret.value = 0;
      _caretShown = false;
      return;
    }
    _caret.reverse().whenComplete(() {
      if (mounted && _caretShown) setState(() => _caretShown = false);
    });
  }

  /// Runs the clock while a word still fades.
  void _tick() {
    _clock.value = _now;
    if (_pace.settledAt(_now) || _ticker.isActive) return;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    _clock.value = _now;
    if (!_pace.settledAt(_now)) return;
    _ticker.stop();
    _epoch += _elapsed;
    _elapsed = Duration.zero;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _caretOpacity.dispose();
    _caret.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;
    return AssistantStreamRevealScope(
      pace: _pace,
      clock: _clock,
      caret: _caretOpacity,
      caretShown: widget.streaming || _caretShown,
      child: widget.child,
    );
  }
}
