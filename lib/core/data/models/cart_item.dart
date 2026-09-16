import 'package:equatable/equatable.dart';

import 'shop.dart';

/// Runtime cart line — a [Product] (optionally a specific [ProductVariant])
/// plus quantity, scoped to a shop. Lines are keyed by [lineKey] so the same
/// product in two different sizes counts as two lines.
///
/// Immutable + value-equal: a quantity change returns a **new** instance via
/// [copyWith]. This is deliberate — the old in-place `qty++` mutation aliased
/// the same object between the previous and next [CartState], so Equatable saw
/// no change and Bloc swallowed the `emit` (the second same-line add never
/// reached the UI). Value equality over identity fields + qty fixes that.
class CartItem extends Equatable {
  final Product product;
  final ProductVariant? variant;
  final String shopId;
  final int qty;

  /// Price snapshot taken when the line was added — used for VIP/Mart pricing so
  /// a later store-mode toggle never silently re-prices an existing line.
  final double? unitPriceOverride;

  const CartItem({
    required this.product,
    required this.shopId,
    this.variant,
    this.qty = 1,
    this.unitPriceOverride,
  });

  CartItem copyWith({int? qty}) => CartItem(
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

  /// Label shown in the cart / checkout (product name + variant option),
  /// locale-aware (Arabic product name when the app is in Arabic).
  String get displayName => variant == null
      ? product.displayName
      : '${product.displayName} · ${variant!.label}';

  /// Image to show in the cart — the variant gallery image if it has one.
  String get displayImage =>
      (variant != null && variant!.image.isNotEmpty) ? variant!.image : product.image;

  /// Identity is (line, shop, qty, price snapshot) — enough to drive rebuilds
  /// while keeping `product`/`variant` object identity out of the comparison
  /// (those models are plain, non-Equatable classes).
  @override
  List<Object?> get props => [lineKey, shopId, qty, unitPriceOverride];
}
