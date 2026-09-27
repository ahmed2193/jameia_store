import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// The coupon applied to the server cart (`GET /v1/cart` → `coupon`).
class CartCouponEntity extends Equatable {
  const CartCouponEntity({required this.code, this.discountFils = 0});

  /// `POST /v1/cart/coupon` accepts codes of this length range.
  static const int minCodeLength = 2;
  static const int maxCodeLength = 32;

  /// Whether [code], trimmed, has a length the API accepts: the one rule
  /// the apply use case and every code field check.
  static bool acceptsCode(String code) {
    final length = code.trim().length;
    return length >= minCodeLength && length <= maxCodeLength;
  }

  final String code;
  final int discountFils;

  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [code, discountFils];
}
