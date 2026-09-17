import 'package:equatable/equatable.dart';

import 'product_entity.dart';
import 'product_variant_entity.dart';

/// Runtime cart line — a [product] (optionally a specific [variant]) plus
/// quantity, scoped to a shop. Lines are keyed by [lineKey] so the same product
/// in two different sizes counts as two lines.
///
/// Immutable: a quantity change returns a new instance via [copyWith].
class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.product,
    required this.shopId,
    this.variant,
    this.qty = 1,
    this.unitPriceOverride,
  });

  final ProductEntity product;
  final ProductVariantEntity? variant;
  final String shopId;
  final int qty;

  /// Price snapshot taken when the line was added — used for VIP/Mart pricing
  /// so a later store-mode toggle never silently re-prices an existing line.
  final double? unitPriceOverride;

  CartItemEntity copyWith({int? qty}) => CartItemEntity(
    product: product,
    shopId: shopId,
    variant: variant,
    qty: qty ?? this.qty,
    unitPriceOverride: unitPriceOverride,
  );

  /// Stable identity of this line: product id, plus the variant SKU when a
  /// specific SKU was chosen.
  String get lineKey =>
      variant == null ? product.id : '${product.id}:${variant!.sku}';

  /// Unit price — the chosen variant's price when present, else the snapshot
  /// taken at add-time (VIP/Mart aware), else the product's Mart price.
  double get unitPrice => variant?.price ?? unitPriceOverride ?? product.price;

  double get lineTotal => unitPrice * qty;

  /// Active-locale line label: product name (see [ProductEntity.nameFor]) plus
  /// ` · <variant label>` when a variant is chosen.
  String nameFor(String languageCode) => variant == null
      ? product.nameFor(languageCode)
      : '${product.nameFor(languageCode)} · ${variant!.label}';

  /// Image to show in the cart — the variant gallery image if it has one.
  String get displayImage => (variant != null && variant!.image.isNotEmpty)
      ? variant!.image
      : product.image;

  /// Identity is (line, shop, qty, price snapshot) — same as the `CartItem`
  /// DTO, so cart state rebuild semantics are unchanged.
  @override
  List<Object?> get props => [lineKey, shopId, qty, unitPriceOverride];
}
