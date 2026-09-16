import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';

/// DTO → entity mapping for the discovery feature. Lives in the data layer, so
/// the framework coupling of the core [Shop] / [Product] DTOs (their
/// `easy_localization`-backed display getters) never crosses into the domain
/// entities, which stay plain Dart. The repository maps offline DTOs to
/// entities through these extensions.
///
/// The reverse direction (reconstructing the core DTO at the shared
/// `core/widgets/*` boundary) lives in `presentation/util/shop_model_bridge.dart`
/// — a presentation concern, so the data layer never depends on presentation.

extension PromoTagMapper on PromoTag {
  PromoTagEntity toEntity() =>
      PromoTagEntity(text: text, bg: bg, fg: fg, style: style);
}

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
    nameAr: nameAr,
    image: image,
    price: price,
    originalPrice: originalPrice,
    desc: desc,
    soldCount: soldCount,
    kcal: kcal,
    categoryId: categoryId,
    bestSelling: bestSelling,
    variants: variants.map((v) => v.toEntity()).toList(),
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

extension MenuSectionMapper on MenuSection {
  MenuSectionEntity toEntity() => MenuSectionEntity(
    id: id,
    title: title,
    image: image,
    products: products.map((p) => p.toEntity()).toList(),
  );
}

extension ShopMapper on Shop {
  ShopEntity toEntity() => ShopEntity(
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
    sections: sections.map((s) => s.toEntity()).toList(),
    promoTags: promoTags.map((t) => t.toEntity()).toList(),
    featureLabels: featureLabels,
    notice: notice,
    isOpen: isOpen,
  );
}

extension ShopListMapper on List<Shop> {
  List<ShopEntity> toEntities() => map((s) => s.toEntity()).toList();
}
