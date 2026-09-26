import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/coupon_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/coupons_repository.dart';
import '../datasources/coupons_local_data_source.dart';

/// Offline coupons repository: the [CouponsLocalDataSource] DTOs mapped to
/// the shared [CouponEntity]; errors become failures through
/// [BaseRepositoryMixin].
class CouponsRepositoryImpl
    with BaseRepositoryMixin
    implements CouponsRepository {
  const CouponsRepositoryImpl(this._local);

  final CouponsLocalDataSource _local;

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() =>
      execute(() => _local.coupons().toEntities());
}
