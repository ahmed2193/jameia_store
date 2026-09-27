// The connectivity data layer over a FakeNetworkInfo: the watch stream
// starts from what the monitor already knows, then follows its changes;
// statuses map true/false → online/offline; the lifecycle switch reaches the
// monitor.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/connectivity/data/datasources/connectivity_data_source.dart';
import 'package:jameia_mart/src/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:jameia_mart/src/features/connectivity/domain/entities/connectivity_status.dart';

import '../../core/network/network_test_fakes.dart';

void main() {
  late FakeNetworkInfo networkInfo;
  late ConnectivityRepositoryImpl repository;

  setUp(() {
    networkInfo = FakeNetworkInfo();
    repository = ConnectivityRepositoryImpl(
      ConnectivityDataSourceImpl(networkInfo),
    );
  });

  test('watch starts from the known status, then follows changes', () async {
    final seen = <ConnectivityStatus>[];
    final sub = repository.watchStatus().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    networkInfo.emit(false);
    networkInfo.emit(true);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [
      ConnectivityStatus.online,
      ConnectivityStatus.offline,
      ConnectivityStatus.online,
    ]);
    await sub.cancel();
    expect(networkInfo.hasListener, isFalse, reason: 'cancel stops watching');
  });

  test('nothing known yet → the first value is the first change', () async {
    networkInfo.isReachable = null;
    final seen = <ConnectivityStatus>[];
    final sub = repository.watchStatus().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    networkInfo.emit(false);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [ConnectivityStatus.offline]);
    await sub.cancel();
  });

  test('checkNow maps the probe', () async {
    networkInfo.checkResult = false;
    expect(
      await repository.checkNow(),
      const Right<Object, ConnectivityStatus>(ConnectivityStatus.offline),
    );
    expect(networkInfo.checkCalls, 1);
  });

  test('monitoring pauses and resumes the monitor', () {
    repository.setMonitoring(active: false);
    expect(networkInfo.paused, isTrue);
    repository.setMonitoring(active: true);
    expect(networkInfo.paused, isFalse);
  });
}
