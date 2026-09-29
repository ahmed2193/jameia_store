import 'package:flutter/widgets.dart';

import 'rolling_glyph.dart';

/// THE NUMBER PRIMITIVE (docs/motion §9.4 #3-#4, D13 / D20) — every amount
/// of money, points or items the customer watches change: shows [value]
/// through [format] and, when the value changes, rolls only the characters
/// that changed (the rest stay still), up for a rise and down for a drop
/// (the direction comes from the delta), over `AppMotion.medium`. The first
/// build is static: a balance, a count or a badge never "counts up" on open.
/// Digits are tabular so the width does not jitter, the run is laid out
/// left-to-right even in Arabic (numbers read LTR), and screen readers get
/// the final text once, not every glyph. Reduced motion → a fast cross-fade
/// of the changed glyphs; animations off → an instant swap.
///
/// The family: [RollingNumber] for a bare number (a stepper count, a badge,
/// a balance); `RollingNumberText` when the number sits inside a translated
/// phrase ("320 pts", "You have 12 points"); `HeroMoneyText(rolling: true)`
/// for a price. `FlipValue` is for labels and time, `CountUpText` only for
/// an amount the customer just earned.
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.format = wholeNumber,
    this.style,
  });

  final num value;

  /// Turns the value into its text (e.g. `(v) => Formatters.price(v)`); by
  /// default the whole number ([wholeNumber]).
  final String Function(num value) format;
  final TextStyle? style;

  /// The default [format]: a count, rounded to a whole number ("12").
  static String wholeNumber(num value) => '${value.round()}';

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  int _trend = 0;

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.value - oldWidget.value;
    if (delta != 0) _trend = delta > 0 ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.format(widget.value);
    final glyphs = text.characters.toList(growable: false);
    final style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .copyWith(fontFeatures: _tabular);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < glyphs.length; i++)
                  // Slots are keyed from the END so "9.999" → "10.000" keeps
                  // the units aligned and rolls the right places.
                  RollingGlyph(
                    key: ValueKey<int>(glyphs.length - i),
                    glyph: glyphs[i],
                    trend: _trend,
                    style: style,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
