import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/entities/product_detail.dart';
import '../cubit/product_detail_cubit.dart';
import 'pdp_bundle_contents.dart';
import 'pdp_header_block.dart';
import 'pdp_link_row.dart';
import 'pdp_price_block.dart';
import 'pdp_recipes_rail.dart';
import 'pdp_related_rail.dart';
import 'pdp_reviews_section.dart';
import 'pdp_scaffold_view.dart';
import 'pdp_section_card.dart';
import 'pdp_variant_selector.dart';

/// The loaded product page, in the storefront's order: gallery → chips, name,
/// description, rating → price → options (variant product) → contents (bundle)
/// → brand / category links → recipes using it → related products → reviews.
class PdpLoadedView extends StatefulWidget {
  const PdpLoadedView({
    super.key,
    required this.detail,
    required this.selectedVariantId,
  });

  final ProductDetail detail;
  final String? selectedVariantId;

  @override
  State<PdpLoadedView> createState() => _PdpLoadedViewState();
}

class _PdpLoadedViewState extends State<PdpLoadedView> {
  final GlobalKey _reviewsKey = GlobalKey();

  void _scrollToReviews() {
    final target = _reviewsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MotionGuard.duration(context, AppMotion.page),
      curve: AppMotion.signature,
    );
  }

  void _openProduct(CatalogProductEntity product) =>
      context.push(Routes.productDetail, extra: ProductDetailArgs.of(product));

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    final variant = detail.variantById(widget.selectedVariantId);
    final now = DateTime.now();
    final brand = detail.brand;
    final category = detail.category;
    return PdpScaffoldView(
      images: detail.gallery,
      sections: [
        PdpHeaderBlock(
          product: detail.product,
          inStock: detail.stockOf(variant) > 0,
          description: detail.description,
          onOpenReviews: _scrollToReviews,
        ),
        if (!detail.needsVariant || variant != null)
          PdpPriceBlock(
            priceFils: detail.unitPriceFils(variant: variant, pro: isPro),
            compareAtFils: detail.compareAtFils(variant: variant, now: now),
            discountPercent: detail.discountPercent(variant: variant, now: now),
            regularPriceFilsWhenPro: detail.regularPriceFilsWhenPro(
              variant: variant,
              pro: isPro,
            ),
            proPriceFilsHint: isPro
                ? null
                : detail.proPriceFilsHint(variant: variant),
          ),
        if (detail.needsVariant)
          PdpVariantSelector(
            variants: detail.variants,
            selectedId: widget.selectedVariantId,
            pro: isPro,
            onSelect: context.read<ProductDetailCubit>().selectVariant,
          ),
        if (detail.bundleItems.isNotEmpty)
          PdpBundleContents(
            items: detail.bundleItems,
            onOpenProduct: _openProduct,
          ),
        if (brand != null || category != null)
          PdpSectionCard(
            child: Column(
              children: [
                if (brand != null)
                  PdpLinkRow(
                    label: 'product.brand'.tr(),
                    value: brand.name,
                    imageUrl: brand.image,
                    onTap: () => context.push(
                      Routes.productListing,
                      extra: ProductListingArgs.brand(
                        slug: brand.slug,
                        title: brand.name,
                      ),
                    ),
                  ),
                if (category != null)
                  PdpLinkRow(
                    label: 'product.category'.tr(),
                    value: category.name,
                    onTap: () => context.push(
                      Routes.category,
                      extra: CategoryArgs.of(category),
                    ),
                  ),
              ],
            ),
          ),
        if (detail.recipes.isNotEmpty)
          PdpRecipesRail(
            recipes: detail.recipes,
            onOpenRecipe: (recipe) =>
                context.push(Routes.recipe, extra: recipe.slug),
          ),
        if (detail.related.isNotEmpty)
          PdpRelatedRail(
            products: detail.related,
            pro: isPro,
            onOpenProduct: _openProduct,
          ),
        PdpReviewsSection(key: _reviewsKey),
        const SizedBox(height: AppSize.s24),
      ],
    );
  }
}
