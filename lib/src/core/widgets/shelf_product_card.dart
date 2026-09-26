import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../domain/entities/catalog_product_entity.dart';
import 'shelf_card_media.dart';
import 'shelf_card_price.dart';
import 'shelf_pro_price_chip.dart';
import 'shelf_tag_pill.dart';

/// The product card of every grid and rail (a listing, the home rails, the
/// assistant, similar products): the light-grey picture tile (with the
/// "Save" badge and the round "+"), a merchandising tag ("Best seller"), the
/// name, the unit it is sold by — or "Multiple sizes" / "Bundle" — the price
/// with its deal marker and the struck "was" price under it, and what a Pro
/// member would pay. Stateless about the cart: the tile passes [qty] and the
/// taps.
class ShelfProductCard extends StatelessWidget {
  const ShelfProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.pro,
    required this.width,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
    this.reservesTagLine = true,
  });

  final CatalogProductEntity product;
  final int qty;

  /// The customer is a Pro member: the price is the Pro price.
  final bool pro;
  final double width;

  /// Opens the product page (also how a size is chosen).
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Keep the tag line even without a tag, so the names of a grid row line
  /// up. A rail (fixed height, one row) skips it: an untagged card reads
  /// name-first under its picture and the spare room falls at the bottom.
  final bool reservesTagLine;

  /// The fixed gaps of the block under the picture: picture → tag → name,
  /// name → price, price → Pro chip.
  static const double _gaps =
      AppSpacing.s8 + AppSpacing.s4 + AppSpacing.s4 + AppSpacing.s6;

  /// Its lines at the default text scale: two name lines, the unit line,
  /// the price, the struck "was" price and the Pro chip.
  static const double _nameLines = 38;
  static const double _unitLine = 16;
  static const double _priceLine = 22;
  static const double _wasLine = 16;
  static const double _proChip = 20;
  static const double _textLines =
      _nameLines + _unitLine + _priceLine + _wasLine + _proChip;

  /// Height of the whole block under the picture at the default text scale:
  /// a cell is `width + textBlockHeight` there.
  static const double textBlockHeight =
      _gaps + ShelfTagPill.height + _textLines;

  /// The cell height a grid or rail owes a [width]-wide card at the reader's
  /// text scale (the tag line and the text grow with it, the gaps do not).
  static double cellHeight(BuildContext context, {required double width}) =>
      width +
      _gaps +
      MediaQuery.textScalerOf(context).scale(ShelfTagPill.height + _textLines);

  /// The height a one-row rail of [products] needs: its tallest card, line
  /// by line, instead of room for every line a card could have — so a rail
  /// of plain products has no empty band under it. Mirrors [build] with
  /// `reservesTagLine: false` (the name always keeps its two lines). With
  /// no products it is [cellHeight].
  static double railHeight(
    BuildContext context, {
    required double width,
    required Iterable<CatalogProductEntity> products,
    required bool pro,
  }) {
    if (products.isEmpty) return cellHeight(context, width: width);
    final scaler = MediaQuery.textScalerOf(context);
    var tallest = 0.0;
    for (final product in products) {
      final hasProHint = !pro && product.hasProPrice;
      final lines =
          (ShelfTagPill.wears(product) ? ShelfTagPill.height : 0) +
          _nameLines +
          (unitLineKeyOf(product) != null ? _unitLine : 0) +
          _priceLine +
          (product.hasListPrice && product.hasDiscount ? _wasLine : 0) +
          (hasProHint ? _proChip : 0);
      final gaps =
          AppSpacing.s8 +
          (ShelfTagPill.wears(product) ? AppSpacing.s4 : 0) +
          AppSpacing.s4 +
          (hasProHint ? AppSpacing.s6 : 0);
      final block = gaps + scaler.scale(lines);
      if (block > tallest) tallest = block;
    }
    return width + tallest;
  }

  /// The i18n key of the unit a product is sold by, or null for `per piece`
  /// (the default, which says nothing).
  static String? unitKeyOf(UnitOfSale unit) => switch (unit) {
    UnitOfSale.kg => 'catalog.per_kg',
    UnitOfSale.litre => 'catalog.per_litre',
    UnitOfSale.pack => 'catalog.per_pack',
    UnitOfSale.piece || UnitOfSale.other => null,
  };

  /// The i18n key of the line under the name: the unit, or — for a product
  /// sold per piece — what kind of product it is ("Multiple sizes",
  /// "Bundle"); null when there is nothing to say.
  static String? unitLineKeyOf(CatalogProductEntity product) =>
      unitKeyOf(product.unitOfSale) ??
      switch (product.type) {
        CatalogProductType.variant => 'catalog.multiple_sizes',
        CatalogProductType.bundle => 'catalog.bundle',
        CatalogProductType.standard || CatalogProductType.other => null,
      };

  @override
  Widget build(BuildContext context) {
    final unitLineKey = unitLineKeyOf(product);
    final proHintFils = !pro && product.hasProPrice
        ? product.proPriceFils
        : null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShelfCardMedia(
              product: product,
              qty: qty,
              width: width,
              onAdd: onAdd,
              onRemove: onRemove,
              onChooseOptions: onTap,
            ),
            const SizedBox(height: AppSpacing.s8),
            if (reservesTagLine || ShelfTagPill.wears(product)) ...[
              ShelfTagPill(product: product),
              const SizedBox(height: AppSpacing.s4),
            ],
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            if (unitLineKey != null)
              Text(
                unitLineKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            const SizedBox(height: AppSpacing.s4),
            if (product.hasListPrice)
              ShelfCardPrice(
                priceKd: product.priceKdFor(pro: pro),
                wasKd: product.compareAtKd,
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
            if (proHintFils != null) ...[
              const SizedBox(height: AppSpacing.s6),
              ShelfProPriceChip(
                priceKd: proHintFils / CatalogProductEntity.filsPerDinar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
