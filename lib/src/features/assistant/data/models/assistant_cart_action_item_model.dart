import 'dart:developer';

import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/error/exceptions.dart';

/// One line of a `cart_action` block: `{ productId, variantId, quantity,
/// product? }` (`variantId` is always present, often `null`).
class AssistantCartActionItemModel {
  const AssistantCartActionItemModel({
    required this.productId,
    this.variantId,
    this.quantity = 1,
    this.product,
  });

  static const String productIdKey = 'productId';
  static const String variantIdKey = 'variantId';
  static const String quantityKey = 'quantity';
  static const String productKey = 'product';
  static const String _logName = 'AssistantCartActionItemModel';

  final String productId;
  final String? variantId;
  final int quantity;
  final ProductModel? product;

  /// Throws [ParsingException] without a `productId`. A malformed nested
  /// `product` only loses the picture and name, never the line.
  factory AssistantCartActionItemModel.fromJson(Map<String, dynamic> json) {
    final productId = JsonRead.string(json[productIdKey]);
    if (productId == null) {
      throw const ParsingException('cart_action item: productId missing');
    }
    return AssistantCartActionItemModel(
      productId: productId,
      variantId: JsonRead.string(json[variantIdKey]),
      quantity: JsonRead.integer(json[quantityKey]) ?? 1,
      product: _productOf(json[productKey]),
    );
  }

  static ProductModel? _productOf(Object? raw) {
    final json = JsonRead.object(raw);
    if (json == null) return null;
    try {
      return ProductModel.fromJson(json);
    } on AppException catch (error) {
      log('dropped line product: $error', name: _logName);
      return null;
    }
  }
}
