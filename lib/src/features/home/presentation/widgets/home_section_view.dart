import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_banner_block.dart';
import 'home_brand_rail.dart';
import 'home_category_grid.dart';
import 'home_link_opener.dart';
import 'home_product_rail.dart';
import 'home_promo_cards.dart';
import 'home_promo_strip.dart';
import 'home_recipe_rail.dart';
import 'home_themed_block.dart';

/// Renders one backend block of the home feed and wires its taps to the
/// router. The exhaustive `switch` on the sealed [HomeSectionEntity] means a
/// new block type cannot be forgotten here.
class HomeSectionView extends StatelessWidget {
  const HomeSectionView({super.key, required this.section});

  final HomeSectionEntity section;

  @override
  Widget build(BuildContext context) {
    final section = this.section;
    return switch (section) {
      HomeProductRailSection() => HomeProductRail(
        section: section,
        onOpenProduct: (product) => context.push(
          Routes.productDetail,
          extra: ProductDetailArgs.of(product),
        ),
        onViewAll: () => context.push(
          Routes.productListing,
          extra: ProductListingArgs.collection(
            slug: section.collectionSlug,
            title: section.title,
          ),
        ),
      ),
      HomeThemedBlockSection() => HomeThemedBlock(
        section: section,
        onOpenStrip: () => HomeLinkOpener.open(
          context,
          section.strip.link,
          title: section.strip.headline,
        ),
        onOpenProduct: (product) => context.push(
          Routes.productDetail,
          extra: ProductDetailArgs.of(product),
        ),
        onViewAll: () => context.push(
          Routes.productListing,
          extra: ProductListingArgs.collection(
            slug: section.rail.collectionSlug,
            title: section.rail.title,
          ),
        ),
      ),
      HomeCategoryRailSection() => HomeCategoryGrid(
        section: section,
        onOpenCategory: (category) =>
            context.push(Routes.category, extra: CategoryArgs.of(category)),
        onViewAll: () => context.push(Routes.categories),
      ),
      HomeBrandRailSection() => HomeBrandRail(
        section: section,
        onOpenBrand: (brand) => context.push(
          Routes.productListing,
          extra: ProductListingArgs.brand(slug: brand.slug, title: brand.name),
        ),
        onViewAll: () => context.push(Routes.brands),
      ),
      HomeRecipeRailSection() => HomeRecipeRail(
        section: section,
        onOpenRecipe: (recipe) =>
            context.push(Routes.recipe, extra: recipe.slug),
        onViewAll: () => context.push(Routes.recipes),
      ),
      HomePromoCardsSection() => HomePromoCards(
        section: section,
        onOpenLink: (link, title) =>
            HomeLinkOpener.open(context, link, title: title),
      ),
      HomePromoStripSection() => HomePromoStrip(
        section: section,
        onTap: () => HomeLinkOpener.open(
          context,
          section.link,
          title: section.hasTitle ? section.title : section.headline,
        ),
      ),
      HomeBannerSection() => HomeBannerBlock(
        section: section,
        onTap: () => HomeLinkOpener.open(
          context,
          section.link,
          title: section.hasTitle ? section.title : section.caption,
        ),
      ),
    };
  }
}
