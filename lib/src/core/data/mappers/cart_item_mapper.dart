import '../../domain/entities/cart_item_entity.dart';
import '../models/cart_item.dart';
import 'product_mapper.dart';
import 'product_variant_mapper.dart';

/// `CartItem` DTO ⇄ [CartItemEntity] (lossless both ways).
extension CartItemMapper on CartItem {
  CartItemEntity toEntity() => CartItemEntity(
    product: product.toEntity(),
    shopId: shopId,
    variant: variant?.toEntity(),
    qty: qty,
    unitPriceOverride: unitPriceOverride,
  );
}

extension CartItemListMapper on List<CartItem> {
  List<CartItemEntity> toEntities() =>
      map((i) => i.toEntity()).toList(growable: false);
}

/// Reverse map — cart lines flow back into local persistence
/// (`CartLineModel.fromCartItem`).
extension CartItemEntityMapper on CartItemEntity {
  CartItem toModel() => CartItem(
    product: product.toModel(),
    shopId: shopId,
    variant: variant?.toModel(),
    qty: qty,
    unitPriceOverride: unitPriceOverride,
  );
}

extension CartItemEntityListMapper on List<CartItemEntity> {
  List<CartItem> toModels() => map((i) => i.toModel()).toList(growable: false);
}
