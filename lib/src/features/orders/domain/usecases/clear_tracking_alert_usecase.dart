import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/tracking_alerts_repository.dart';

class ClearTrackingAlertParams extends Equatable {
  const ClearTrackingAlertParams(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Takes an order's ride card out of the notification shade (the live map
/// closed: nothing follows the ride any more).
class ClearTrackingAlertUseCase
    implements UseCase<Unit, ClearTrackingAlertParams> {
  const ClearTrackingAlertUseCase(this._repository);

  final TrackingAlertsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ClearTrackingAlertParams params) =>
      _repository.clearRide(params.orderId);
}
