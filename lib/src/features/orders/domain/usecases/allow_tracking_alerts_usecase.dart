import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/tracking_alerts_repository.dart';

/// Asks the customer — when they chose to, from the live map — to let the
/// app post the ride's notifications; `true` when they do.
class AllowTrackingAlertsUseCase implements UseCase<bool, NoParams> {
  const AllowTrackingAlertsUseCase(this._repository);

  final TrackingAlertsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) => _repository.ask();
}
