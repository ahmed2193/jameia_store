import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import 'assistant_word_pace.dart';

/// THE assistant text reveal, local mode (docs/motion §9.6 §0 rule 4,
/// §2.3): known text — a buddy line, the greeting's message, a tour demo,
/// the voice transcript — shows word by word ([AssistantWordPace]), each new
/// word fading in over [AppMotion.fast] through its colour's alpha only (a
/// paint change: the paragraph is laid out once, whole, so the box has its
/// final size from the first frame and nothing around it moves). Shown
/// words never animate again, and once every word is in the text is plain.
/// Then [onDone]. (Its network mode — the chat's stream — is
/// `AssistantStreamReveal`, on the same tokens.)
///
/// It plays on mount when [play]; `false` shows the text whole at once (no
/// [onDone]). [appendOnly] (the live voice transcript): a new [text] fades
/// in only its new trailing words, at the local pace; the words it had
/// already — kept or rewritten by the recogniser — show at once, so a
/// correction never flickers. [AssistantWordReveal.at] follows an outside
/// [progress] `0..1` (a tour demo's timeline) instead of its own clock.
/// Reduced motion: the text is whole at once and [onDone] comes after the
/// first frame. Screen readers get the whole text from the start.
class AssistantWordReveal extends StatefulWidget {
  const AssistantWordReveal({
    super.key,
    required this.text,
    required this.style,
    this.play = true,
    this.appendOnly = false,
    this.onDone,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDirection,
    this.textWidthBasis,
  }) : progress = null;

  const AssistantWordReveal.at({
    super.key,
    required this.text,
    required this.style,
    required double this.progress,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDirection,
    this.textWidthBasis,
  }) : play = true,
       appendOnly = false,
       onDone = null;

  final String text;
  final TextStyle style;
  final bool play;

  /// A changed [text] reveals only its new trailing words.
  final bool appendOnly;
  final VoidCallback? onDone;

  /// The reveal's progress from outside, `0..1`; `null` = its own clock.
  final double? progress;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextWidthBasis? textWidthBasis;

  @override
  State<AssistantWordReveal> createState() => _AssistantWordRevealState();
}

class _AssistantWordRevealState extends State<AssistantWordReveal>
    with SingleTickerProviderStateMixin {
  late List<String> _words = AssistantWordPace.split(widget.text);

  /// Words before this index show whole; the rest follow [_tail].
  int _from = 0;
  late AssistantWordPace _tail = AssistantWordPace.of(_words);
  late final AnimationController _clock = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  @override
  void didUpdateWidget(AssistantWordReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    final words = AssistantWordPace.split(widget.text);
    _from = widget.appendOnly ? math.min(_words.length, words.length) : 0;
    _words = words;
    _tail = AssistantWordPace.of(words.sublist(_from));
    _start();
  }

  void _start() {
    if (widget.progress != null) return;
    final whole =
        !widget.play || MotionGuard.reduced(context) || _tail.words.isEmpty;
    if (whole) {
      _clock.value = 1;
      if (!widget.play) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
      return;
    }
    _clock.duration = _tail.length;
    // Completes only when the reveal ends by itself (not on dispose).
    _clock.forward(from: 0).then((_) {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// The text [share] of the way through: every word in (and plain) at
  /// `1`, otherwise each word at its own alpha.
  InlineSpan _span(double share) {
    if (share >= 1) return TextSpan(text: widget.text);
    final elapsed = _tail.length * share;
    final color =
        widget.style.color ?? DefaultTextStyle.of(context).style.color;
    return TextSpan(
      children: [
        for (final (index, word) in _words.indexed)
          TextSpan(
            text: word,
            style: index < _from
                ? null
                : TextStyle(
                    color: color?.withValues(
                      alpha: color.a * _tail.alphaAt(index - _from, elapsed),
                    ),
                  ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final outside = widget.progress;
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => Text.rich(
        _span(
          outside == null
              ? _clock.value
              : MotionGuard.reduced(context)
              ? 1
              : outside.clamp(0.0, 1.0),
        ),
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        textWidthBasis: widget.textWidthBasis,
      ),
    );
  }
}
