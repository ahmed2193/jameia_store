import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/tracking_alert.dart';
import '../../domain/usecases/allow_tracking_alerts_usecase.dart';
import '../../domain/usecases/check_tracking_alerts_usecase.dart';
import '../../domain/usecases/clear_tracking_alert_usecase.dart';
import '../../domain/usecases/show_tracking_alert_usecase.dart';
import 'tracking_alerts_state.dart';

/// The live map's notifications: whether the app may post them, the prompt
/// that asks — only when the customer taps it, never on its own — and the
/// ride card and moments the page composes. Closing takes the ride card
/// away: nothing follows the ride once the map is gone (a moment already
/// posted, such as "at the door", stays).
///
/// Posts and clears reach the shade one after another, in the order the
/// page sent them: a ride card still being drawn can never land after the
/// clear that followed it.
class TrackingAlertsCubit extends Cubit<TrackingAlertsState>
    with SafeCubitMixin<TrackingAlertsState> {
  TrackingAlertsCubit({
    required this._check,
    required this._allow,
    required this._show,
    required this._clear,
  }) : super(const TrackingAlertsState());

  final CheckTrackingAlertsUseCase _check;
  final AllowTrackingAlertsUseCase _allow;
  final ShowTrackingAlertUseCase _show;
  final ClearTrackingAlertUseCase _clear;

  /// The order whose ride card is up (or queued to go up).
  String? _rideOf;

  /// The last post or clear sent to the shade; the next one waits for it.
  /// The use cases return an `Either` and never throw, so the chain holds.
  Future<void> _tail = Future<void>.value();

  /// The page is gone: ride cards still queued are not posted any more.
  bool _closing = false;

  Future<void> check() async {
    final result = await _check(const NoParams());
    safeEmit(state.copyWith(allowed: result.getOrElse(() => false)));
  }

  /// The customer tapped "Turn on": the phone asks them.
  Future<void> allow() async {
    if (state.asking) return;
    safeEmit(state.copyWith(asking: true));
    final result = await _allow(const NoParams());
    safeEmit(
      state.copyWith(
        allowed: result.getOrElse(() => false),
        asking: false,
        promptDismissed: true,
      ),
    );
  }

  void dismissPrompt() => safeEmit(state.copyWith(promptDismissed: true));

  /// Posts [alert] when the app may; a card for a ride that ended is taken
  /// away instead. Runs after every earlier post or clear.
  Future<void> show(TrackingAlert alert) {
    if (state.allowed != true || isClosed || _closing) {
      return Future<void>.value();
    }
    if (alert.kind == TrackingAlertKind.ride) {
      // Known at once, so a close() before this runs still clears the card.
      _rideOf = alert.riding ? alert.orderId : null;
    }
    return _tail = _tail.then((_) => _run(alert));
  }

  Future<void> _run(TrackingAlert alert) async {
    if (state.allowed != true) return;
    final ride = alert.kind == TrackingAlertKind.ride;
    if (ride && !alert.riding) {
      await _clear(ClearTrackingAlertParams(alert.orderId));
      return;
    }
    // The clear queued by close() takes the card away anyway.
    if (ride && _closing) return;
    await _show(ShowTrackingAlertParams(alert));
  }

  @override
  Future<void> close() {
    _closing = true;
    final ride = _rideOf;
    _rideOf = null;
    if (ride != null) {
      unawaited(
        _tail = _tail.then((_) => _clear(ClearTrackingAlertParams(ride))),
      );
    }
    return super.close();
  }
}
