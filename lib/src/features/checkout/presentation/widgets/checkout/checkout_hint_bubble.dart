import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_line_thumb.dart';
import 'checkout_hint_tail_painter.dart';

/// The dark "KD x off this item" bubble over "Place order": the line's
/// picture on a white plate, the saving in bold, then which pieces it is on
/// ("this item" / "these 2 items"), and a tail under the bubble's centre.
///
/// A solid fill and a painted tail — no shadow, blur or opacity, so the
/// float that carries it only moves a layer. The height is a minimum: large
/// text grows the bubble instead of clipping it.
class CheckoutHintBubble extends StatelessWidget {
  const CheckoutHintBubble({
    super.key,
    required this.imageUrl,
    required this.savingKd,
    required this.quantity,
  });

  /// The nearest width on the size scale (Hero measures 168).
  static const double width = AppSize.s170;
  static const double minHeight = AppSize.s50;
  static const double plateSize = AppSize.s40;
  static const Size tailSize = Size(AppSize.s12, AppSize.s6);
  static const int _maxLines = 3;

  static const BoxDecoration _fill = BoxDecoration(
    color: AppColors.tooltipFill,
    borderRadius: BorderRadius.all(Radius.circular(AppSize.r8)),
  );
  static const BorderRadius _plateRadius = BorderRadius.all(
    Radius.circular(AppSize.r4),
  );

  final String imageUrl;
  final double savingKd;

  /// Pieces of the line the saving is on.
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyLarge.copyWith(color: AppColors.white);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: _fill,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s10,
                  AppSpacing.s5,
                  AppSpacing.s8,
                  AppSpacing.s5,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: _plateRadius,
                      child: ColoredBox(
                        color: AppColors.white,
                        child: SizedBox.square(
                          dimension: plateSize,
                          // The 56 dp line thumb (one CDN url and decode with
                          // the cart row), scaled into the 40 dp plate.
                          child: FittedBox(child: HeroLineThumb(url: imageUrl)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'checkout.hint_off'.tr(
                                namedArgs: {
                                  'amount': Formatters.price(savingKd),
                                },
                              ),
                              style: const TextStyle(
                                fontWeight: AppTextStyles.bold,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: 'checkout.hint_items'.plural(quantity),
                            ),
                          ],
                        ),
                        maxLines: _maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const CustomPaint(
          size: tailSize,
          painter: CheckoutHintTailPainter(color: AppColors.tooltipFill),
        ),
      ],
    );
  }
}
