import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/tracking_alert.dart';
import '../repositories/tracking_alerts_repository.dart';

class ShowTrackingAlertParams extends Equatable {
  const ShowTrackingAlertParams(this.alert);

  final TrackingAlert alert;

  @override
  List<Object?> get props => [alert];
}

/// Posts a ride card or a moment to the notification shade.
class ShowTrackingAlertUseCase
    implements UseCase<Unit, ShowTrackingAlertParams> {
  const ShowTrackingAlertUseCase(this._repository);

  final TrackingAlertsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ShowTrackingAlertParams params) =>
      _repository.show(params.alert);
}
