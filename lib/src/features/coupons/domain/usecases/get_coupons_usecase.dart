import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/coupon_buckets.dart';
import '../entities/coupon_dates.dart';
import '../repositories/coupons_repository.dart';

/// Load the user's coupons and bucket them into the three wallet tabs
/// (available / used / expired).
///
/// A coupon is **used** when its `used` flag is set, **expired** when its
/// expiry label marks it so or its date is before today ([now], injectable
/// for tests), otherwise **available**. A coupon stays available through the
/// whole day of its expiry date.
class GetCouponsUseCase implements UseCase<CouponBuckets, NoParams> {
  const GetCouponsUseCase(this._repository, {this._now = DateTime.now});

  final CouponsRepository _repository;
  final DateTime Function() _now;

  /// The legacy offline labels mark a lapsed coupon in the text itself.
  static const String _expiredMarker = 'expired';

  @override
  Future<Either<Failure, CouponBuckets>> call(NoParams params) async =>
      (await _repository.getCoupons()).map(_bucket);

  CouponBuckets _bucket(List<CouponEntity> all) {
    final available = <CouponEntity>[];
    final used = <CouponEntity>[];
    final expired = <CouponEntity>[];
    for (final coupon in all) {
      if (coupon.used) {
        used.add(coupon);
      } else if (_isExpired(coupon)) {
        expired.add(coupon);
      } else {
        available.add(coupon);
      }
    }
    return CouponBuckets(available: available, used: used, expired: expired);
  }

  /// An "Expired" marker in the label, or a label date before today.
  bool _isExpired(CouponEntity coupon) {
    if (coupon.expiry.toLowerCase().contains(_expiredMarker)) return true;
    final date = coupon.expiryDate;
    if (date == null) return false;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(DateTime(date.year, date.month, date.day));
  }
}
