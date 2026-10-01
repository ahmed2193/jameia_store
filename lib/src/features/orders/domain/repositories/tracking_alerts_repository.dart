import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/tracking_alert.dart';

/// The phone's notification shade, for the live ride of an order.
abstract class TrackingAlertsRepository {
  /// Whether the customer lets the app post notifications.
  Future<Either<Failure, bool>> allowed();

  /// Asks the customer to let it; `true` when they do.
  Future<Either<Failure, bool>> ask();

  /// Posts [alert] (a ride card updates in place).
  Future<Either<Failure, Unit>> show(TrackingAlert alert);

  /// Takes the ride card of [orderId] away.
  Future<Either<Failure, Unit>> clearRide(String orderId);
}
