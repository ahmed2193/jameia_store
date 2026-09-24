import 'package:equatable/equatable.dart';

/// What identifies a cart line for the customer: the product plus, for a
/// variant product, the chosen variant. The server's line `key` is only known
/// once the line exists there, so local pending changes are keyed by this.
class CartLineRef extends Equatable {
  const CartLineRef(this.productId, [this.variantId]);

  final String productId;
  final String? variantId;

  @override
  List<Object?> get props => [productId, variantId];

  @override
  String toString() => variantId == null ? productId : '$productId/$variantId';
}
