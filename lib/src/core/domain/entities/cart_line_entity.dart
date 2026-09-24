import 'package:equatable/equatable.dart';

import 'cart_line_ref.dart';
import 'catalog_product_entity.dart';

/// Why the server flagged a line (`lines[].issue`); the customer must fix it
/// before checkout.
enum CartLineIssue { none, outOfStock, quantityReduced, unavailable, other }

/// One paid line of the server cart (`GET /v1/cart` → `lines[]`). Money in
/// fils; [product] is the catalogue card the backend embeds.
class CartLineEntity extends Equatable {
  const CartLineEntity({
    required this.key,
    required this.product,
    this.quantity = 0,
    this.maxQuantity = 0,
    this.unitPriceFils = 0,
    this.compareAtFils,
    this.lineTotalFils = 0,
    this.variantId,
    this.variantName,
    this.issue = CartLineIssue.none,
  });

  /// Server line key (`PATCH /v1/cart/items/{key}`); empty while the line only
  /// exists locally (an add that has not reached the server yet).
  final String key;
  final CatalogProductEntity product;
  final int quantity;

  /// Stock cap the server applies; `0` = no cap known.
  final int maxQuantity;
  final int unitPriceFils;
  final int? compareAtFils;
  final int lineTotalFils;
  final String? variantId;
  final String? variantName;
  final CartLineIssue issue;

  CartLineRef get ref => CartLineRef(product.id, variantId);
  bool get isLocalOnly => key.isEmpty;
  bool get hasIssue => issue != CartLineIssue.none;

  /// Whether the line blocks checkout until the customer removes it.
  bool get blocksCheckout =>
      issue == CartLineIssue.outOfStock || issue == CartLineIssue.unavailable;
  bool get canIncrement => maxQuantity <= 0 || quantity < maxQuantity;

  bool get hasDiscount {
    final compareAt = compareAtFils;
    return compareAt != null && compareAt > unitPriceFils;
  }

  double get unitPriceKd => unitPriceFils / CatalogProductEntity.filsPerDinar;
  double get lineTotalKd => lineTotalFils / CatalogProductEntity.filsPerDinar;

  /// `0` without a discount (what `PriceText.originalPrice` expects).
  double get compareAtKd =>
      hasDiscount ? compareAtFils! / CatalogProductEntity.filsPerDinar : 0;

  CartLineEntity withQuantity(int quantity) => CartLineEntity(
    key: key,
    product: product,
    quantity: quantity,
    maxQuantity: maxQuantity,
    unitPriceFils: unitPriceFils,
    compareAtFils: compareAtFils,
    lineTotalFils: unitPriceFils * quantity,
    variantId: variantId,
    variantName: variantName,
    issue: issue,
  );

  @override
  List<Object?> get props => [
    key,
    product,
    quantity,
    maxQuantity,
    unitPriceFils,
    compareAtFils,
    lineTotalFils,
    variantId,
    variantName,
    issue,
  ];
}
