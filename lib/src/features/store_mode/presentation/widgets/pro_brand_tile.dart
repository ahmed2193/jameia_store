import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_image.dart';

/// A brand's logo square in the paywall's logo rows (its initial when the
/// brand has no logo); opens the brand's products.
class ProBrandTile extends StatelessWidget {
  const ProBrandTile({super.key, required this.brand});

  static const double side = AppSize.s88;

  final BrandEntity brand;

  @override
  Widget build(BuildContext context) {
    void open() => context.push(
      Routes.productListing,
      extra: ProductListingArgs.brand(slug: brand.slug, title: brand.name),
    );
    // `excludeSemantics` drops the press-scale's tap, so the node carries its
    // own: a screen reader can open the brand too.
    return Semantics(
      button: true,
      label: brand.name,
      excludeSemantics: true,
      onTap: open,
      child: PressScale(
        onTap: open,
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: brand.hasImage ? AppColors.white : AppColors.smallBackground,
            borderRadius: BorderRadius.circular(AppRadius.r3),
            border: Border.all(color: AppColors.brandTileBorder),
          ),
          child: brand.hasImage
              ? HeroImage(
                  url: brand.image,
                  width: side,
                  height: side,
                  memCacheWidth: context.cacheCapFor(side),
                )
              : Text(
                  brand.initial,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.secondaryText,
                  ),
                ),
        ),
      ),
    );
  }
}
