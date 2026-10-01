import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/courier_progress.dart';
import '../../domain/entities/courier_stage.dart';
import '../../domain/entities/courier_trip.dart';

enum CourierTrackingStatus { loading, live, failed }

/// The live map: the ride ([trip]) once it is known, the rider's latest
/// [progress] along it, whether the feed has gone quiet ([stale]), and a
/// [failure] to tell — transient, cleared by every [copyWith].
class CourierTrackingState extends Equatable {
  const CourierTrackingState({
    this.status = CourierTrackingStatus.loading,
    this.trip,
    this.progress,
    this.stale = false,
    this.failure,
  });

  final CourierTrackingStatus status;
  final CourierTrip? trip;

  /// `null` until the first fix.
  final CourierProgress? progress;

  /// No fix for a while: the rider's place on the map is an old one.
  final bool stale;
  final Failure? failure;

  CourierStage? get stage => progress?.stage;
  bool get arrived => progress?.arrived ?? false;

  CourierTrackingState copyWith({
    CourierTrackingStatus? status,
    CourierTrip? trip,
    CourierProgress? progress,
    bool? stale,
    Failure? failure,
  }) => CourierTrackingState(
    status: status ?? this.status,
    trip: trip ?? this.trip,
    progress: progress ?? this.progress,
    stale: stale ?? this.stale,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, trip, progress, stale, failure];
}
