import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';

/// Cross-feature boundary escape: reconstruct the core [Product] DTO from a
/// framework-free [ProductEntity] so a search-rail tap can push the
/// product-details feature's `ProductDetailPage`, whose public constructor
/// accepts the CORE `Product`.
///
// TODO(P2.9-boundary): search owns framework-free entities, but the product
// detail push crosses into another feature whose screen contract is the core
// `Product` DTO. Per the parallel-rewrite boundary rule we do NOT propagate our
// entity across that seam — we rebuild the DTO here (lossless: all raw scalar
// fields + variants are carried on the entity). Drop this when product_details
// exposes an entity-typed constructor.
extension ProductEntityBoundary on ProductEntity {
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
    variants: variants.map((v) => v.toModel()).toList(growable: false),
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

extension _ProductVariantEntityBoundary on ProductVariantEntity {
  ProductVariant toModel() => ProductVariant(
    sku: sku,
    label: label,
    price: price,
    oldPrice: oldPrice,
    image: image,
    inStock: inStock,
  );
}
