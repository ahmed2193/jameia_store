import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../responsive/app_size.dart';
import 'count_badge.dart';

/// The green basket of the basket bars, with the item count in a red disc
/// at its top-end corner ([CountBadge]: it bumps and rolls when the count
/// changes — a rise when the added product's flight lands — and an empty
/// basket shows no disc). The basket can be where added products fly to
/// ([targetKey]). Decorative for a screen reader: the bar reads the count.
class CartBasketBadge extends StatelessWidget {
  const CartBasketBadge({
    super.key,
    required this.count,
    this.targetKey,
    this.size = defaultSize,
  });

  static const double defaultSize = AppSize.s52;
  static const double _disc = AppSize.s24;
  static const double _discInset = -AppSpacing.s4;
  static const double _ring = AppSize.s2;

  final int count;

  /// Put on the basket, for `FlyToCart.pushTarget`.
  final GlobalKey? targetKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              count > 0 ? HeroAssets.cartBasketFull : HeroAssets.cartBasket,
              key: targetKey,
              width: size,
              height: size,
            ),
            PositionedDirectional(
              top: _discInset,
              end: _discInset,
              // A circle, stretched into a pill by a long count.
              child: CountBadge(
                count: count,
                color: AppColors.accent1,
                textStyle: AppTextStyles.tag,
                borderColor: AppColors.white,
                borderWidth: _ring,
                minSize: _disc,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s5,
                ),
                landsWithFlight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
