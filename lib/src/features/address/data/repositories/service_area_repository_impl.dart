import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/service_area.dart';
import '../../domain/repositories/service_area_repository.dart';
import '../datasources/service_area_local_data_source.dart';
import '../mappers/service_area_mapper.dart';

class ServiceAreaRepositoryImpl
    with BaseRepositoryMixin
    implements ServiceAreaRepository {
  ServiceAreaRepositoryImpl(this._local);

  final ServiceAreaLocalDataSource _local;

  /// The outline as entities (hundreds of corners), made once.
  ServiceArea? _area;

  @override
  Future<Either<Failure, ServiceArea>> serviceArea() =>
      execute(() async => _area ??= (await _local.area()).toEntity());
}
