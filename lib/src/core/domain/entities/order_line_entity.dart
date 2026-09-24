import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'catalog_product_entity.dart';

/// One paid line of an order (`lines[]`): the product as it was sold, with
/// both languages so a language switch re-labels the receipt in place.
class OrderLineEntity extends Equatable {
  const OrderLineEntity({
    required this.key,
    required this.productId,
    this.nameEn = '',
    this.nameAr = '',
    this.image = '',
    this.productType = '',
    this.variantId,
    this.variantNameEn = '',
    this.variantNameAr = '',
    this.sku,
    this.quantity = 0,
    this.unitPriceFils = 0,
    this.lineTotalFils = 0,
  });

  final String key;
  final String productId;
  final String nameEn;
  final String nameAr;
  final String image;
  final String productType;
  final String? variantId;
  final String variantNameEn;
  final String variantNameAr;
  final String? sku;
  final int quantity;
  final int unitPriceFils;
  final int lineTotalFils;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);

  /// Empty when the line has no variant.
  String variantNameFor(String languageCode) =>
      pickLocalized(languageCode, en: variantNameEn, ar: variantNameAr);

  double get unitPriceKd => unitPriceFils / CatalogProductEntity.filsPerDinar;
  double get lineTotalKd => lineTotalFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    key,
    productId,
    nameEn,
    nameAr,
    image,
    productType,
    variantId,
    variantNameEn,
    variantNameAr,
    sku,
    quantity,
    unitPriceFils,
    lineTotalFils,
  ];
}

/// A free product an offer added to the order (`offerLines[]`).
class OrderOfferLineEntity extends Equatable {
  const OrderOfferLineEntity({
    required this.productId,
    required this.offerId,
    this.nameEn = '',
    this.nameAr = '',
    this.image = '',
    this.offerNameEn = '',
    this.offerNameAr = '',
    this.quantity = 0,
  });

  final String productId;
  final String offerId;
  final String nameEn;
  final String nameAr;
  final String image;
  final String offerNameEn;
  final String offerNameAr;
  final int quantity;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);
  String offerNameFor(String languageCode) =>
      pickLocalized(languageCode, en: offerNameEn, ar: offerNameAr);

  @override
  List<Object?> get props => [
    productId,
    offerId,
    nameEn,
    nameAr,
    image,
    offerNameEn,
    offerNameAr,
    quantity,
  ];
}

/// An offer applied to the order (`appliedOffers[]`).
class OrderAppliedOfferEntity extends Equatable {
  const OrderAppliedOfferEntity({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
    this.rewardType = '',
    this.discountFils = 0,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String rewardType;
  final int discountFils;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);
  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [id, nameEn, nameAr, rewardType, discountFils];
}
