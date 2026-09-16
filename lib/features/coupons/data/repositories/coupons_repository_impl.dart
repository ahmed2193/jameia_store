import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupons_repository.dart';
import '../datasources/coupons_local_data_source.dart';
import '../mappers/coupon_mapper.dart';

/// Offline coupons repository — reads the [CouponsLocalDataSource] DTOs, maps
/// them to framework-free [CouponEntity]s, and wraps the result in
/// `Either<Failure, T>`.
class CouponsRepositoryImpl implements CouponsRepository {
  CouponsRepositoryImpl({required this.local});

  final CouponsLocalDataSource local;

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() async {
    try {
      return Right(local.coupons().toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
