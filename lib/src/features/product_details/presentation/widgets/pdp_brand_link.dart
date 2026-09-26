import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';

/// The brand's name above the product's, as an underlined ink link to the
/// products of that brand (a brand listing).
class PdpBrandLink extends StatelessWidget {
  const PdpBrandLink({super.key, required this.brand});

  final BrandEntity brand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () => context.push(
          Routes.productListing,
          extra: ProductListingArgs.brand(slug: brand.slug, title: brand.name),
        ),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s2,
          ),
          child: Text(
            brand.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryText,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
