import 'package:equatable/equatable.dart';

import 'menu_section_entity.dart';
import 'product_entity.dart';
import 'promo_tag_entity.dart';

/// Framework-free shop entity — the central commerce model, owned by the shop
/// feature (no reuse of the core `Shop` DTO, no `easy_localization` / `intl`).
///
/// Carries the raw bilingual `name` / `nameAr` so presentation resolves the
/// active-locale display **live** (see `presentation/util/shop_display.dart`);
/// a language switch then flips the visible name on the next rebuild without
/// reloading the cubit. All other fields are plain primitives / entity lists.
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

  /// English / default name + its Arabic counterpart (resolved live in
  /// presentation, never frozen here).
  final String name;
  final String nameAr;

  final String logo;
  final String cover;

  /// restaurant | grocery.
  final String kind;
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

  /// Styled promo ribbons/coupons rendered on the card.
  final List<PromoTagEntity> promoTags;

  /// Feature labels (e.g. "Buy 1 Get 1", "Low delivery fee").
  final List<String> featureLabels;

  /// Optional notice/status line (e.g. "Opens at 10:00").
  final String notice;

  /// Whether the shop is currently open.
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
