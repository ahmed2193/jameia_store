import 'package:equatable/equatable.dart';

/// Framework-free shop entity for the checkout feature.
///
/// Owned by the checkout feature (no reuse of the core `Shop` DTO, no
/// `easy_localization` / `intl`). Carries only the fields the checkout screen
/// needs (header logo + name, the delivery-fee inputs to the money math) plus
/// the raw bilingual name so the presentation layer resolves the active-locale
/// display **live** (see `presentation/util/shop_display.dart`).
class ShopEntity extends Equatable {
  const ShopEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.logo,
    required this.deliveryFee,
    required this.freeDelivery,
  });

  final String id;

  /// English / default name + its Arabic counterpart (resolved live in
  /// `shop_display.dart`).
  final String name;
  final String nameAr;

  final String logo;
  final double deliveryFee;
  final bool freeDelivery;

  /// Delivery fee actually charged — zero when the shop offers free delivery.
  /// Pure derivation, so it stays on the entity (money math, not display).
  double get effectiveDeliveryFee => freeDelivery ? 0.0 : deliveryFee;

  @override
  List<Object?> get props => [id, name, nameAr, logo, deliveryFee, freeDelivery];
}
