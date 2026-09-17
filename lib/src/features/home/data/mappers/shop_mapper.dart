import '../../../../core/data/models/models.dart';
import '../../domain/entities/shop_entity.dart';
import 'product_mapper.dart';

/// DTO → entity mapping for shops (and their nested menu sections + promo tags).
/// Lives in the data layer so the core `Shop` DTO's `easy_localization`-backed
/// display getters (`displayName`, `displayTags`) never cross into the domain
/// [ShopEntity]; presentation resolves those live off the raw fields carried
/// here (see `presentation/util/shop_display.dart`).
extension PromoTagMapper on PromoTag {
  PromoTagEntity toEntity() =>
      PromoTagEntity(text: text, bg: bg, fg: fg, style: style);
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
