import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'courier_fix.dart';
import 'courier_stage.dart';
import 'courier_trip.dart';

/// Where the rider stands on the ride after one fix: how far along the
/// trip's whole [CourierTrip.path], the [stage] the customer reads, and the
/// whole minutes left to the door (rounded up, never 0 before the door —
/// "arriving now" is the rider being there).
class CourierProgress extends Equatable {
  const CourierProgress({
    required this.pathMeters,
    required this.deliveryStartMeters,
    required this.pathLengthMeters,
    required this.stage,
    required this.at,
    this.minutesLeft,
    this.secondsLeft,
  });

  /// [fix], already snapped to [pathMeters] of the trip's path. The stage is
  /// the feed's word, except that bringing the order becomes "almost there"
  /// within [nearbyMeters] of the door. The feed's own estimate wins; with
  /// none, the time left is the road left at [averageSpeedMps]. A rider who
  /// reports being at the store or the door is exactly there.
  factory CourierProgress.of(
    CourierTrip trip,
    CourierFix fix, {
    required double pathMeters,
  }) {
    final path = trip.path;
    final deliveryStart = trip.deliveryStartMeters;
    final along = switch (fix.state) {
      CourierFixState.assigning => 0.0,
      CourierFixState.atStore => deliveryStart,
      CourierFixState.arrived => path.lengthMeters,
      CourierFixState.toStore => math.min(
        path.clamp(pathMeters),
        deliveryStart,
      ),
      CourierFixState.onTheWay => math.max(
        path.clamp(pathMeters),
        deliveryStart,
      ),
      CourierFixState.other => path.clamp(pathMeters),
    };
    final left = path.lengthMeters - along;
    final stage = switch (fix.state) {
      CourierFixState.assigning => CourierStage.assigning,
      CourierFixState.toStore => CourierStage.toStore,
      CourierFixState.atStore => CourierStage.atStore,
      CourierFixState.arrived => CourierStage.arrived,
      CourierFixState.onTheWay || CourierFixState.other =>
        left <= nearbyMeters ? CourierStage.nearby : CourierStage.onTheWay,
    };
    final arrived = stage == CourierStage.arrived;
    return CourierProgress(
      pathMeters: along,
      deliveryStartMeters: deliveryStart,
      pathLengthMeters: path.lengthMeters,
      stage: stage,
      at: fix.at,
      minutesLeft: arrived
          ? null
          : wholeMinutes(fix.etaSeconds ?? left / averageSpeedMps),
      secondsLeft: arrived
          ? null
          : fix.etaSeconds ?? (left / averageSpeedMps).round(),
    );
  }

  /// A rider this close to the door (metres of road) is almost there.
  static const double nearbyMeters = 300;

  /// A city ride's average pace (≈ 22 km/h), for a fix with no estimate.
  static const double averageSpeedMps = 6;

  /// [seconds] as whole minutes, rounded up, at least 1.
  static int wholeMinutes(num seconds) =>
      math.max(1, (seconds / Duration.secondsPerMinute).ceil());

  /// The longest gap between two fixes the rider glides across; after a
  /// longer one (a pause, a reconnect) they step to the new fix.
  static const Duration longestGlide = Duration(seconds: 5);

  /// Metres of the whole path behind the rider.
  final double pathMeters;

  /// Where the store is on the path.
  final double deliveryStartMeters;
  final double pathLengthMeters;
  final CourierStage stage;

  /// When the fix was taken.
  final DateTime at;

  /// Whole minutes to the door, at least 1; `null` once arrived.
  final int? minutesLeft;

  /// The exact seconds to the door behind [minutesLeft] (the feed's own
  /// estimate, else the road left at [averageSpeedMps]); `null` once
  /// arrived. A countdown runs on these, so it never jumps back up by the
  /// rounding of the minutes.
  final int? secondsLeft;

  /// Metres of road to the door.
  double get remainingMeters => math.max(0, pathLengthMeters - pathMeters);

  /// Share of the store → door road behind the rider (0 before the store).
  double get deliveryFraction {
    final length = pathLengthMeters - deliveryStartMeters;
    if (length <= 0) return stage.delivering ? 1 : 0;
    return ((pathMeters - deliveryStartMeters) / length).clamp(0, 1).toDouble();
  }

  /// When the order should reach the door: [secondsLeft] after [at].
  DateTime? get arrivesAt {
    final seconds = secondsLeft;
    return seconds == null ? null : at.add(Duration(seconds: seconds));
  }

  /// How long the rider glides from [previous] to this fix: the time
  /// between the two, when it is above zero and at most [longestGlide];
  /// `null` for the first fix or after a longer gap (step, don't glide).
  Duration? glideFrom(CourierProgress? previous) {
    if (previous == null) return null;
    final gap = at.difference(previous.at);
    return gap > Duration.zero && gap <= longestGlide ? gap : null;
  }

  /// Share of the whole ride (to the store, then to the door) behind the
  /// rider.
  double get rideFraction => pathLengthMeters <= 0
      ? (arrived ? 1 : 0)
      : (pathMeters / pathLengthMeters).clamp(0, 1).toDouble();

  bool get arrived => stage == CourierStage.arrived;

  CourierProgress withMinutes(int? minutes) => CourierProgress(
    pathMeters: pathMeters,
    deliveryStartMeters: deliveryStartMeters,
    pathLengthMeters: pathLengthMeters,
    stage: stage,
    at: at,
    minutesLeft: minutes,
    secondsLeft: secondsLeft,
  );

  @override
  List<Object?> get props => [
    pathMeters,
    deliveryStartMeters,
    pathLengthMeters,
    stage,
    at,
    minutesLeft,
    secondsLeft,
  ];
}
