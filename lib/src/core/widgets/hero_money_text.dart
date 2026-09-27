import 'package:flutter/material.dart';

import '../../config/theme/app_text_styles.dart';
import '../motion/rolling_number.dart';
import '../utils/formatters.dart';

/// Money the customer compares: one left-to-right run with tabular figures
/// (`KD 12.500` / `د.ك 12.500`), read out as the localized price. Inherits
/// the surrounding [DefaultTextStyle] unless [style] is given. [negative]
/// prefixes a minus (a discount), [strike] strikes it through (a was-price),
/// [rolling] rolls the digits that change — bottom-bar totals only; static on
/// the first build.
class HeroMoneyText extends StatelessWidget {
  const HeroMoneyText({
    super.key,
    required this.kd,
    this.style,
    this.color,
    this.negative = false,
    this.strike = false,
    this.rolling = false,
  });

  static const String _minus = '- ';

  final double kd;
  final TextStyle? style;
  final Color? color;
  final bool negative;
  final bool strike;
  final bool rolling;

  String get _sign => negative ? _minus : '';

  String _format(num v) => '$_sign${Formatters.priceLtr(v.toDouble())}';

  @override
  Widget build(BuildContext context) {
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontFeatures: AppTextStyles.tabular,
      decoration: strike ? TextDecoration.lineThrough : null,
      decorationColor: strike ? color : null,
    );
    return Semantics(
      label: '$_sign${Formatters.price(kd)}',
      excludeSemantics: true,
      child: rolling
          ? RollingNumber(value: kd, format: _format, style: base)
          : Directionality(
              textDirection: TextDirection.ltr,
              child: Text(_format(kd), maxLines: 1, style: base),
            ),
    );
  }
}
