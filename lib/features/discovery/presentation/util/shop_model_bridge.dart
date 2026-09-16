import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';

/// Presentation-side, entity → core-DTO bridge for the discovery channel screens.
///
/// The discovery feature owns framework-free [ShopEntity] / [ProductEntity]s,
/// but its screens hand shops/products to shared `core/widgets/*` surfaces
/// (`ShopCard`, `ProductCard`, `KeetaImage`) and the cross-feature `CartCubit`,
/// all of which require the core [Shop] / [Product] DTOs. Reconstructing the DTO
/// from the entity's raw fields at that boundary is a presentation concern, so
/// it lives here (not in the data layer) — the domain never leaks across the
/// shared boundary, and the data layer never depends on presentation.
///
/// The DTO is rebuilt from raw fields only, so its `easy_localization`-backed
/// display getters (`displayName`) resolve live off the active locale — a
/// language switch still flips the text on the next rebuild.

// TODO(P2.9-boundary): entity → core Shop reconstruction for the shared ShopCard
// / KeetaImage widgets. Remove once those shared widgets accept the entity type.
extension ShopEntityBridge on ShopEntity {
  Shop toModel() => Shop(
    id: id,
    name: name,
    nameAr: nameAr,
    logo: logo,
    cover: cover,
    kind: kind,
    rating: rating,
    ratingCount: ratingCount,
    deliveryFee: deliveryFee,
    deliveryTime: deliveryTime,
    distanceKm: distanceKm,
    minOrder: minOrder,
    tags: tags,
    promo: promo,
    freeDelivery: freeDelivery,
    sponsored: sponsored,
    sections: sections.map((s) => s.toModel()).toList(),
    promoTags: promoTags.map((t) => t.toModel()).toList(),
    featureLabels: featureLabels,
    notice: notice,
    isOpen: isOpen,
  );
}

extension MenuSectionEntityBridge on MenuSectionEntity {
  MenuSection toModel() => MenuSection(
    id: id,
    title: title,
    image: image,
    products: products.map((p) => p.toModel()).toList(),
  );
}

extension PromoTagEntityBridge on PromoTagEntity {
  PromoTag toModel() => PromoTag(text: text, bg: bg, fg: fg, style: style);
}

// TODO(P2.9-boundary): entity → core Product reconstruction for the shared
// ProductCard widget and the cross-feature CartCubit / quickAddToCart. Remove
// once those shared surfaces accept the entity type.
extension ProductEntityBridge on ProductEntity {
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
    variants: variants.map((v) => v.toModel()).toList(),
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

extension ProductEntityListBridge on List<ProductEntity> {
  List<Product> toModels() => map((p) => p.toModel()).toList();
}

extension ProductVariantEntityBridge on ProductVariantEntity {
  ProductVariant toModel() => ProductVariant(
    sku: sku,
    label: label,
    price: price,
    oldPrice: oldPrice,
    image: image,
    inStock: inStock,
  );
}
