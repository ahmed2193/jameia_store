import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';

/// DTO → entity mapping for products and their SKU variants. Lives in the data
/// layer, so the framework coupling of the core [Product] DTO (its
/// `easy_localization`-backed `displayName`) never crosses into the domain
/// [ProductEntity], which stays plain Dart. Display resolution happens in
/// presentation, off the raw `name` / `nameAr` carried here.
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

extension ProductMapper on Product {
  ProductEntity toEntity() => ProductEntity(
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
