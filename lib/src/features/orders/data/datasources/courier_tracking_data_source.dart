import '../../domain/entities/courier_trip_request.dart';
import '../models/courier_fix_model.dart';
import '../models/courier_trip_model.dart';

/// Where the live map reads the rider from. The backend has no rider feed
/// yet (`docs/api_integration.md` §6.1), so the only implementation is the
/// simulated `DemoCourierTrackingDataSource`; a remote one on the API
/// (a route for the ride, an event stream for the fixes) takes its place
/// with the same DTOs.
abstract class CourierTrackingDataSource {
  /// The ride of [request]'s order. Throws an `AppException`.
  Future<CourierTripModel> getTrip(CourierTripRequest request);

  /// The rider's fixes until the ride ends. A malformed frame is logged and
  /// skipped; errors are `AppException`s.
  Stream<CourierFixModel> watchCourier(String orderId);
}
