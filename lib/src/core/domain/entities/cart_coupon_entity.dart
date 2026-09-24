import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// The coupon applied to the server cart (`GET /v1/cart` → `coupon`).
class CartCouponEntity extends Equatable {
  const CartCouponEntity({required this.code, this.discountFils = 0});

  /// `POST /v1/cart/coupon` accepts codes of this length range.
  static const int minCodeLength = 2;
  static const int maxCodeLength = 32;

  final String code;
  final int discountFils;

  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [code, discountFils];
}
