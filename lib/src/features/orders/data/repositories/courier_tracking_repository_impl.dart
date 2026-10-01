import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/courier_fix.dart';
import '../../domain/entities/courier_trip.dart';
import '../../domain/entities/courier_trip_request.dart';
import '../../domain/repositories/courier_tracking_repository.dart';
import '../datasources/courier_tracking_data_source.dart';
import '../mappers/courier_tracking_mapper.dart';

class CourierTrackingRepositoryImpl
    with BaseRepositoryMixin
    implements CourierTrackingRepository {
  const CourierTrackingRepositoryImpl(this._source);

  final CourierTrackingDataSource _source;

  @override
  Future<Either<Failure, CourierTrip>> getTrip(CourierTripRequest request) =>
      execute(() async => (await _source.getTrip(request)).toEntity());

  @override
  Stream<CourierFix> watchCourier(String orderId) =>
      guardStream(_source.watchCourier(orderId).map((fix) => fix.toEntity()));
}
