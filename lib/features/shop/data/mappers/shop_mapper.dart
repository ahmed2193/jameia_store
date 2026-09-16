import '../../../../core/data/models/models.dart';
import '../../domain/entities/menu_section_entity.dart';
import '../../domain/entities/promo_tag_entity.dart';
import '../../domain/entities/shop_entity.dart';
import 'product_mapper.dart';

/// DTO → entity mapping for the shop graph (shop → sections → products, plus
/// promo tags). Lives in the data layer, so the core [Shop] DTO's
/// `easy_localization`-backed display getters never cross into the framework-free
/// [ShopEntity]. Presentation resolves the visible name off the raw
/// `name` / `nameAr` carried here (see `presentation/util/shop_display.dart`).
extension PromoTagMapper on PromoTag {
  PromoTagEntity toEntity() =>
      PromoTagEntity(text: text, bg: bg, fg: fg, style: style);
}

extension PromoTagListMapper on List<PromoTag> {
  List<PromoTagEntity> toEntities() =>
      map((t) => t.toEntity()).toList(growable: false);
}

extension MenuSectionMapper on MenuSection {
  MenuSectionEntity toEntity() => MenuSectionEntity(
        id: id,
        title: title,
        image: image,
        products: products.toEntities(),
      );
}

extension MenuSectionListMapper on List<MenuSection> {
  List<MenuSectionEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
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
