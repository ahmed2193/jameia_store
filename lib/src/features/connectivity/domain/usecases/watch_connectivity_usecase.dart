import '../../../../core/usecase/usecase.dart';
import '../entities/connectivity_status.dart';
import '../repositories/connectivity_repository.dart';

/// The backend's reachability as it changes (raw: not debounced).
class WatchConnectivityUseCase
    implements StreamUseCase<ConnectivityStatus, NoParams> {
  const WatchConnectivityUseCase(this._repository);

  final ConnectivityRepository _repository;

  @override
  Stream<ConnectivityStatus> call(NoParams params) => _repository.watchStatus();
}
