import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Framework-free promo-tag entity — a styled promotional chip carried on a
/// [ShopEntity]. Plain raw fields (hex colours stay strings); the presentation
/// layer maps this back to the core `PromoTag` only at the shared `PromoRibbon`
/// boundary.
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

/// Framework-free menu section entity — a rank/sub-category strip of products
/// on a [ShopEntity].
class MenuSectionEntity extends Equatable {
  const MenuSectionEntity({
    this.id = '',
    required this.title,
    this.image = '',
    this.products = const [],
  });

  final String id;
  final String title;
  final String image;
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [id, title, image, products];
}

/// Framework-free shop entity.
///
/// Owned by the home feature (no reuse of the core `Shop` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual name so presentation
/// resolves the active-locale display **live** (see
/// `presentation/util/shop_display.dart`). Pure derivations (`isRestaurant`,
/// `allProducts`, `maxDiscountPercent`) live here; the locale-live promo-tag /
/// feature synthesis lives in the display extension.
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

  int get maxDiscountPercent {
    var m = 0;
    for (final p in allProducts) {
      if (p.discountPercent > m) m = p.discountPercent;
    }
    return m;
  }

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
