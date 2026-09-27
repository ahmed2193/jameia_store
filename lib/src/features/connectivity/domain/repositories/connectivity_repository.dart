import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/connectivity_status.dart';

/// Reachability of the backend (the device's monitor, no request of its own).
abstract class ConnectivityRepository {
  /// The current status (when one is known) and then every change of it;
  /// listening keeps the monitor running.
  Stream<ConnectivityStatus> watchStatus();

  /// Checks now and answers with what the check found.
  Future<Either<Failure, ConnectivityStatus>> checkNow();

  /// Stops ([active] false) or restarts the monitor's polling.
  Either<Failure, Unit> setMonitoring({required bool active});
}
