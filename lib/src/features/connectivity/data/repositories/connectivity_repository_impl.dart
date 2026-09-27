import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/connectivity_status.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../datasources/connectivity_data_source.dart';

class ConnectivityRepositoryImpl
    with BaseRepositoryMixin
    implements ConnectivityRepository {
  const ConnectivityRepositoryImpl(this._dataSource);

  final ConnectivityDataSource _dataSource;

  @override
  Stream<ConnectivityStatus> watchStatus() =>
      guardStream(_dataSource.watchReachability().map(_statusOf));

  @override
  Future<Either<Failure, ConnectivityStatus>> checkNow() =>
      execute(() async => _statusOf(await _dataSource.checkNow()));

  @override
  Either<Failure, Unit> setMonitoring({required bool active}) =>
      executeSync(() {
        _dataSource.setMonitoring(active: active);
        return unit;
      });

  static ConnectivityStatus _statusOf(bool reachable) =>
      reachable ? ConnectivityStatus.online : ConnectivityStatus.offline;
}
