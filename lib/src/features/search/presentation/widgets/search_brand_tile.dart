import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import 'search_tile_image.dart';

/// A brand of the search screen: its logo on an outlined 16 dp tile and the
/// name under it. Opens the brand's products.
class SearchBrandTile extends StatelessWidget {
  const SearchBrandTile({super.key, required this.brand});

  static const double size = AppSize.s80;
  static const double _pressedScale = 0.97;

  final BrandEntity brand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: brand.name,
      excludeSemantics: true,
      child: PressScale(
        pressedScale: _pressedScale,
        onTap: () => context.push(
          Routes.productListing,
          extra: ProductListingArgs.brand(slug: brand.slug, title: brand.name),
        ),
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: size,
                child: SearchTileImage(
                  url: brand.image,
                  initial: brand.initial,
                  outlined: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                brand.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
