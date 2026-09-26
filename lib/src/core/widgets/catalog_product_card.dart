import 'package:flutter/material.dart';

import '../domain/entities/catalog_product_entity.dart';
import '../responsive/app_size.dart';
import 'shelf_product_card.dart';

/// The product card of the home rails and the assistant's product rails —
/// the one shelf card the listing grid and the product page rails show too
/// ([ShelfProductCard]): the light-grey picture with the "Save" badge and
/// the round "+", the name, the unit (or "Multiple sizes" / "Bundle"), the
/// price with its deal marker and struck "was" price, and what a Pro member
/// would pay. A rail has one row, so by default an untagged card skips the
/// tag line; a grid sets [reservesTagLine] so the names of a row line up.
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
    this.reservesTagLine = false,
  });

  static const double defaultWidth = AppSize.s130;

  /// Height of the block under the square picture at the default text
  /// scale. A rail or grid sizes its cells as `width + textBlockHeight`
  /// there ([cellHeight] beyond it).
  static const double textBlockHeight = ShelfProductCard.textBlockHeight;

  /// The cell height a rail or grid owes a [width]-wide card at the reader's
  /// text scale — the shelf card's own ([ShelfProductCard.cellHeight]). At
  /// the default scale this is `width + textBlockHeight`; the app clamps
  /// scaling at 1.3, where the card needs more.
  static double cellHeight(
    BuildContext context, {
    double width = defaultWidth,
  }) => ShelfProductCard.cellHeight(context, width: width);

  /// The height a one-row rail of [products] needs: its tallest card
  /// ([ShelfProductCard.railHeight]).
  static double railHeight(
    BuildContext context, {
    required Iterable<CatalogProductEntity> products,
    required bool pro,
    double width = defaultWidth,
  }) => ShelfProductCard.railHeight(
    context,
    width: width,
    products: products,
    pro: pro,
  );

  /// The i18n key of the unit a product is sold by, or null for `per piece`
  /// (the default, which says nothing).
  static String? unitKeyOf(UnitOfSale unit) => ShelfProductCard.unitKeyOf(unit);

  final CatalogProductEntity product;
  final int qty;

  /// Opens the product page (also how a variant is chosen).
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool pro;
  final double width;

  /// Keep the tag line even without a tag ([ShelfProductCard.reservesTagLine]):
  /// a grid of several rows sets it so the names of a row line up; a rail
  /// (one row) leaves it off.
  final bool reservesTagLine;

  @override
  Widget build(BuildContext context) {
    return ShelfProductCard(
      product: product,
      qty: qty,
      pro: pro,
      width: width,
      onTap: onTap,
      onAdd: onAdd,
      onRemove: onRemove,
      reservesTagLine: reservesTagLine,
    );
  }
}
