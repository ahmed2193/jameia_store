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
///
/// A block that opens a collection page hands it the hero dress it
/// advertised: a strip's line and countdown, and the Hero flame after the
/// heading when the block is a sale or deals.
class HomeSectionView extends StatelessWidget {
  const HomeSectionView({super.key, required this.section});

  final HomeSectionEntity section;

  /// Whether a list opened from a block themed [theme] shows the flame after
  /// its heading (a sale or deals).
  static bool _isHot(HomeSectionTheme theme) => switch (theme) {
    HomeSectionTheme.sale || HomeSectionTheme.deals => true,
    HomeSectionTheme.standard ||
    HomeSectionTheme.featured ||
    HomeSectionTheme.store => false,
  };

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
            flame: _isHot(section.theme),
          ),
        ),
      ),
      // The strip links to the collection the rail previews, so its arrow is
      // the rail's "view all" too: the listing takes the rail's short title.
      // The flame follows the strip's theme, or the block's when the rail
      // itself is the sale.
      HomeThemedBlockSection() => HomeThemedBlock(
        section: section,
        onOpenStrip: () => HomeLinkOpener.open(
          context,
          section.strip.link,
          title: section.rail.hasTitle
              ? section.rail.title
              : section.strip.headline,
          subtitle: section.strip.subtitle,
          endsAt: section.strip.endsAt,
          flame: _isHot(section.strip.theme) || _isHot(section.theme),
        ),
        onOpenProduct: (product) => context.push(
          Routes.productDetail,
          extra: ProductDetailArgs.of(product),
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
          subtitle: section.subtitle,
          endsAt: section.endsAt,
          flame: _isHot(section.theme),
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
