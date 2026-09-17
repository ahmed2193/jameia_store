import '../../../../core/data/models/models.dart';
import '../../domain/entities/shop_entity.dart';
import 'product_mapper.dart';

/// DTO → entity mapping for shops. Lives in the data layer, so the framework
/// coupling of the core [Shop] DTO (its `easy_localization`-backed `displayName`)
/// never crosses into the domain [ShopEntity], which stays plain Dart. The
/// flattened menu (`allProducts`) is mapped through [ProductMapper].
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
    products: allProducts.toEntities(),
  );
}

/// Convenience for mapping the whole list.
extension ShopListMapper on List<Shop> {
  List<ShopEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
}
