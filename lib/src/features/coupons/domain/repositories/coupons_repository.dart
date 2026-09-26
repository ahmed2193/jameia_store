import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/error/failures.dart';

/// Read boundary for the user's coupons. Offline, the full coupon list resolves
/// from the in-memory catalogue (the jm3eia API has no coupon wallet yet).
/// Bucketing into available / used / expired is business logic and lives in
/// `GetCouponsUseCase`, not here.
abstract class CouponsRepository {
  /// The full, unbucketed coupon list.
  Future<Either<Failure, List<CouponEntity>>> getCoupons();
}
