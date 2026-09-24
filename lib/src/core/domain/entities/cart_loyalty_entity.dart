import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// Loyalty points redeemed against the cart (`GET /v1/cart` → `loyalty`).
class CartLoyaltyEntity extends Equatable {
  const CartLoyaltyEntity({this.pointsApplied = 0, this.discountFils = 0});

  /// `POST /v1/cart/loyalty` needs at least this many points.
  static const int minPoints = 1;

  final int pointsApplied;
  final int discountFils;

  bool get isApplied => pointsApplied > 0;
  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [pointsApplied, discountFils];
}
