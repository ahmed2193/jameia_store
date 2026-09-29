import 'package:flutter/widgets.dart';

import 'rolling_number.dart';

/// A [RollingNumber] inside a translated phrase — "320 pts", "لديك 12 نقطة",
/// "KD 1.500 / month": [text] turns the formatted number into the whole
/// phrase; the words around the number stay still and only the number
/// rolls when [value] changes (static on the first build, like every
/// member of the family).
///
/// The phrase is one paragraph (it wraps, and keeps the reading order of the
/// surrounding [Directionality]); the number is a baseline-aligned run laid
/// out left-to-right inside it. Screen readers hear the whole phrase once.
class RollingNumberText extends StatelessWidget {
  const RollingNumberText({
    super.key,
    required this.value,
    required this.text,
    this.format = RollingNumber.wholeNumber,
    this.style,
    this.textAlign,
  });

  /// Stands for the number while the phrase is split around it: a
  /// private-use character no translation contains.
  static const String _slot = '\u{E000}';

  final num value;

  /// The phrase around the formatted number, e.g.
  /// `(points) => 'loyalty.points_value'.tr(namedArgs: {'points': points})`.
  final String Function(String number) text;
  final String Function(num value) format;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final phrase = text(_slot);
    final at = phrase.indexOf(_slot);
    final spoken = text(format(value));
    if (at < 0) return Text(spoken, textAlign: textAlign, style: style);
    // One paragraph: the words keep their spaces and bidi order, the number
    // is a baseline-aligned widget inside it.
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: phrase.substring(0, at)),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: RollingNumber(value: value, format: format, style: style),
            ),
            TextSpan(text: phrase.substring(at + _slot.length)),
          ],
        ),
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
