import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';

/// The green basket of the basket bars, with the item count in a red disc
/// at its top-end corner that pops when the count changes (an empty basket
/// shows no disc). The basket can be where added products fly to
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
    final decode = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              count > 0 ? HeroAssets.globalCartFull : HeroAssets.globalCart,
              key: targetKey,
              width: size,
              height: size,
              cacheWidth: decode,
              fit: BoxFit.contain,
            ),
            if (count > 0)
              PositionedDirectional(
                top: _discInset,
                end: _discInset,
                child: PopScale(
                  popKey: count,
                  // A circle, stretched into a pill by a long count.
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: _disc,
                      minHeight: _disc,
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s5,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent1,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.white, width: _ring),
                      ),
                    ),
                    child: Text(
                      '$count',
                      maxLines: 1,
                      style: AppTextStyles.tag.copyWith(
                        color: AppColors.white,
                        fontFeatures: AppTextStyles.tabular,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
