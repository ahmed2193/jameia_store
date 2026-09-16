import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Framework-free promo-tag entity — a styled ribbon/coupon/pill shown on a shop
/// card. Mirrors the core `PromoTag` DTO as plain Dart so [ShopEntity] never
/// imports `core/data/models`.
class PromoTagEntity extends Equatable {
  const PromoTagEntity({
    required this.text,
    this.bg = '#D90012',
    this.fg = '#FFFFFF',
    this.style = 'ribbon',
  });

  final String text;
  final String bg; // hex
  final String fg; // hex
  final String style; // ribbon | coupon | pill

  @override
  List<Object?> get props => [text, bg, fg, style];
}

/// Framework-free menu-section entity — a rank/subcategory heading and its
/// [ProductEntity] rows. Held by [ShopEntity] so the shop carries its full menu
/// (the fixed-price channel derives its hot-selling grid from it).
class MenuSectionEntity extends Equatable {
  const MenuSectionEntity({
    this.id = '',
    required this.title,
    this.image = '',
    required this.products,
  });

  final String id;
  final String title;
  final String image;
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [id, title, image, products];
}

/// Framework-free shop entity — the central commerce model for the discovery
/// channel surfaces (channel list, KingKong landing, self-pickup, meal-for-one,
/// fixed-price host).
///
/// Owned by the discovery feature (no reuse of the core `Shop` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual name so display
/// resolves live off the reconstructed core model at the presentation boundary;
/// the tag / distance / kind derivations the use cases need (scene derivation,
/// distance sort, restaurant-vs-grocery host pick) live here.
class ShopEntity extends Equatable {
  const ShopEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.logo,
    required this.cover,
    required this.kind,
    required this.rating,
    required this.ratingCount,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.distanceKm,
    required this.minOrder,
    required this.tags,
    required this.promo,
    required this.freeDelivery,
    required this.sponsored,
    required this.sections,
    this.promoTags = const [],
    this.featureLabels = const [],
    this.notice = '',
    this.isOpen = true,
  });

  final String id;
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
  final List<MenuSectionEntity> sections;
  final List<PromoTagEntity> promoTags;
  final List<String> featureLabels;
  final String notice;
  final bool isOpen;

  bool get isRestaurant => kind == 'restaurant';

  List<ProductEntity> get allProducts =>
      sections.expand((s) => s.products).toList(growable: false);

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
    sections,
    promoTags,
    featureLabels,
    notice,
    isOpen,
  ];
}
