import 'package:equatable/equatable.dart';

import 'jameia_address_entity.dart';
import 'shop_entity.dart';

/// First-frame snapshot the checkout screen needs before the user touches
/// anything: the ordering [shop], the delivery [address] shown in the address
/// bar, and how many coupons are available to apply (the red "N available"
/// badge on the coupons row). Loaded once through the checkout repository.
///
/// Holds framework-free entities ([ShopEntity] / [JameiaAddressEntity]) — the
/// core-DTO coupling stays behind the data-layer mappers.
class CheckoutContext extends Equatable {
  const CheckoutContext({
    required this.shop,
    required this.address,
    required this.availableCouponCount,
  });

  final ShopEntity shop;
  final JameiaAddressEntity address;

  /// Count of not-yet-used coupons (`coupons.where((c) => !c.used).length`).
  final int availableCouponCount;

  @override
  List<Object?> get props => [shop, address, availableCouponCount];
}
