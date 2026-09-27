// SnapshotLoaderMixin: snapshots and failures reach the cubit in order; a
// new load on a channel cancels the running one (its late snapshot — a slow
// disk read landing after a refresh's reply — is never delivered); channels
// run side by side; nothing is delivered after close; every awaited load
// completes; isReading follows a running load; the reconnect refresh is
// single-flight and conditional, and decides after a running read answers.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/utils/performance/safe_cubit_mixin.dart';
import 'package:hero_mart/src/core/utils/performance/snapshot_loader_mixin.dart';

class _Cubit extends Cubit<List<String>>
    with SafeCubitMixin<List<String>>, SnapshotLoaderMixin<List<String>> {
  _Cubit() : super(const []);

  final List<Failure> failures = [];

  Future<void> load(
    Stream<DataSnapshot<String>> source, {
    Object channel = 'main',
  }) => followSnapshots<String>(
    source,
    channel: channel,
    onSnapshot: (snapshot) => safeEmit([...state, snapshot.data]),
    onFailure: failures.add,
  );
}

DataSnapshot<String> _snap(String data, {bool cache = false}) => DataSnapshot(
  data: data,
  fetchedAt: DateTime.utc(2026, 9, 27),
  origin: cache ? SnapshotOrigin.cache : SnapshotOrigin.network,
);

void main() {
  late _Cubit cubit;

  setUp(() => cubit = _Cubit());
  tearDown(() => cubit.close());

  test(
    'snapshots then a failure arrive in order; the load completes',
    () async {
      final source = StreamController<DataSnapshot<String>>();
      final done = cubit.load(source.stream);
      source
        ..add(_snap('copy', cache: true))
        ..addError(const NetworkFailure());
      await source.close();
      await done;
      expect(cubit.state, ['copy']);
      expect(cubit.failures, [const NetworkFailure()]);
    },
  );

  test('a non-Failure error surfaces as UnexpectedFailure', () async {
    await cubit.load(Stream<DataSnapshot<String>>.error(StateError('x')));
    expect(cubit.failures.single, isA<UnexpectedFailure>());
  });

  test(
    'a new load replaces the running one; its late copy is dropped',
    () async {
      final slow = StreamController<DataSnapshot<String>>();
      final first = cubit.load(slow.stream);
      await cubit.load(Stream.value(_snap('network')));
      // The first load's disk read lands after the refresh answered.
      slow.add(_snap('late copy', cache: true));
      await pumpEventQueue();
      expect(cubit.state, ['network']);
      await first; // completes when replaced
      expect(slow.hasListener, isFalse, reason: 'cancelled');
    },
  );

  test('channels run side by side', () async {
    final feed = StreamController<DataSnapshot<String>>();
    final init = StreamController<DataSnapshot<String>>();
    unawaited(cubit.load(feed.stream, channel: 'feed'));
    unawaited(cubit.load(init.stream, channel: 'init'));
    feed.add(_snap('feed'));
    init.add(_snap('init'));
    await pumpEventQueue();
    expect(cubit.state, ['feed', 'init']);
    await feed.close();
    await init.close();
  });

  test('nothing is delivered after close; loads complete', () async {
    final source = StreamController<DataSnapshot<String>>();
    final done = cubit.load(source.stream);
    await cubit.close();
    await done;
    expect(source.hasListener, isFalse);
    expect(cubit.state, isEmpty);
  });

  group('refreshOnReconnect', () {
    test('runs only when needed', () async {
      var runs = 0;
      await cubit.refreshOnReconnect(
        needed: () => false,
        refresh: () async => runs++,
      );
      expect(runs, 0);
    });

    test('a running read answers first: needed is asked after it', () async {
      var runs = 0;
      var stale = true;
      final source = StreamController<DataSnapshot<String>>();
      unawaited(cubit.load(source.stream));
      expect(cubit.isReading('main'), isTrue);

      final reconnect = cubit.refreshOnReconnect(
        needed: () => stale,
        refresh: () async => runs++,
        channel: 'main',
      );
      source.add(_snap('server'));
      stale = false; // the running read brought the server's data
      await source.close();
      await reconnect;

      expect(runs, 0);
      expect(cubit.isReading('main'), isFalse);
    });

    test('single-flight: overlapping calls share one refresh', () async {
      var runs = 0;
      final gate = Completer<void>();
      Future<void> refresh() async {
        runs++;
        await gate.future;
      }

      final a = cubit.refreshOnReconnect(needed: () => true, refresh: refresh);
      final b = cubit.refreshOnReconnect(needed: () => true, refresh: refresh);
      gate.complete();
      await Future.wait([a, b]);
      expect(runs, 1);

      await cubit.refreshOnReconnect(needed: () => true, refresh: refresh);
      expect(runs, 2, reason: 'a later reconnect refreshes again');
    });
  });
}
