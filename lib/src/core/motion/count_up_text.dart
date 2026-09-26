import 'package:flutter/material.dart';

import 'motion.dart';

/// COUNT-UP — renders [value] through [format], rolling from the previously
/// shown value to the new one over [AppMotion.countUp] (a points balance that
/// lands, a per-month price that changes with the picked plan). The first
/// build counts up from [from] when given, else shows [value] at once.
/// Reduced motion → the final text immediately.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.from,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final double value;

  /// Turns the in-between number into the text (e.g. `Formatters.price`).
  final String Function(double value) format;
  final double? from;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  late double _begin = widget.from ?? widget.value;

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _begin = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.format(widget.value),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
    // Read once, as the final value: the text under the label (settled or
    // in between) is left out of the semantics tree.
    return Semantics(
      label: widget.format(widget.value),
      excludeSemantics: true,
      child: MotionGuard.reduced(context) || _begin == widget.value
          ? text
          : TweenAnimationBuilder<double>(
              // [_begin] only seeds the first count: a new target while one
              // is running continues from the number on screen.
              tween: Tween<double>(begin: _begin, end: widget.value),
              duration: AppMotion.countUp,
              curve: AppMotion.emphasizedDecelerate,
              builder: (context, value, _) => Text(
                widget.format(value),
                style: widget.style,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
              ),
            ),
    );
  }
}
