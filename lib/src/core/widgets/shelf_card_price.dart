import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import '../utils/formatters.dart';
import 'shelf_arrival_scope.dart';
import 'shelf_marker_painter.dart';

/// A product card's price: the currency and the amount in a medium weight,
/// and for a deal a lime marker stroke under the price — drawn in as the
/// card lands — with the struck "was" price on its own line below, its
/// currency on the same side as the price's.
class ShelfCardPrice extends StatelessWidget {
  const ShelfCardPrice({super.key, required this.priceKd, this.wasKd = 0});

  final double priceKd;

  /// The price before the deal; 0 without one.
  final double wasKd;

  /// The marker draws over the last part of its card's arrival.
  static const Interval _draw = Interval(
    0.55,
    1,
    curve: AppMotion.emphasizedDecelerate,
  );

  bool get _deal => wasKd > priceKd && wasKd > 0;

  @override
  Widget build(BuildContext context) {
    final price = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          Formatters.currency,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
        ),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            Formatters.amount(priceKd),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
    if (!_deal) return price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: ShelfMarkerPainter(
            progress: ShelfArrivalScope.of(context)
                .drive(CurveTween(curve: _draw)),
            color: AppColors.proLime,
            textDirection: Directionality.of(context),
          ),
          child: price,
        ),
        // Currency first, like the price row above: in Arabic the label
        // then stacks under the price's label (right) instead of mirroring
        // to the left as `Formatters.price` does inside an RTL line.
        Text(
          '${Formatters.currency} ${Formatters.amount(wasKd)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.tertiaryText,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}
