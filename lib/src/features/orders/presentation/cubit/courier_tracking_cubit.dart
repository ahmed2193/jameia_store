import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/courier_progress.dart';
import '../../domain/entities/courier_trip.dart';
import '../../domain/usecases/get_courier_trip_usecase.dart';
import '../../domain/usecases/watch_courier_usecase.dart';
import 'courier_tracking_state.dart';

/// The live map of an order's ride: reads the ride, then follows the rider
/// fix by fix until they are at the door — for as long as the page lives,
/// also under the rider chat sheet and while the app is in the background,
/// because the live notification follows the ride from these fixes (with a
/// backend, background moments arrive by push; the phone pauses a
/// backgrounded app on its own, and the feed catches up when it resumes).
///
/// * With no fix for [staleAfter] the state turns [CourierTrackingState.stale]
///   (the map says it is locating the rider); the next fix clears it.
/// * A feed that broke keeps the rider where they were last seen and tells
///   the failure once; the connection coming back ([onReconnected]) follows
///   the rider again.
class CourierTrackingCubit extends Cubit<CourierTrackingState>
    with SafeCubitMixin<CourierTrackingState> {
  CourierTrackingCubit({
    required this._getTrip,
    required this._watchCourier,
    this.staleAfter = defaultStaleAfter,
  }) : super(const CourierTrackingState());

  static const Duration defaultStaleAfter = Duration(seconds: 15);

  final GetCourierTripUseCase _getTrip;
  final WatchCourierUseCase _watchCourier;
  final Duration staleAfter;

  OrderEntity? _order;
  StreamSubscription<CourierProgress>? _feed;
  Timer? _watchdog;
  int _generation = 0;

  /// Whether the rider's fixes are being followed right now.
  bool get isFollowing => _feed != null;

  Future<void> start(OrderEntity order) async {
    _order = order;
    final generation = ++_generation;
    await _stopFeed();
    safeEmit(const CourierTrackingState());
    final result = await _getTrip(GetCourierTripParams(order));
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: CourierTrackingStatus.failed, failure: failure),
      ),
      (trip) {
        safeEmit(
          CourierTrackingState(status: CourierTrackingStatus.live, trip: trip),
        );
        _follow(trip);
      },
    );
  }

  /// The ride could not be read: ask again.
  Future<void> retry() async {
    final order = _order;
    if (order != null) await start(order);
  }

  /// The connection came back: a feed that broke on the way follows the
  /// rider again.
  void onReconnected() {
    final trip = state.trip;
    if (trip == null || _feed != null || state.arrived || isClosed) return;
    _follow(trip);
  }

  void _follow(CourierTrip trip) {
    if (isClosed) return;
    final generation = _generation;
    final feed = _watchCourier(WatchCourierParams(trip)).listen(
      (progress) {
        if (generation != _generation) return;
        safeEmit(state.copyWith(progress: progress, stale: false));
        _armWatchdog();
      },
      onError: (Object error) {
        if (generation != _generation) return;
        safeEmit(
          state.copyWith(
            stale: true,
            failure: error is Failure ? error : const UnexpectedFailure(),
          ),
        );
      },
      onDone: () {
        if (generation != _generation) return;
        _feed = null;
        _cancelWatchdog();
      },
    );
    _feed = feed;
    _armWatchdog();
  }

  void _armWatchdog() {
    _cancelWatchdog();
    if (state.arrived || isClosed) return;
    _watchdog = Timer(staleAfter, () {
      _watchdog = null;
      safeEmit(state.copyWith(stale: true));
    });
  }

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  Future<void> _stopFeed() async {
    _cancelWatchdog();
    final feed = _feed;
    _feed = null;
    await feed?.cancel();
  }

  @override
  Future<void> close() async {
    _generation++;
    await _stopFeed();
    return super.close();
  }
}
