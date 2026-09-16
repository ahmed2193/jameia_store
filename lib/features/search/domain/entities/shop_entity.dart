import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Framework-free shop entity owned by the search feature (no reuse of the core
/// `Shop` DTO, no `easy_localization` / `intl`). Carries the raw bilingual name
/// so the presentation layer resolves the active-locale display **live** (see
/// `presentation/util/shop_display.dart`).
///
/// [products] is the flattened menu (the core `Shop.allProducts`) — the search
/// result card renders a rail off it and the promo strip/filters derive from it.
class ShopEntity extends Equatable {
  const ShopEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.logo,
    this.cover = '',
    required this.kind,
    required this.rating,
    required this.ratingCount,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.distanceKm,
    this.minOrder = 0,
    this.tags = const [],
    this.promo = '',
    required this.freeDelivery,
    this.sponsored = false,
    this.products = const [],
  });

  final String id;

  /// English / default name + its Arabic counterpart (resolved live in
  /// presentation via `ShopDisplay.displayName`).
  final String name;
  final String nameAr;

  final String logo;
  final String cover;
  final String kind; // restaurant | grocery
  final double rating;
  final int ratingCount;
  final double deliveryFee;
  final String deliveryTime;
  final double distanceKm;
  final double minOrder;
  final List<String> tags;
  final String promo;
  final bool freeDelivery;
  final bool sponsored;

  /// Flattened menu products (== core `Shop.allProducts`).
  final List<ProductEntity> products;

  bool get isRestaurant => kind == 'restaurant';

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        logo,
        cover,
        kind,
        rating,
        ratingCount,
        deliveryFee,
        deliveryTime,
        distanceKm,
        minOrder,
        tags,
        promo,
        freeDelivery,
        sponsored,
        products,
      ];
}
