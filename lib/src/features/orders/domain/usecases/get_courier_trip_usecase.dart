import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/courier_trip.dart';
import '../entities/courier_trip_request.dart';
import '../repositories/courier_tracking_repository.dart';

/// The ride the live map follows for [GetCourierTripParams.order]: asked
/// with what the order knows (its door, its driver).
class GetCourierTripUseCase
    implements UseCase<CourierTrip, GetCourierTripParams> {
  const GetCourierTripUseCase(this._repository);

  final CourierTrackingRepository _repository;

  @override
  Future<Either<Failure, CourierTrip>> call(GetCourierTripParams params) {
    if (params.order.id.isEmpty) {
      return Future.value(const Left(ValidationFailure('order id')));
    }
    return _repository.getTrip(CourierTripRequest.of(params.order));
  }
}

class GetCourierTripParams extends Equatable {
  const GetCourierTripParams(this.order);

  final OrderEntity order;

  @override
  List<Object?> get props => [order];
}
