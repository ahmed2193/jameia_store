import 'package:equatable/equatable.dart';

import 'cart_line_ref.dart';

/// One row of `POST /v1/cart/items` → `items[]`: add [quantity] of a product
/// (a variant product also names the variant). Built by the cart page and by
/// "reorder" on a past order, so it is shared.
class CartItemRequest extends Equatable {
  const CartItemRequest({
    required this.productId,
    this.variantId,
    this.quantity = 1,
  });

  /// `POST /v1/cart/items` accepts at most this many rows per call.
  static const int maxItemsPerRequest = 50;
  static const int minQuantity = 1;

  final String productId;
  final String? variantId;
  final int quantity;

  CartLineRef get ref => CartLineRef(productId, variantId);
  bool get isValid => productId.isNotEmpty && quantity >= minQuantity;

  @override
  List<Object?> get props => [productId, variantId, quantity];
}
