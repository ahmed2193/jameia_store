import 'dart:async';
import 'dart:developer';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../constants/app_constants.dart';

/// Whether the Hero backend can be reached — the app's one reachability
/// monitor. Feature code never reads it directly: `features/connectivity`
/// turns it into the app-global `ConnectivityCubit`, and the Dio chain feeds
/// it through `ReachabilitySignalInterceptor`.
abstract class NetworkInfo {
  /// The last known reachability; `null` until the first probe (or response).
  bool? get isReachable;

  /// Every change of [isReachable]. The first listener starts the monitor
  /// (the poll — the app's own requests answer first); the last one to
  /// leave stops it, so nothing probes while nobody listens.
  Stream<bool> get onReachabilityChanged;

  /// Probes now (joining a probe already running) and returns the result.
  Future<bool> checkNow();

  /// Any HTTP response from the backend proves it is reachable — marks it
  /// reachable at once, without waiting for the next poll, and moves the
  /// idle poll out (live traffic needs no probe).
  void reportReachable();

  /// A request failed in transport (no route, timeout): re-check at once.
  /// It never flips the status by itself — only a probe does.
  void reportTransportFailure();

  /// Stops polling (the app went to the background). A probe already running
  /// still reports its result.
  void pause();

  /// Starts polling again with an immediate probe.
  void resume();
}

/// [NetworkInfo] over `internet_connection_checker_plus`, which only runs the
/// probe ([InternetConnection.hasInternetAccess] over [probeOptions]).
///
/// The schedule and the status are owned HERE, not by the package's
/// `onStatusChange`: that stream de-duplicates against a private last status
/// that a [reportReachable] cannot update, so after a response marked the
/// backend reachable the monitor could never report it unreachable again.
///
/// Polls every [AppConstants.connectivityPoll] while unreachable (fast
/// recovery) and every [AppConstants.connectivityPollOnline] of silence while
/// reachable (every response restarts that wait); nothing while paused or
/// unobserved. There is no probe at launch: the startup requests report
/// within milliseconds (a response marks the backend reachable, a transport
/// failure probes at once), and a probe racing them is the one that times
/// out.
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(
    this._checker, {
    this._onlinePoll = AppConstants.connectivityPollOnline,
    this._offlinePoll = AppConstants.connectivityPoll,
  });

  /// Probes [apiBaseUrl] plus one neutral host.
  NetworkInfoImpl.forApi(String apiBaseUrl)
    : this(
        InternetConnection.createInstance(
          customCheckOptions: probeOptions(apiBaseUrl),
          useDefaultOptions: false,
        ),
      );

  /// `dart:developer` log name.
  static const String logName = 'connectivity';

  /// A neutral HTTPS host: a backend outage must never read as "offline", and
  /// a captive portal cannot answer for an HTTPS host, so any reply counts.
  static const String fallbackProbe = 'https://one.one.one.one';

  /// `HEAD <api>/` answers `404` with an empty body in about 0.3 s — ANY
  /// status proves our backend is reachable, so it is the cheapest probe
  /// (2026-09-27). The fallback keeps the app online when only our backend is
  /// down; the screens then show their server error, not the offline UI.
  static List<InternetCheckOption> probeOptions(String apiBaseUrl) => [
    InternetCheckOption(
      uri: Uri.parse('$apiBaseUrl/'),
      timeout: AppConstants.connectivityProbeTimeout,
      responseStatusFn: _anyStatus,
    ),
    InternetCheckOption(
      uri: Uri.parse(fallbackProbe),
      timeout: AppConstants.connectivityProbeTimeout,
      responseStatusFn: _anyStatus,
    ),
  ];

  static bool _anyStatus(Object? _) => true;

  final InternetConnection _checker;
  final Duration _onlinePoll;
  final Duration _offlinePoll;

  late final StreamController<bool> _changes = StreamController<bool>.broadcast(
    onListen: _startMonitoring,
    onCancel: _stopPolling,
  );

  bool? _reachable;
  bool _paused = false;
  Timer? _poll;
  Future<bool>? _probing;

  /// Bumped by every [reportReachable]: a probe that started before the last
  /// response and then failed is older news, and must not flip the status.
  int _evidence = 0;

  @override
  bool? get isReachable => _reachable;

  @override
  Stream<bool> get onReachabilityChanged => _changes.stream;

  bool get _monitoring => _changes.hasListener && !_paused;

  @override
  Future<bool> checkNow() => _probe();

  @override
  void reportReachable() {
    _evidence++;
    _set(true);
    if (_probing == null) _schedule(); // the traffic proves it: poll later
  }

  @override
  void reportTransportFailure() {
    if (_monitoring) unawaited(_probe());
  }

  @override
  void pause() {
    if (_paused) return;
    _paused = true;
    _stopPolling();
    log('monitor paused', name: logName);
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;
    log('monitor resumed', name: logName);
    if (_changes.hasListener) unawaited(_probe());
  }

  void _startMonitoring() => _schedule();

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// One probe at a time: a trigger that lands while one runs joins it.
  Future<bool> _probe() {
    _stopPolling();
    return _probing ??= _runProbe().whenComplete(() {
      _probing = null;
      _schedule();
    });
  }

  Future<bool> _runProbe() async {
    final evidence = _evidence;
    final watch = Stopwatch()..start();
    final reachable = await _checker.hasInternetAccess;
    log(
      'probe → ${reachable ? 'reachable' : 'unreachable'} '
      '(${watch.elapsedMilliseconds}ms)',
      name: logName,
    );
    if (!reachable && evidence != _evidence) return true;
    _set(reachable);
    return reachable;
  }

  void _set(bool reachable) {
    if (_reachable == reachable) return;
    _reachable = reachable;
    log(reachable ? 'backend reachable' : 'backend unreachable', name: logName);
    _changes.add(reachable);
  }

  void _schedule() {
    _stopPolling();
    if (!_monitoring) return;
    _poll = Timer(
      _reachable == false ? _offlinePoll : _onlinePoll,
      () => unawaited(_probe()),
    );
  }
}
