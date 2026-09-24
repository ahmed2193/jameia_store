import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/region_options.dart';
import '../../domain/repositories/service_region_repository.dart';
import '../datasources/service_region_local_data_source.dart';
import '../mappers/service_region_mapper.dart';

class ServiceRegionRepositoryImpl
    with BaseRepositoryMixin
    implements ServiceRegionRepository {
  const ServiceRegionRepositoryImpl(this._local);

  final ServiceRegionLocalDataSource _local;

  @override
  Future<Either<Failure, RegionOptions>> getServiceRegions() => execute(
    () => RegionOptions(
      regions: _local.serviceRegions().toEntities(),
      activeRegion: _local.activeRegion(),
    ),
  );

  @override
  Future<Either<Failure, Unit>> switchRegion(String region) => execute(() {
    _local.switchRegion(region);
    return unit;
  });
}
