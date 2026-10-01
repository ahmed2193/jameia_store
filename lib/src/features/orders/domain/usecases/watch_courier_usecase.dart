import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/courier_fix.dart';
import '../entities/courier_progress.dart';
import '../entities/courier_trip.dart';
import '../entities/steady_eta.dart';
import '../repositories/courier_tracking_repository.dart';

/// The rider's progress along [WatchCourierParams.trip], one value per fix,
/// the way live maps read a GPS feed:
///
/// * a fix no newer than the last one is dropped (a straggler after a
///   reconnect never rewinds the rider);
/// * each fix is snapped onto the road, forward only (a rider never drives
///   back, whatever GPS noise says) and no further than a rider could ride
///   since the fix before (noise never jumps them ahead to where the road
///   comes back past itself);
/// * the minutes are held steady ([SteadyEta]).
///
/// Ends with the ride; failures on the error channel.
class WatchCourierUseCase
    implements StreamUseCase<CourierProgress, WatchCourierParams> {
  const WatchCourierUseCase(this._repository);

  final CourierTrackingRepository _repository;

  @override
  Stream<CourierProgress> call(WatchCourierParams params) {
    final trip = params.trip;
    DateTime? last;
    // The time of the last fix read onto the road: sets how far on the next
    // one may land.
    DateTime? previousAt;
    var along = 0.0;
    var eta = const SteadyEta();
    return _repository
        .watchCourier(trip.orderId)
        .where((fix) {
          final previous = last;
          if (previous != null && !fix.at.isAfter(previous)) return false;
          last = fix.at;
          return true;
        })
        .map((fix) {
          // Each leg on its own: where the way to the store and the way to
          // the door share a street, noise never jumps the rider a leg.
          final deliveryStart = trip.deliveryStartMeters;
          final length = trip.path.lengthMeters;
          // No further than a rider could ride since the last fix: where the
          // road comes back past itself (a U-turn, a cul-de-sac), noise
          // never locks the rider onto the way back. The first fix (a map
          // opened mid-ride) may land anywhere.
          final since = previousAt;
          final reach = since == null
              ? double.infinity
              : math.max(
                  _minReachMeters,
                  fix.at.difference(since).inMilliseconds /
                      Duration.millisecondsPerSecond *
                      _maxRiderSpeedMps,
                );
          along = switch (fix.state) {
            CourierFixState.toStore => _project(
              trip,
              fix,
              from: math.min(along, deliveryStart),
              legEnd: deliveryStart,
              reach: reach,
            ),
            CourierFixState.onTheWay => _project(
              trip,
              fix,
              from: math.max(along, deliveryStart),
              legEnd: length,
              reach: reach,
            ),
            _ => _project(trip, fix, from: along, legEnd: length, reach: reach),
          };
          final progress = CourierProgress.of(trip, fix, pathMeters: along);
          along = progress.pathMeters;
          previousAt = fix.at;
          eta = eta.next(progress.minutesLeft);
          return progress.withMinutes(eta.minutes);
        });
  }

  /// The least road a fix may cover however soon it follows the last one:
  /// room for GPS error on top of the ride itself.
  static const double _minReachMeters = 60;

  /// Faster than any city rider (108 km/h): the most road per second a fix
  /// may cover.
  static const double _maxRiderSpeedMps = 30;

  /// [fix] on the road between [from] and [from] + [reach], never past
  /// [legEnd].
  static double _project(
    CourierTrip trip,
    CourierFix fix, {
    required double from,
    required double legEnd,
    required double reach,
  }) => trip.path.project(
    fix.position,
    from: from,
    to: math.min(legEnd, from + reach),
  );
}

class WatchCourierParams extends Equatable {
  const WatchCourierParams(this.trip);

  final CourierTrip trip;

  @override
  List<Object?> get props => [trip];
}
