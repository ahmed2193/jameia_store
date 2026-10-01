import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tracking_alert.dart';
import '../../domain/repositories/tracking_alerts_repository.dart';
import '../datasources/tracking_alerts_data_source.dart';

class TrackingAlertsRepositoryImpl
    with BaseRepositoryMixin
    implements TrackingAlertsRepository {
  const TrackingAlertsRepositoryImpl(this._source);

  final TrackingAlertsDataSource _source;

  @override
  Future<Either<Failure, bool>> allowed() => execute(_source.allowed);

  @override
  Future<Either<Failure, bool>> ask() => execute(_source.ask);

  @override
  Future<Either<Failure, Unit>> show(TrackingAlert alert) => execute(() async {
    await _source.show(alert);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> clearRide(String orderId) => execute(() async {
    await _source.clearRide(orderId);
    return unit;
  });
}
