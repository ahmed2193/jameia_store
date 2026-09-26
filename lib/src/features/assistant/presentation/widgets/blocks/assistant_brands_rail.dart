import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/brand_entity.dart';
import 'assistant_pill_chip.dart';
import 'assistant_pill_rail.dart';

/// `brands`: brands to browse; a pill opens the brand's products.
class AssistantBrandsRail extends StatelessWidget {
  const AssistantBrandsRail({super.key, required this.brands});

  final List<BrandEntity> brands;

  @override
  Widget build(BuildContext context) {
    return AssistantPillRail(
      title: 'assistant.brands_title'.tr(),
      children: [
        for (final brand in brands)
          AssistantPillChip(
            key: ValueKey(brand.id),
            label: brand.name,
            imageUrl: brand.image,
            initial: brand.initial,
            onTap: () => context.push(
              Routes.productListing,
              extra: ProductListingArgs.brand(
                slug: brand.slug,
                title: brand.name,
              ),
            ),
          ),
      ],
    );
  }
}
