import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/tracking_alerts_repository.dart';

/// Whether the live ride can be shown in the notification shade (the
/// customer let the app post notifications).
class CheckTrackingAlertsUseCase implements UseCase<bool, NoParams> {
  const CheckTrackingAlertsUseCase(this._repository);

  final TrackingAlertsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) => _repository.allowed();
}
