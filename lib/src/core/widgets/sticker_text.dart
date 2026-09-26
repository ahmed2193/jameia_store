import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import 'sticker_rim_painter.dart';

/// Bold white letters with a dark rim — the "sticker" type of the buy
/// buttons and deal tags ("Add to cart", "Checkout", "Buy 2 get 1 free").
/// The label is one [Text]; the rim is painted behind it
/// ([StickerRimPainter]), so finders and screen readers meet it once.
class StickerText extends StatelessWidget {
  const StickerText(
    this.text, {
    super.key,
    required this.style,
    this.outline = AppColors.stickerOutline,
    this.rim = defaultRim,
    this.maxLines = 1,
    this.textAlign,
  });

  /// Stroke width of the rim; half of it shows outside the letters.
  static const double defaultRim = AppSize.s3;

  final String text;

  /// The fill: colour, size and weight of the letters.
  final TextStyle style;
  final Color outline;
  final double rim;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    var effective = inherited.style.merge(style);
    if (MediaQuery.boldTextOf(context)) {
      effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final align = textAlign ?? inherited.textAlign ?? TextAlign.start;
    return CustomPaint(
      painter: StickerRimPainter(
        text: text,
        style: effective,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textAlign: align,
        maxLines: maxLines,
        rim: rim,
        outline: outline,
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: effective,
      ),
    );
  }
}
