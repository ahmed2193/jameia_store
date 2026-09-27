// ConnectivityCubit: `unknown` never shows, going offline is debounced and
// confirmed by one more live check (one failed probe never shows the
// banner), coming back is instant and bumps the reconnect epoch once per recovery,
// "Back online" hides by itself, emits are distinct, checks set isChecking
// (the banner's retry holds it for a dwell), and the lifecycle reaches the
// monitor. Timings are injected (tens of ms) — the repo's test convention.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:jameia_mart/src/features/connectivity/presentation/cubit/connectivity_banner_mode.dart';
import 'package:jameia_mart/src/features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'package:jameia_mart/src/features/connectivity/presentation/cubit/connectivity_state.dart';

import 'connectivity_test_fakes.dart';

Future<void> _wait(Duration duration) => Future<void>.delayed(duration);
Future<void> _flush() => _wait(Duration.zero);

void main() {
  late FakeConnectivityRepository repository;
  late ConnectivityCubit cubit;
  late List<ConnectivityState> states;
  late StreamSubscription<ConnectivityState> sub;

  setUp(() {
    repository = FakeConnectivityRepository();
    cubit = buildConnectivityCubit(repository)..start();
    states = [];
    sub = cubit.stream.listen(states.add);
  });

  tearDown(() async {
    await sub.cancel();
    await cubit.close();
  });

  /// A real disconnection: the monitor says so, and so does the check that
  /// confirms it.
  Future<void> goOffline() async {
    repository
      ..checkResult = ConnectivityStatus.offline
      ..report(ConnectivityStatus.offline);
    await _wait(testOfflineAfter * 2);
  }

  test('starts unknown, and unknown never shows the banner', () {
    expect(cubit.state.status, ConnectivityStatus.unknown);
    expect(cubit.state.bannerMode, ConnectivityBannerMode.hidden);
  });

  test('the launch settling online is not a recovery', () async {
    repository.report(ConnectivityStatus.online);
    await _flush();
    expect(cubit.state.status, ConnectivityStatus.online);
    expect(cubit.state.reconnectEpoch, 0);
    expect(cubit.state.showBackOnline, isFalse);
  });

  test(
    'offline shows only after the debounce and a confirming check',
    () async {
      repository
        ..checkResult = ConnectivityStatus.offline
        ..report(ConnectivityStatus.offline);
      await _flush();
      expect(cubit.state.isOffline, isFalse);
      expect(repository.checkCalls, 0);
      await _wait(testOfflineAfter * 2);
      expect(repository.checkCalls, 1);
      expect(cubit.state.isOffline, isTrue);
      expect(cubit.state.bannerMode, ConnectivityBannerMode.offline);
    },
  );

  test('one failed probe (a slow first one at launch) never shows offline: '
      'the confirming check reaches the server', () async {
    repository.report(ConnectivityStatus.offline);
    await _wait(testOfflineAfter * 2);

    expect(repository.checkCalls, 1);
    expect(states.where((state) => state.isOffline), isEmpty);
    expect(cubit.state.status, ConnectivityStatus.online);
    expect(cubit.state.reconnectEpoch, 0, reason: 'never offline: no recovery');
    expect(cubit.state.bannerMode, ConnectivityBannerMode.hidden);
  });

  test('a "reachable" report during the confirming check wins', () async {
    repository
      ..checkGate = Completer<void>()
      ..checkResult = ConnectivityStatus.offline
      ..report(ConnectivityStatus.offline);
    await _wait(testOfflineAfter * 2);
    expect(repository.checkCalls, 1);

    repository.report(ConnectivityStatus.online); // an API response
    await _flush();
    repository.checkGate!.complete();
    await _flush();

    expect(states.where((state) => state.isOffline), isEmpty);
    expect(cubit.state.status, ConnectivityStatus.online);
  });

  test(
    'more "unreachable" reports while confirming start no second check',
    () async {
      repository
        ..checkGate = Completer<void>()
        ..checkResult = ConnectivityStatus.offline
        ..report(ConnectivityStatus.offline);
      await _wait(testOfflineAfter * 2);
      repository.report(ConnectivityStatus.offline);
      await _wait(testOfflineAfter * 2);
      expect(repository.checkCalls, 1);

      repository.checkGate!.complete();
      await _flush();
      expect(cubit.state.isOffline, isTrue);
    },
  );

  test('a flap shorter than the debounce never shows offline', () async {
    repository.report(ConnectivityStatus.online);
    await _flush();
    states.clear();
    for (var i = 0; i < 5; i++) {
      repository.report(ConnectivityStatus.offline);
      await _wait(testOfflineAfter ~/ 3);
      repository.report(ConnectivityStatus.online);
      await _flush();
    }
    await _wait(testOfflineAfter * 2);
    expect(states, isEmpty);
    expect(cubit.state.reconnectEpoch, 0);
  });

  test('recovery is instant, bumps the epoch once, then hides', () async {
    await goOffline();
    repository.report(ConnectivityStatus.online);
    await _flush();
    expect(cubit.state.status, ConnectivityStatus.online);
    expect(cubit.state.reconnectEpoch, 1);
    expect(cubit.state.bannerMode, ConnectivityBannerMode.backOnline);

    repository.report(ConnectivityStatus.online);
    await _flush();
    expect(cubit.state.reconnectEpoch, 1, reason: 'one bump per recovery');

    await _wait(testBackOnlineFor * 2);
    expect(cubit.state.showBackOnline, isFalse);
    expect(cubit.state.bannerMode, ConnectivityBannerMode.hidden);
  });

  test('every real recovery bumps the epoch', () async {
    await goOffline();
    repository.report(ConnectivityStatus.online);
    await _flush();
    await goOffline();
    repository.report(ConnectivityStatus.online);
    await _flush();
    expect(cubit.state.reconnectEpoch, 2);
  });

  test('going offline again drops the back-online confirmation', () async {
    await goOffline();
    repository.report(ConnectivityStatus.online);
    await _flush();
    await goOffline();
    expect(cubit.state.showBackOnline, isFalse);
    await _wait(testBackOnlineFor * 2);
    expect(cubit.state.isOffline, isTrue);
  });

  test('emits distinct states only', () async {
    await goOffline();
    final before = states.length;
    repository.report(ConnectivityStatus.offline);
    repository.report(ConnectivityStatus.offline);
    await _wait(testOfflineAfter * 2);
    expect(states.length, before);
  });

  test('checkNow sets isChecking and answers what the check found', () async {
    await goOffline();
    repository.checkGate = Completer<void>();
    repository.checkResult = ConnectivityStatus.offline;
    final pending = cubit.checkNow();
    await _flush();
    expect(cubit.state.isChecking, isTrue);
    expect(cubit.state.bannerMode, ConnectivityBannerMode.reconnecting);
    repository.checkGate!.complete();
    expect(await pending, ConnectivityStatus.offline);
    expect(cubit.state.isChecking, isFalse);
    expect(cubit.state.isOffline, isTrue);
  });

  test('a successful check recovers at once', () async {
    await goOffline();
    repository.checkResult = ConnectivityStatus.online;
    expect(await cubit.checkNow(), ConnectivityStatus.online);
    expect(cubit.state.status, ConnectivityStatus.online);
    expect(cubit.state.reconnectEpoch, 1);
  });

  test('concurrent checks share one', () async {
    repository.checkGate = Completer<void>();
    final first = cubit.checkNow();
    final second = cubit.checkNow();
    repository.checkGate!.complete();
    await Future.wait([first, second]);
    expect(repository.checkCalls, 1);
  });

  test('the banner retry stays "Reconnecting…" for the dwell', () async {
    await goOffline();
    repository.checkResult = ConnectivityStatus.offline;
    final watch = Stopwatch()..start();
    final pending = cubit.retry();
    await _flush();
    expect(cubit.state.isChecking, isTrue);
    await pending;
    expect(watch.elapsed, greaterThanOrEqualTo(testRetryDwell));
    expect(cubit.state.isChecking, isFalse);
  });

  test('the lifecycle pauses and resumes the monitor', () {
    cubit
      ..pause()
      ..resume();
    expect(repository.monitoring, [false, true]);
  });

  test('closing cancels the pending timers', () async {
    repository.report(ConnectivityStatus.offline);
    await _flush();
    await cubit.close();
    await _wait(testOfflineAfter * 2);
    expect(cubit.state.isOffline, isFalse);
  });

  test('lastChangedAt stamps each transition', () async {
    await goOffline();
    expect(cubit.state.lastChangedAt, DateTime(2026, 9, 27, 12));
  });
}
