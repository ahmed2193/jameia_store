import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:hero_mart/src/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:hero_mart/src/features/connectivity/domain/usecases/check_connectivity_usecase.dart';
import 'package:hero_mart/src/features/connectivity/domain/usecases/set_connectivity_monitoring_usecase.dart';
import 'package:hero_mart/src/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:hero_mart/src/features/connectivity/presentation/cubit/connectivity_cubit.dart';

/// Drives the cubit with raw monitor reports ([report]) and scripted checks.
class FakeConnectivityRepository implements ConnectivityRepository {
  final StreamController<ConnectivityStatus> reports =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus checkResult = ConnectivityStatus.online;
  Completer<void>? checkGate;
  int checkCalls = 0;
  final List<bool> monitoring = [];

  void report(ConnectivityStatus status) => reports.add(status);

  @override
  Stream<ConnectivityStatus> watchStatus() => reports.stream;

  @override
  Future<Either<Failure, ConnectivityStatus>> checkNow() async {
    checkCalls++;
    await checkGate?.future;
    return Right(checkResult);
  }

  @override
  Either<Failure, Unit> setMonitoring({required bool active}) {
    monitoring.add(active);
    return const Right(unit);
  }
}

const Duration testOfflineAfter = Duration(milliseconds: 30);
const Duration testBackOnlineFor = Duration(milliseconds: 40);
const Duration testRetryDwell = Duration(milliseconds: 25);

ConnectivityCubit buildConnectivityCubit(
  FakeConnectivityRepository repository, {
  DateTime Function()? now,
}) => ConnectivityCubit(
  watch: WatchConnectivityUseCase(repository),
  check: CheckConnectivityUseCase(repository),
  setMonitoring: SetConnectivityMonitoringUseCase(repository),
  now: now ?? () => DateTime(2026, 9, 27, 12),
  offlineAfter: testOfflineAfter,
  backOnlineFor: testBackOnlineFor,
  retryDwell: testRetryDwell,
);
