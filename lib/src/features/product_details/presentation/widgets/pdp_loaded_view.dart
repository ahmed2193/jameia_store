import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/stagger_entrance.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/entities/product_detail.dart';
import '../cubit/product_detail_cubit.dart';
import 'pdp_bundle_contents.dart';
import 'pdp_category_link.dart';
import 'pdp_info_block.dart';
import 'pdp_product_rail.dart';
import 'pdp_recipes_rail.dart';
import 'pdp_reviews_section.dart';
import 'pdp_scaffold_view.dart';
import 'pdp_section.dart';
import 'pdp_section_divider.dart';
import 'pdp_variant_selector.dart';

/// The loaded product page, flat blocks on the white sheet in talabat-mart's
/// order: gallery → tag, brand, name, meta, description, notes → options
/// (variant product) → contents (bundle) → similar products → "shop more
/// for less" (the related deals) → recipes using it → reviews → category.
///
/// The blocks under the name cascade in once as the page loads (the photo
/// and the name were already painted by the preview, so they stay put).
class PdpLoadedView extends StatefulWidget {
  const PdpLoadedView({
    super.key,
    required this.detail,
    required this.selectedVariantId,
    this.lowStockLeft,
    this.galleryKey,
  });

  final ProductDetail detail;
  final String? selectedVariantId;

  /// Units of the selection left when they are running out, else `null`.
  final int? lowStockLeft;

  /// On the gallery: where the buy bar's fly-to-cart takes off.
  final GlobalKey? galleryKey;

  @override
  State<PdpLoadedView> createState() => _PdpLoadedViewState();
}

class _PdpLoadedViewState extends State<PdpLoadedView> {
  final GlobalKey _reviewsKey = GlobalKey();

  /// Brings the reviews up to just under the solid top bar. The bar is an
  /// overlay, not a pinned sliver, so the viewport's own reveal
  /// ([Scrollable.ensureVisible]) would park the heading behind it.
  void _scrollToReviews() {
    final target = _reviewsKey.currentContext;
    final box = target?.findRenderObject();
    if (target == null || box == null) return;
    final position = Scrollable.of(target).position;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0);
    final to = (reveal.offset - PdpScaffoldView.coveredTop(context)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final duration = MotionGuard.duration(context, AppMotion.page);
    // A scroll animation needs a real duration: reduced motion jumps.
    if (duration == Duration.zero) {
      position.jumpTo(to);
      return;
    }
    position.animateTo(to, duration: duration, curve: AppMotion.signature);
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
    final category = detail.category;
    final similar = detail.relatedRegular;
    final deals = detail.relatedOnDeal;
    // The id keeps each block's entrance with the block when another block
    // comes or goes on a reload. `divided` puts a hairline above it; like
    // talabat, the options run straight on from the description, the
    // hairline comes before the first rail, and the rails follow one another
    // without one.
    final blocks = <({String id, bool divided, Widget block})>[
      if (detail.needsVariant)
        (
          id: 'variants',
          divided: false,
          block: PdpVariantSelector(
            variants: detail.variants,
            selectedId: widget.selectedVariantId,
            pro: isPro,
            onSelect: context.read<ProductDetailCubit>().selectVariant,
          ),
        ),
      if (detail.bundleItems.isNotEmpty)
        (
          id: 'bundle',
          divided: true,
          block: PdpBundleContents(
            items: detail.bundleItems,
            onOpenProduct: _openProduct,
          ),
        ),
      if (similar.isNotEmpty)
        (
          id: 'similar',
          divided: true,
          block: PdpProductRail(
            title: 'product.similar_products'.tr(),
            products: similar,
          ),
        ),
      if (deals.isNotEmpty)
        (
          id: 'deals',
          divided: similar.isEmpty,
          block: PdpProductRail(
            title: 'product.shop_more_for_less'.tr(),
            products: deals,
          ),
        ),
      if (detail.recipes.isNotEmpty)
        (
          id: 'recipes',
          divided: true,
          block: PdpRecipesRail(
            recipes: detail.recipes,
            onOpenRecipe: (recipe) =>
                context.push(Routes.recipe, extra: recipe.slug),
          ),
        ),
      (
        id: 'reviews',
        divided: true,
        block: PdpReviewsSection(key: _reviewsKey),
      ),
      if (category != null)
        (
          id: 'category',
          divided: true,
          block: PdpCategoryLink(category: category),
        ),
    ];
    return PdpScaffoldView(
      title: detail.product.name,
      images: detail.gallery,
      galleryKey: widget.galleryKey,
      sections: [
        PdpSection(
          child: PdpInfoBlock(
            product: detail.product,
            brand: detail.brand,
            description: detail.description,
            inStock: detail.stockOf(variant) > 0,
            lowStockLeft: widget.lowStockLeft,
            discountPercent: detail.discountPercent(variant: variant, now: now),
            proPriceApplied:
                detail.regularPriceFilsWhenPro(variant: variant, pro: isPro) !=
                null,
            proPriceHintFils: isPro
                ? null
                : detail.proPriceFilsHint(variant: variant),
            onOpenReviews: _scrollToReviews,
          ),
        ),
        for (final (index, (:id, :divided, :block)) in blocks.indexed)
          StaggerEntrance(
            key: ValueKey<String>(id),
            // The name block is index 0: the cascade starts after it.
            index: index + 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [if (divided) const PdpSectionDivider(), block],
            ),
          ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }
}
