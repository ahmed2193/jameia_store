import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/courier_fix.dart';
import '../entities/courier_trip.dart';
import '../entities/courier_trip_request.dart';

/// The rider's live position for the order page's map. The backend has no
/// rider feed yet, so the data layer plays a simulated ride behind this
/// contract; a live feed replaces it without touching anything above.
abstract class CourierTrackingRepository {
  /// The ride of the order in [request]: the store, the door, the road.
  Future<Either<Failure, CourierTrip>> getTrip(CourierTripRequest request);

  /// The rider's fixes as they come, until the ride ends; a [Failure] on
  /// the error channel.
  Stream<CourierFix> watchCourier(String orderId);
}
