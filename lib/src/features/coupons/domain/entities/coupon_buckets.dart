import 'package:equatable/equatable.dart';

import 'coupon.dart';

/// The user's coupons partitioned into the three Jameia tabs.
///
/// A pure domain snapshot built by [GetCouponsUseCase]: it carries the
/// bucketing result the presentation layer renders as the Available / Used /
/// Expired tabs and the history feed, over the framework-free [CouponEntity].
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

  @override
  List<Object?> get props => [available, used, expired];
}
