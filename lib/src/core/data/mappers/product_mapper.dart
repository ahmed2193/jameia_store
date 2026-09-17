import '../../domain/entities/product_entity.dart';
import '../models/shop.dart';
import 'product_variant_mapper.dart';

/// Per-instance memo of mapped products. The jameia loader shares ONE `Product`
/// instance per sku across every rank / featured section, and the DTO is
/// immutable, so a mapped entity can be reused: re-mapping the same catalogue
/// graph (home feed reload, shop page open, search) allocates nothing new and
/// keeps entity identity shared the same way the DTO graph does. Weak keys —
/// entries die with their DTO.
final Expando<ProductEntity> _productEntities = Expando<ProductEntity>();

/// `Product` DTO ⇄ [ProductEntity] (lossless both ways — every raw field incl.
/// variants is carried).
extension ProductMapper on Product {
  ProductEntity toEntity() => _productEntities[this] ??= _map();

  ProductEntity _map() => ProductEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    image: image,
    price: price,
    originalPrice: originalPrice,
    desc: desc,
    soldCount: soldCount,
    kcal: kcal,
    categoryId: categoryId,
    bestSelling: bestSelling,
    variants: variants.toEntities(),
    vipPrice: vipPrice,
    available: available,
    maxQty: maxQty,
    showDiscount: showDiscount,
    firstUnitsQty: firstUnitsQty,
    gallery: gallery,
    brand: brand,
    weight: weight,
    storage: storage,
  );
}

extension ProductListMapper on List<Product> {
  List<ProductEntity> toEntities() =>
      map((p) => p.toEntity()).toList(growable: false);
}

/// Reverse map — rebuilds the catalogue DTO for the cart persistence path
/// (see `CartItemEntityMapper.toModel`).
extension ProductEntityMapper on ProductEntity {
  Product toModel() => Product(
    id: id,
    name: name,
    nameAr: nameAr,
    image: image,
    price: price,
    originalPrice: originalPrice,
    desc: desc,
    soldCount: soldCount,
    kcal: kcal,
    categoryId: categoryId,
    bestSelling: bestSelling,
    variants: variants.toModels(),
    vipPrice: vipPrice,
    available: available,
    maxQty: maxQty,
    showDiscount: showDiscount,
    firstUnitsQty: firstUnitsQty,
    gallery: gallery,
    brand: brand,
    weight: weight,
    storage: storage,
  );
}

extension ProductEntityListMapper on List<ProductEntity> {
  List<Product> toModels() => map((p) => p.toModel()).toList(growable: false);
}
