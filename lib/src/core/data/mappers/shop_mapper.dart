import '../../domain/entities/shop_entity.dart';
import '../models/shop.dart';
import 'menu_section_mapper.dart';
import 'promo_tag_mapper.dart';

/// `Shop` DTO → [ShopEntity] (full graph: sections → products, promo tags).
///
/// Read-only: shops never flow back into a `JameiaRepository` write API, so no
/// reverse mapper exists.
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
    sections: sections.toEntities(),
    promoTags: promoTags.toEntities(),
    featureLabels: featureLabels,
    notice: notice,
    isOpen: isOpen,
  );
}

extension ShopListMapper on List<Shop> {
  List<ShopEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
}
