import 'shop.dart';

/// Runtime cart line — a [Product] plus quantity, scoped to a shop.
class CartItem {
  final Product product;
  final String shopId;
  int qty;

  CartItem({required this.product, required this.shopId, this.qty = 1});

  double get lineTotal => product.price * qty;
}
