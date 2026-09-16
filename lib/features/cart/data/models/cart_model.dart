import '../../../../core/data/models/models.dart';

/// Serializable snapshot of one cart line — persists only identity + qty + the
/// price snapshot, NOT the whole [Product] (rehydrated from the catalogue on
/// load, so a catalogue update never ships stale product data in the cart).
class CartLineModel {
  final String productId;
  final String? variantSku;
  final String shopId;
  final int qty;
  final double? unitPriceOverride;

  const CartLineModel({
    required this.productId,
    required this.shopId,
    required this.qty,
    this.variantSku,
    this.unitPriceOverride,
  });

  factory CartLineModel.fromCartItem(CartItem item) => CartLineModel(
        productId: item.product.id,
        variantSku: item.variant?.sku,
        shopId: item.shopId,
        qty: item.qty,
        unitPriceOverride: item.unitPriceOverride,
      );

  factory CartLineModel.fromJson(Map<String, dynamic> j) => CartLineModel(
        productId: j['productId'] as String,
        variantSku: j['variantSku'] as String?,
        shopId: j['shopId'] as String,
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        unitPriceOverride: (j['unitPriceOverride'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        if (variantSku != null) 'variantSku': variantSku,
        'shopId': shopId,
        'qty': qty,
        if (unitPriceOverride != null) 'unitPriceOverride': unitPriceOverride,
      };
}

/// The whole persisted cart (all lines + the owning shop).
class CartModel {
  final String? shopId;
  final List<CartLineModel> lines;

  const CartModel({this.shopId, this.lines = const []});

  factory CartModel.fromJson(Map<String, dynamic> j) => CartModel(
        shopId: j['shopId'] as String?,
        lines: (j['lines'] as List?)
                ?.map((e) => CartLineModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        if (shopId != null) 'shopId': shopId,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}
