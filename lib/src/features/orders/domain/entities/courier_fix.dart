import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// What the rider is doing, as the live feed reports it: no rider yet, on
/// the way to the store, collecting the order, bringing it, at the door.
/// [other] catches a value this build does not know (read as "bringing it").
enum CourierFixState { assigning, toStore, atStore, onTheWay, arrived, other }

/// One report of the live feed (a GPS ping): where the rider is, when, what
/// they are doing, and the feed's own estimate of the time left to the door
/// when it sends one. While [CourierFixState.assigning] there is no rider:
/// the position is the store's.
class CourierFix extends Equatable {
  const CourierFix({
    required this.position,
    required this.at,
    this.state = CourierFixState.onTheWay,
    this.etaSeconds,
  });

  final GeoPointEntity position;
  final DateTime at;
  final CourierFixState state;

  /// Seconds until the door, everything before it included; `null` when the
  /// feed has no estimate.
  final int? etaSeconds;

  @override
  List<Object?> get props => [position, at, state, etaSeconds];
}
