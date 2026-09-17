import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'menu_section_entity.dart';
import 'product_entity.dart';
import 'promo_tag_entity.dart';

/// Shared shop / restaurant / grocery store and its menu — the central commerce
/// entity (home feed, discovery channels, search, shop page, checkout header).
///
/// Carries the raw bilingual name; the visible name is resolved with [nameFor].
/// Defaults mirror the `Shop.fromJson` fallbacks so slim call sites (e.g. the
/// checkout header) can build one with only the fields they need.
class ShopEntity extends Equatable {
  const ShopEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.logo = '',
    this.cover = '',
    this.kind = 'restaurant',
    this.rating = 0,
    this.ratingCount = 0,
    this.deliveryFee = 0,
    this.deliveryTime = '',
    this.distanceKm = 0,
    this.minOrder = 0,
    this.tags = const [],
    this.promo = '',
    this.freeDelivery = false,
    this.sponsored = false,
    this.sections = const [],
    this.promoTags = const [],
    this.featureLabels = const [],
    this.notice = '',
    this.isOpen = true,
  });

  final String id;

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;
  final String logo;
  final String cover;

  /// restaurant | grocery.
  final String kind;
  final double rating;
  final int ratingCount;
  final double deliveryFee;

  /// Display string (e.g. `'15-25 min'`).
  final String deliveryTime;
  final double distanceKm;
  final double minOrder;
  final List<String> tags;
  final String promo;
  final bool freeDelivery;
  final bool sponsored;
  final List<MenuSectionEntity> sections;

  /// Explicit styled promo ribbons/coupons (empty → synthesized by
  /// [resolvedPromoTags]).
  final List<PromoTagEntity> promoTags;

  /// Feature labels (e.g. "Buy 1 Get 1").
  final List<String> featureLabels;

  /// Optional notice/status line (e.g. "Opens at 10:00").
  final String notice;

  /// Whether the shop is currently open (false → dim cover + closed overlay).
  final bool isOpen;

  /// Active-locale name: Arabic when [languageCode] is `ar*` and [nameAr] is
  /// non-blank, else [name].
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  bool get isRestaurant => kind == 'restaurant';

  /// Delivery fee actually charged — zero when the shop offers free delivery.
  double get effectiveDeliveryFee => freeDelivery ? 0.0 : deliveryFee;

  /// Every product across [sections] (the flattened menu).
  List<ProductEntity> get allProducts =>
      sections.expand((s) => s.products).toList(growable: false);

  /// Highest discount percent across the menu (0 when nothing is discounted).
  int get maxDiscountPercent {
    var m = 0;
    for (final p in allProducts) {
      if (p.discountPercent > m) m = p.discountPercent;
    }
    return m;
  }

  /// Promo tags to render on the golden feed card / shop meta — explicit
  /// [promoTags] when present, otherwise synthesized from shop state. Same rule
  /// as the `Shop.displayTags` DTO getter, with the two localized labels
  /// injected by the caller so the domain stays i18n-free:
  /// - [upToOffLabel] receives the max discount percent (used when >= 5),
  ///   e.g. `(p) => 'catalog.up_to_off'.tr(namedArgs: {'percent': '$p'})`;
  /// - [freeDeliveryLabel], e.g. `'catalog.free_delivery'.tr()`.
  List<PromoTagEntity> resolvedPromoTags({
    required String Function(int percent) upToOffLabel,
    required String freeDeliveryLabel,
  }) {
    if (promoTags.isNotEmpty) return promoTags;
    final out = <PromoTagEntity>[];
    final maxOff = maxDiscountPercent;
    if (maxOff >= 5) {
      out.add(PromoTagEntity(text: upToOffLabel(maxOff)));
    } else if (promo.isNotEmpty) {
      out.add(PromoTagEntity(text: promo));
    }
    if (freeDelivery) {
      out.add(
        PromoTagEntity(
          text: freeDeliveryLabel,
          bg: '#E2F6F0',
          fg: '#008C65',
          style: 'coupon',
        ),
      );
    }
    return out;
  }

  /// Feature labels — explicit [featureLabels] when present, else the first
  /// two [tags].
  List<String> get displayFeatures => featureLabels.isNotEmpty
      ? featureLabels
      : tags.take(2).toList(growable: false);

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
