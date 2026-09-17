import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_entity.dart';

/// DTO ⇄ entity mapping for products. Lives in the data layer, so the framework
/// coupling of the core [Product] DTO (its `easy_localization`-backed
/// `displayName`) never crosses into the domain [ProductEntity].
///
/// The reverse [ProductEntityMapper.toModel] is the single point that rebuilds a
/// core [Product] — used at the cart (`quickAddToCart`) / product-detail
/// (`ProductDetailPage`) boundary, which still consume the core DTO.
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

extension ProductMapper on Product {
  ProductEntity toEntity() => ProductEntity(
    id: id,
    name: name,
    image: image,
    price: price,
    originalPrice: originalPrice,
    desc: desc,
    soldCount: soldCount,
    kcal: kcal,
    categoryId: categoryId,
    bestSelling: bestSelling,
    variants: variants.map((v) => v.toEntity()).toList(),
    nameAr: nameAr,
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
  List<ProductEntity> toEntities() => map((p) => p.toEntity()).toList();
}

// ── Reverse (entity → core DTO), used only at the cross-feature boundary ──────

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

extension ProductEntityMapper on ProductEntity {
  Product toModel() => Product(
    id: id,
    name: name,
    image: image,
    price: price,
    originalPrice: originalPrice,
    desc: desc,
    soldCount: soldCount,
    kcal: kcal,
    categoryId: categoryId,
    bestSelling: bestSelling,
    variants: variants.map((v) => v.toModel()).toList(),
    nameAr: nameAr,
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
