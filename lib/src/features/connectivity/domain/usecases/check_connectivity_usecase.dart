import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/connectivity_status.dart';
import '../repositories/connectivity_repository.dart';

/// Checks reachability now (the banner's "try again", the place-order
/// confirmation) instead of waiting for the next poll.
class CheckConnectivityUseCase
    implements UseCase<ConnectivityStatus, NoParams> {
  const CheckConnectivityUseCase(this._repository);

  final ConnectivityRepository _repository;

  @override
  Future<Either<Failure, ConnectivityStatus>> call(NoParams params) =>
      _repository.checkNow();
}
