import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/coupon.dart';

/// Read boundary for the user's coupons. Offline, the full coupon list resolves
/// from the in-memory catalogue (mapped to framework-free [CouponEntity]s); it
/// still returns `Either<Failure, T>` so the presentation layer handles failure
/// uniformly. Bucketing into available / used / expired is business logic and
/// lives in [GetCouponsUseCase], not here.
abstract class CouponsRepository {
  /// The full, unbucketed coupon list from the offline catalogue.
  Future<Either<Failure, List<CouponEntity>>> getCoupons();
}
