import '../../domain/entities/product_variant_entity.dart';
import '../models/shop.dart';

/// `ProductVariant` DTO ⇄ [ProductVariantEntity] (lossless both ways).
extension ProductVariantMapper on ProductVariant {
  ProductVariantEntity toEntity() => ProductVariantEntity(
    sku: sku,
    label: label,
    price: price,
    oldPrice: oldPrice,
    image: image,
    inStock: inStock,
  );
}

extension ProductVariantListMapper on List<ProductVariant> {
  List<ProductVariantEntity> toEntities() =>
      map((v) => v.toEntity()).toList(growable: false);
}

/// Reverse map — used where a cart line flows back into local persistence
/// (see `CartItemEntityMapper.toModel`).
extension ProductVariantEntityMapper on ProductVariantEntity {
  ProductVariant toModel() => ProductVariant(
    sku: sku,
    label: label,
    price: price,
    oldPrice: oldPrice,
    image: image,
    inStock: inStock,
  );
}

extension ProductVariantEntityListMapper on List<ProductVariantEntity> {
  List<ProductVariant> toModels() =>
      map((v) => v.toModel()).toList(growable: false);
}
