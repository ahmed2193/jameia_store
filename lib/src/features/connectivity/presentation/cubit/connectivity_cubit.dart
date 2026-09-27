import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/connectivity_status.dart';
import '../../domain/usecases/check_connectivity_usecase.dart';
import '../../domain/usecases/set_connectivity_monitoring_usecase.dart';
import '../../domain/usecases/watch_connectivity_usecase.dart';
import 'connectivity_state.dart';

/// App-global connection state (provided above `MaterialApp.router`, started
/// once by the app root):
///
///   * going offline is debounced ([AppConstants.offlineDebounce]) and then
///     CONFIRMED: only a report that stays "unreachable" that long, and a
///     live check at its end that still finds no connection, show the
///     banner — one failed probe (the first one at launch, while the app is
///     still starting; a Wi-Fi ↔ mobile hand-over) never does;
///   * coming back is instant on the first "reachable" report — a probe or
///     any API response — and bumps [ConnectivityState.reconnectEpoch];
///   * "Back online" shows for [AppConstants.backOnlineHold], then hides;
///   * [pause] / [resume] follow the app lifecycle (no probe in background).
class ConnectivityCubit extends Cubit<ConnectivityState>
    with SafeCubitMixin<ConnectivityState> {
  ConnectivityCubit({
    required this._watch,
    required this._check,
    required this._setMonitoring,
    this._now = DateTime.now,
    this._offlineAfter = AppConstants.offlineDebounce,
    this._backOnlineFor = AppConstants.backOnlineHold,
    this._retryDwell = AppConstants.connectivityRetryDwell,
  }) : super(const ConnectivityState());

  static const String _logName = 'ConnectivityCubit';

  final WatchConnectivityUseCase _watch;
  final CheckConnectivityUseCase _check;
  final SetConnectivityMonitoringUseCase _setMonitoring;
  final DateTime Function() _now;
  final Duration _offlineAfter;
  final Duration _backOnlineFor;
  final Duration _retryDwell;

  StreamSubscription<ConnectivityStatus>? _reports;
  Timer? _offlineDebounce;
  Timer? _backOnlineHold;
  Future<ConnectivityStatus>? _checking;

  /// The live check confirming "offline" is running.
  bool _confirming = false;

  /// Bumped by every "reachable" report: a confirming check that started
  /// before one is older news.
  int _reachableReports = 0;

  /// Follows the monitor; the first listener starts it. Idempotent.
  void start() {
    _reports ??= _watch(const NoParams()).listen(
      _onReport,
      onError: (Object failure) =>
          log('monitor failed', name: _logName, error: failure),
    );
  }

  /// Checks now and answers with what the check found (not debounced) —
  /// the place-order confirmation. Joins a check already running.
  Future<ConnectivityStatus> checkNow() => _startCheck(Duration.zero);

  /// The banner's tap: the same check, shown as "Reconnecting…" for at least
  /// [AppConstants.connectivityRetryDwell] so it is seen even when it fails
  /// at once.
  Future<void> retry() => _startCheck(_retryDwell);

  /// The app went to the background: no probes until [resume].
  void pause() => _monitor(active: false);

  /// Back in the foreground: polling restarts with an immediate check.
  void resume() => _monitor(active: true);

  Future<ConnectivityStatus> _startCheck(Duration minimum) =>
      _checking ??= _runCheck(minimum).whenComplete(() => _checking = null);

  Future<ConnectivityStatus> _runCheck(Duration minimum) async {
    safeEmit(state.copyWith(isChecking: true));
    final (result, _) = await (
      _check(const NoParams()),
      Future<void>.delayed(minimum),
    ).wait;
    final found = result.fold((failure) {
      log('check failed', name: _logName, error: failure);
      return state.status;
    }, (status) => status);
    _onReport(found);
    safeEmit(state.copyWith(isChecking: false));
    return found;
  }

  void _onReport(ConnectivityStatus reported) {
    switch (reported) {
      case ConnectivityStatus.online:
        _reachableReports++;
        _offlineDebounce?.cancel();
        _offlineDebounce = null;
        _markOnline();
      case ConnectivityStatus.offline:
        if (state.isOffline || _confirming) return;
        _offlineDebounce ??= Timer(
          _offlineAfter,
          () => unawaited(_confirmOffline()),
        );
      case ConnectivityStatus.unknown:
        break;
    }
  }

  /// The debounce ran out: one more live check before the app says it is
  /// offline. Still no connection → offline; the check reached the server,
  /// or a "reachable" report (an API response) came meanwhile → online.
  Future<void> _confirmOffline() async {
    _offlineDebounce = null;
    _confirming = true;
    final reachableBefore = _reachableReports;
    final result = await _check(const NoParams());
    _confirming = false;
    if (reachableBefore != _reachableReports) return;
    final found = result.fold((failure) {
      log('offline check failed', name: _logName, error: failure);
      return ConnectivityStatus.offline;
    }, (status) => status);
    if (found == ConnectivityStatus.online) {
      _onReport(ConnectivityStatus.online);
    } else {
      _markOffline();
    }
  }

  void _markOffline() {
    _backOnlineHold?.cancel();
    _backOnlineHold = null;
    safeEmit(
      state.copyWith(
        status: ConnectivityStatus.offline,
        showBackOnline: false,
        lastChangedAt: _now(),
      ),
    );
  }

  void _markOnline() {
    if (state.status == ConnectivityStatus.online) return;
    // `unknown → online` is the launch settling, not a recovery.
    final recovered = state.isOffline;
    safeEmit(
      state.copyWith(
        status: ConnectivityStatus.online,
        reconnectEpoch: recovered ? state.reconnectEpoch + 1 : null,
        showBackOnline: recovered,
        lastChangedAt: _now(),
      ),
    );
    if (!recovered) return;
    _backOnlineHold?.cancel();
    _backOnlineHold = Timer(_backOnlineFor, () {
      _backOnlineHold = null;
      safeEmit(state.copyWith(showBackOnline: false));
    });
  }

  void _monitor({required bool active}) {
    _setMonitoring(SetConnectivityMonitoringParams(active: active)).fold(
      (failure) => log('monitor not switched', name: _logName, error: failure),
      (_) {},
    );
  }

  @override
  Future<void> close() async {
    _offlineDebounce?.cancel();
    _backOnlineHold?.cancel();
    await _reports?.cancel();
    return super.close();
  }
}
