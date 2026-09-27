import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/connectivity_repository.dart';

/// Pauses the reachability polling while the app is in the background (zero
/// probes there) and resumes it — with an immediate check — on return.
class SetConnectivityMonitoringUseCase
    implements SyncUseCase<Unit, SetConnectivityMonitoringParams> {
  const SetConnectivityMonitoringUseCase(this._repository);

  final ConnectivityRepository _repository;

  @override
  Either<Failure, Unit> call(SetConnectivityMonitoringParams params) =>
      _repository.setMonitoring(active: params.active);
}

class SetConnectivityMonitoringParams extends Equatable {
  const SetConnectivityMonitoringParams({required this.active});

  final bool active;

  @override
  List<Object?> get props => [active];
}
