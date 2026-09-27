import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/coupon_buckets.dart';

enum CouponsStatus { initial, loading, loaded, error }

/// State of a coupon screen: the coupons bucketed into available / used /
/// expired. My coupons and the history each read the buckets they render. [failure] is transient: every [copyWith] clears it.
class CouponsState extends Equatable {
  const CouponsState({
    this.status = CouponsStatus.initial,
    this.buckets = const CouponBuckets(),
    this.failure,
  });

  final CouponsStatus status;
  final CouponBuckets buckets;
  final Failure? failure;

  CouponsState copyWith({
    CouponsStatus? status,
    CouponBuckets? buckets,
    Failure? failure,
  }) => CouponsState(
    status: status ?? this.status,
    buckets: buckets ?? this.buckets,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, buckets, failure];
}
