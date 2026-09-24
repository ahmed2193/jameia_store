import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// A free product an offer put in the cart (`GET /v1/cart` → `offerLines[]`);
/// the customer cannot edit it.
class CartOfferLineEntity extends Equatable {
  const CartOfferLineEntity({
    required this.key,
    required this.offerId,
    required this.product,
    this.offerName = '',
    this.quantity = 0,
  });

  final String key;
  final String offerId;
  final String offerName;
  final int quantity;
  final CatalogProductEntity product;

  @override
  List<Object?> get props => [key, offerId, offerName, quantity, product];
}
