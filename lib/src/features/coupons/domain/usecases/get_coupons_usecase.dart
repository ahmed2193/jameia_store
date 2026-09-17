import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/coupon.dart';
import '../entities/coupon_buckets.dart';
import '../repositories/coupons_repository.dart';

/// Load the user's coupons and bucket them into the three Jameia tabs
/// (available / used / expired).
///
/// This is the feature's core business rule (previously inline in
/// `CouponsCubit.load`): a coupon is **used** when its `used` flag is set,
/// **expired** when its expiry label marks it so, otherwise **available**.
class GetCouponsUseCase implements UseCase<CouponBuckets, NoParams> {
  final CouponsRepository repository;
  const GetCouponsUseCase(this.repository);

  @override
  Future<Either<Failure, CouponBuckets>> call(NoParams params) async {
    final result = await repository.getCoupons();
    return result.map(_bucket);
  }

  CouponBuckets _bucket(List<CouponEntity> all) {
    final available = <CouponEntity>[];
    final used = <CouponEntity>[];
    final expired = <CouponEntity>[];
    for (final c in all) {
      if (c.used) {
        used.add(c);
      } else if (_isExpired(c)) {
        expired.add(c);
      } else {
        available.add(c);
      }
    }
    return CouponBuckets(available: available, used: used, expired: expired);
  }

  /// Dummy data carries the human label only; treat an "Expired" marker in the
  /// expiry string as the expired bucket so all three tabs populate offline.
  static bool _isExpired(CouponEntity c) =>
      c.expiry.toLowerCase().contains('expired');
}
