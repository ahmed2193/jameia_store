import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// One purchasable option of a [CatalogProductType.variant] product
/// (`1 L` / `2 L`), as `GET /v1/products/:slug` → `variants[]` sends it.
/// Shared by the product page and the cart line that remembers the choice.
class CatalogVariantEntity extends Equatable {
  const CatalogVariantEntity({
    required this.id,
    required this.name,
    this.priceFils = 0,
    this.proPriceFils,
    this.compareAtFils,
    this.compareAtExpiresAt,
    this.stock = 0,
    this.enabled = true,
  });

  static const int _percent = 100;

  /// Variant id inside its product (`v1`); the cart line key adds it to the
  /// product id.
  final String id;

  /// Already resolved for the request language.
  final String name;
  final int priceFils;
  final int? proPriceFils;
  final int? compareAtFils;

  /// When the struck price stops applying; `null` = no end.
  final DateTime? compareAtExpiresAt;
  final int stock;
  final bool enabled;

  bool get isAvailable => enabled && stock > 0;

  bool get hasProPrice {
    final pro = proPriceFils;
    return pro != null && pro > 0 && pro < priceFils;
  }

  int priceFilsFor({required bool pro}) =>
      pro && hasProPrice ? proPriceFils! : priceFils;

  /// The struck price still valid at [now], else `null`.
  int? compareAtFilsAt(DateTime now) {
    final compareAt = compareAtFils;
    if (compareAt == null || compareAt <= priceFils) return null;
    final expiresAt = compareAtExpiresAt;
    if (expiresAt != null && !expiresAt.isAfter(now)) return null;
    return compareAt;
  }

  /// Whole percent off at [now]; `0` without a valid struck price.
  int discountPercentAt(DateTime now) {
    final compareAt = compareAtFilsAt(now);
    if (compareAt == null) return 0;
    return (((compareAt - priceFils) * _percent) / compareAt).round();
  }

  double get priceKd => priceFils / CatalogProductEntity.filsPerDinar;
  double priceKdFor({required bool pro}) =>
      priceFilsFor(pro: pro) / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    name,
    priceFils,
    proPriceFils,
    compareAtFils,
    compareAtExpiresAt,
    stock,
    enabled,
  ];
}
