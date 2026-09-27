// NetworkInfoImpl: the probe list, the poll schedule (fast while
// unreachable, slow while reachable, none while paused or unobserved), the
// immediate re-check on a transport failure, the instant recovery on an API
// response, and single-flight probes. The probe runs through the package's
// `customConnectivityCheck`, so nothing here touches the network.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:jameia_mart/src/core/network/network_info.dart';

/// Answers every probe option from [reachable]; a [gate] holds the answer.
class _ScriptedProbe {
  bool reachable = true;
  final List<Uri> calls = [];
  Completer<void>? gate;

  /// Number of probe rounds (each round asks both options).
  int get rounds => calls.where((uri) => uri.host == 'api.test').length;

  Future<InternetCheckResult> check(InternetCheckOption option) async {
    calls.add(option.uri);
    await gate?.future;
    return InternetCheckResult(option: option, isSuccess: reachable);
  }
}

const Duration _fastPoll = Duration(milliseconds: 20);
const Duration _slowPoll = Duration(hours: 1);
const Duration _settle = Duration(milliseconds: 5);

NetworkInfoImpl _monitor(
  _ScriptedProbe probe, {
  Duration onlinePoll = _slowPoll,
  Duration offlinePoll = _fastPoll,
}) => NetworkInfoImpl(
  InternetConnection.createInstance(
    customCheckOptions: NetworkInfoImpl.probeOptions('https://api.test'),
    useDefaultOptions: false,
    customConnectivityCheck: probe.check,
  ),
  onlinePoll: onlinePoll,
  offlinePoll: offlinePoll,
);

Future<void> _wait([Duration duration = _settle]) =>
    Future<void>.delayed(duration);

void main() {
  group('probe options', () {
    final options = NetworkInfoImpl.probeOptions('https://api.test');

    test('our backend first, then one neutral HTTPS host', () {
      expect(options.map((o) => o.uri.toString()), [
        'https://api.test/',
        NetworkInfoImpl.fallbackProbe,
      ]);
      expect(options.first.uri.scheme, 'https');
      expect(Uri.parse(NetworkInfoImpl.fallbackProbe).scheme, 'https');
    });

    test('any HTTP status counts as reachable (HEAD / answers 404)', () {
      for (final status in [200, 301, 404, 429, 500, 503]) {
        for (final option in options) {
          expect(
            option.responseStatusFn(http.Response('', status)),
            isTrue,
            reason: '${option.uri} $status',
          );
        }
      }
    });
  });

  group('monitoring', () {
    test('nothing probes while nobody listens', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe);
      monitor.reportTransportFailure();
      await _wait(_fastPoll * 3);
      expect(probe.calls, isEmpty);
      expect(monitor.isReachable, isNull);
    });

    test('the first listener starts an immediate probe', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe);
      final seen = <bool>[];
      final sub = monitor.onReachabilityChanged.listen(seen.add);
      await _wait();
      expect(probe.rounds, 1);
      expect(seen, [true]);
      expect(monitor.isReachable, isTrue);
      await sub.cancel();
    });

    test('the fallback keeps the app online when only our host fails', () async {
      final asked = <String>[];
      final monitor = NetworkInfoImpl(
        InternetConnection.createInstance(
          customCheckOptions: NetworkInfoImpl.probeOptions('https://api.test'),
          useDefaultOptions: false,
          customConnectivityCheck: (option) async {
            asked.add(option.uri.host);
            return InternetCheckResult(
              option: option,
              isSuccess: option.uri.host != 'api.test',
            );
          },
        ),
        onlinePoll: _slowPoll,
        offlinePoll: _fastPoll,
      );
      expect(await monitor.checkNow(), isTrue);
      expect(asked, containsAll(['api.test', 'one.one.one.one']));
    });

    test('no host answers → unreachable', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe);
      expect(await monitor.checkNow(), isFalse);
      expect(monitor.isReachable, isFalse);
    });

    test('only changes are emitted', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe);
      final seen = <bool>[];
      final sub = monitor.onReachabilityChanged.listen(seen.add);
      await _wait();
      await monitor.checkNow();
      await monitor.checkNow();
      probe.reachable = false;
      await monitor.checkNow();
      await monitor.checkNow();
      expect(seen, [true, false]);
      await sub.cancel();
    });
  });

  group('poll cadence', () {
    test('polls fast while unreachable, slow once reachable', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait(_fastPoll * 5);
      final offlineRounds = probe.rounds;
      expect(offlineRounds, greaterThanOrEqualTo(3));

      probe.reachable = true;
      await _wait(_fastPoll * 2);
      final atRecovery = probe.rounds;
      await _wait(_fastPoll * 5);
      // Online: the next poll is an hour away.
      expect(probe.rounds, atRecovery);
      expect(monitor.isReachable, isTrue);
      await sub.cancel();
    });

    test('the last listener leaving stops the poll', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait();
      await sub.cancel();
      final rounds = probe.rounds;
      await _wait(_fastPoll * 4);
      expect(probe.rounds, rounds);
    });
  });

  group('lifecycle', () {
    test('paused: zero probes; resume: one immediate probe', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait();
      monitor.pause();
      final rounds = probe.rounds;
      monitor.reportTransportFailure();
      await _wait(_fastPoll * 5);
      expect(probe.rounds, rounds, reason: 'no probe while paused');

      monitor.resume();
      await _wait();
      expect(probe.rounds, rounds + 1);
      await sub.cancel();
    });

    test('resume without a listener does not probe', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe)..pause();
      monitor.resume();
      await _wait();
      expect(probe.calls, isEmpty);
    });
  });

  group('signals from real traffic', () {
    test('a transport failure re-checks at once (while monitoring)', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait();
      expect(probe.rounds, 1);
      monitor.reportTransportFailure();
      await _wait();
      expect(probe.rounds, 2);
      await sub.cancel();
    });

    test('a transport failure alone never flips the status', () async {
      final probe = _ScriptedProbe();
      final monitor = _monitor(probe);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait();
      monitor.reportTransportFailure();
      await _wait();
      expect(monitor.isReachable, isTrue);
      await sub.cancel();
    });

    test('an API response recovers instantly, without a probe', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe, offlinePoll: _slowPoll);
      final seen = <bool>[];
      final sub = monitor.onReachabilityChanged.listen(seen.add);
      await _wait();
      final rounds = probe.rounds;
      monitor.reportReachable();
      expect(monitor.isReachable, isTrue);
      await _wait();
      expect(seen, [false, true]);
      expect(probe.rounds, rounds);
      await sub.cancel();
    });

    test('a probe that failed before the response landed cannot undo it', () async {
      final probe = _ScriptedProbe()..reachable = false;
      final monitor = _monitor(probe, offlinePoll: _slowPoll);
      final sub = monitor.onReachabilityChanged.listen((_) {});
      await _wait();
      probe.gate = Completer<void>();
      final pending = monitor.checkNow();
      await _wait();
      monitor.reportReachable();
      probe.gate!.complete();
      expect(await pending, isTrue);
      expect(monitor.isReachable, isTrue);
      await sub.cancel();
    });
  });

  test('probes are single-flight', () async {
    final probe = _ScriptedProbe()..gate = Completer<void>();
    final monitor = _monitor(probe);
    final first = monitor.checkNow();
    final second = monitor.checkNow();
    monitor.reportTransportFailure();
    probe.gate!.complete();
    expect(await Future.wait([first, second]), [true, true]);
    expect(probe.rounds, 1);
  });
}
