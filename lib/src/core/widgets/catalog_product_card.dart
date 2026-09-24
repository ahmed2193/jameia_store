import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../domain/entities/catalog_product_entity.dart';
import '../responsive/app_size.dart';
import '../utils/formatters.dart';
import 'catalog_add_control.dart';
import 'catalog_discount_badge.dart';
import 'catalog_pro_price_tag.dart';
import 'catalog_type_chip.dart';
import 'catalog_unavailable_overlay.dart';
import 'jameia_image.dart';
import 'rating_badge.dart';

/// The product card of every backend-catalogue list (home rails, category /
/// brand / collection / search grids, related products): a square image with
/// the discount badge, the type chip and the floating cart control, then the
/// name, the unit it is sold by, the price (struck "was" price beside it) and
/// either the rating or what a Pro member would pay for it.
///
/// Stateless about the cart: the feature passes [qty] and handles the taps
/// (`CartCubit.addCatalogProduct` / `removeProduct`). [pro] selects the Pro
/// price for a Pro member.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
    this.pro = false,
    this.width = defaultWidth,
  });

  static const double defaultWidth = AppSize.s130;

  /// Height of the text block under the square image: name (2 lines), the
  /// unit, price, then the rating or the Pro price. A rail or grid sizes its
  /// cells as `width + textBlockHeight`.
  static const double textBlockHeight = AppSize.s104;

  /// The fixed gaps inside that block; everything else in it is text, and
  /// text grows with the reader's scale.
  static const double _textGaps =
      AppSpacing.s6 + AppSpacing.s2 + AppSpacing.s2 + AppSpacing.s2;
  static const double _textLines = textBlockHeight - _textGaps;

  /// The cell height a rail or grid owes a [width]-wide card at the reader's
  /// text scale. At the default scale this is `width + textBlockHeight`;
  /// the app clamps scaling at 1.3, where the card needs more.
  static double cellHeight(
    BuildContext context, {
    double width = defaultWidth,
  }) => width + _textGaps + MediaQuery.textScalerOf(context).scale(_textLines);

  static const double _dimmed = 0.45;

  final CatalogProductEntity product;
  final int qty;

  /// Opens the product page (also how a variant is chosen).
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool pro;
  final double width;

  @override
  Widget build(BuildContext context) {
    // `per piece` is the default and says nothing; the other units do.
    final unitKey = switch (product.unitOfSale) {
      UnitOfSale.kg => 'catalog.per_kg',
      UnitOfSale.litre => 'catalog.per_litre',
      UnitOfSale.pack => 'catalog.per_pack',
      UnitOfSale.piece || UnitOfSale.other => null,
    };
    final proHintFils = !pro && product.hasProPrice
        ? product.proPriceFils
        : null;
    final typeLabel = switch (product.type) {
      CatalogProductType.variant => 'catalog.multiple_sizes'.tr(),
      CatalogProductType.bundle => 'catalog.bundle'.tr(),
      CatalogProductType.standard || CatalogProductType.other => null,
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: width,
              child: Stack(
                children: [
                  Opacity(
                    opacity: product.inStock ? 1 : _dimmed,
                    child: JameiaImage(
                      url: product.image,
                      width: width,
                      height: width,
                      radius: AppRadius.card,
                    ),
                  ),
                  if (product.hasDiscount)
                    PositionedDirectional(
                      top: AppSpacing.s6,
                      start: AppSpacing.s6,
                      child: CatalogDiscountBadge(
                        percent: product.discountPercent,
                      ),
                    )
                  else if (typeLabel != null)
                    PositionedDirectional(
                      top: AppSpacing.s6,
                      start: AppSpacing.s6,
                      child: CatalogTypeChip(label: typeLabel),
                    ),
                  if (!product.inStock)
                    const Positioned.fill(child: CatalogUnavailableOverlay()),
                  CatalogAddControl(
                    product: product,
                    qty: qty,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    onChooseOptions: onTap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.bold,
                height: AppSize.lh1_2,
              ),
            ),
            if (unitKey != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                unitKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s2),
            if (product.hasListPrice)
              Row(
                children: [
                  Flexible(
                    child: Text(
                      Formatters.price(product.priceKdFor(pro: pro)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: product.hasDiscount
                            ? AppColors.finalPrice
                            : AppColors.primaryText,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(width: AppSpacing.s4),
                    Flexible(
                      child: Text(
                        Formatters.amount(product.compareAtKd),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.tertiaryText,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Text(
                'catalog.choose_options'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            // What a Pro member would pay is the better line to show here:
            // a member already sees that price as the price.
            if (proHintFils != null) ...[
              const SizedBox(height: AppSpacing.s2),
              CatalogProPriceTag(
                priceKd: proHintFils / CatalogProductEntity.filsPerDinar,
              ),
            ] else if (product.hasRating) ...[
              const SizedBox(height: AppSpacing.s2),
              RatingBadge(
                rating: product.ratingAverage,
                count: product.ratingCount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
