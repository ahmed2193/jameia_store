import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/coupon_entity.dart';

/// The user's coupons partitioned into the three wallet tabs.
///
/// A pure domain snapshot built by `GetCouponsUseCase`: the Available / Used /
/// Expired tabs, the history feed and the checkout picker all read from it.
class CouponBuckets extends Equatable {
  const CouponBuckets({
    this.available = const [],
    this.used = const [],
    this.expired = const [],
  });

  /// Unused, still-valid coupons → "Available" tab / order picker.
  final List<CouponEntity> available;

  /// Coupons already redeemed → "Used" tab / history feed.
  final List<CouponEntity> used;

  /// Lapsed coupons → "Expired" tab / history feed.
  final List<CouponEntity> expired;

  /// The most the customer can still save (KD): every available coupon's
  /// discount added up.
  double get savingsUpTo =>
      available.fold<double>(0, (sum, coupon) => sum + coupon.amount);

  /// Nothing used and nothing expired yet (an empty history feed).
  bool get hasNoHistory => used.isEmpty && expired.isEmpty;

  /// The available coupon with [id], or `null` (no id, or not available).
  CouponEntity? availableById(String? id) {
    if (id == null) return null;
    for (final coupon in available) {
      if (coupon.id == id) return coupon;
    }
    return null;
  }

  @override
  List<Object?> get props => [available, used, expired];
}
