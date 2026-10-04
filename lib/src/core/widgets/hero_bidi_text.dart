import 'package:flutter/widgets.dart';

import '../domain/localization/text_direction_estimate.dart';

/// Text that reads in its own direction but sits where the layout's text
/// sits — for content the store or the customer wrote (product names and
/// sizes, addresses, file names), which is often in the other script.
///
/// A Latin "2 Liter" in the Arabic app stays "2 Liter" (not "Liter 2"), and
/// a long Latin name cut short ends in its own "…" ("Basmati Rice 5kg
/// (Premium…"), while both start at the right like the Arabic text around
/// them; an Arabic name in the English app works the other way round. Text
/// without a letter (a number, a code) follows the layout.
class HeroBidiText extends StatelessWidget {
  const HeroBidiText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final layoutRtl = Directionality.of(context) == TextDirection.rtl;
    final rtl = TextDirectionEstimate.isRtl(text) ?? layoutRtl;
    return Text(
      text,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      // The layout's start side, whatever the text's own direction.
      textAlign: layoutRtl ? TextAlign.right : TextAlign.left,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
