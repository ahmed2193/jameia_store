import '../../../../core/data/models/models.dart';
import '../../domain/entities/shop_entity.dart';

/// DTO → entity mapping for the ordering shop. Lives in the data layer, so the
/// framework coupling of the core [Shop] DTO (its `easy_localization`-backed
/// `displayName`) never crosses into [ShopEntity]. The raw bilingual name is
/// carried; display resolution happens in presentation (`shop_display.dart`).
extension ShopMapper on Shop {
  ShopEntity toEntity() => ShopEntity(
        id: id,
        name: name,
        nameAr: nameAr,
        logo: logo,
        deliveryFee: deliveryFee,
        freeDelivery: freeDelivery,
      );
}
