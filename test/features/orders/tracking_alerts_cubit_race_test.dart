// The live map's notification calls reach the shade one after another, in
// the order the page sent them: a ride card still being drawn never lands
// after the clear that followed it.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/tracking_alert.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/tracking_alerts_repository.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/allow_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/check_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/clear_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/show_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/tracking_alerts_cubit.dart';

TrackingAlert _alert({
  TrackingAlertKind kind = TrackingAlertKind.ride,
  double progress = 0.4,
  bool riding = true,
}) => TrackingAlert(
  orderId: 'o1',
  kind: kind,
  channelName: 'Live order tracking',
  title: 'On its way',
  body: 'Ali · 5 min',
  progress: progress,
  riding: riding,
);

void main() {
  late _GatedAlertsRepository shade;

  Future<TrackingAlertsCubit> allowedCubit() async {
    final cubit = TrackingAlertsCubit(
      check: CheckTrackingAlertsUseCase(shade),
      allow: AllowTrackingAlertsUseCase(shade),
      show: ShowTrackingAlertUseCase(shade),
      clear: ClearTrackingAlertUseCase(shade),
    );
    await cubit.check();
    return cubit;
  }

  setUp(() => shade = _GatedAlertsRepository());

  test('the clear sent on close lands after a ride post in flight', () async {
    final cubit = await allowedCubit();
    final gate = shade.gate = Completer<void>();

    unawaited(cubit.show(_alert()));
    await pumpEventQueue();
    await cubit.close();
    await pumpEventQueue();
    expect(shade.log, ['post ride 0.4']);

    gate.complete();
    await pumpEventQueue();
    expect(shade.log, ['post ride 0.4', 'posted ride 0.4', 'clear o1']);
  });

  test('the arrival clear lands after an earlier ride post', () async {
    final cubit = await allowedCubit();
    final gate = shade.gate = Completer<void>();

    unawaited(cubit.show(_alert(progress: 0.9)));
    unawaited(cubit.show(_alert(progress: 1, riding: false)));
    await pumpEventQueue();
    expect(shade.log, ['post ride 0.9']);

    gate.complete();
    await pumpEventQueue();
    expect(shade.log, ['post ride 0.9', 'posted ride 0.9', 'clear o1']);

    // The card is gone already: closing clears nothing more.
    await cubit.close();
    await pumpEventQueue();
    expect(shade.log.where((entry) => entry.startsWith('clear')), hasLength(1));
  });

  test('two ride posts land in the order they were sent', () async {
    final cubit = await allowedCubit();
    final gate = shade.gate = Completer<void>();

    unawaited(cubit.show(_alert()));
    unawaited(cubit.show(_alert(progress: 0.5)));
    await pumpEventQueue();
    expect(shade.log, ['post ride 0.4']);

    gate.complete();
    await pumpEventQueue();
    expect(shade.log, [
      'post ride 0.4',
      'posted ride 0.4',
      'post ride 0.5',
      'posted ride 0.5',
    ]);
    await cubit.close();
  });

  test(
    'a ride post queued behind close is dropped, its card cleared',
    () async {
      final cubit = await allowedCubit();
      final gate = shade.gate = Completer<void>();

      unawaited(cubit.show(_alert(kind: TrackingAlertKind.moment)));
      unawaited(cubit.show(_alert()));
      await pumpEventQueue();
      await cubit.close();

      gate.complete();
      await pumpEventQueue();
      // The moment sent while the map was up still goes; the ride does not.
      expect(shade.log, ['post moment 0.4', 'posted moment 0.4', 'clear o1']);
    },
  );

  test('nothing is posted once the map is closed', () async {
    final cubit = await allowedCubit();
    await cubit.close();

    await cubit.show(_alert(kind: TrackingAlertKind.moment));
    await pumpEventQueue();

    expect(shade.log, isEmpty);
  });
}

/// A shade that lets the app post and logs each call; a post waits on
/// [gate] when one is set (the ride picture still being drawn).
class _GatedAlertsRepository implements TrackingAlertsRepository {
  final List<String> log = [];
  Completer<void>? gate;

  @override
  Future<Either<Failure, bool>> allowed() async => const Right(true);

  @override
  Future<Either<Failure, bool>> ask() async => const Right(true);

  @override
  Future<Either<Failure, Unit>> show(TrackingAlert alert) async {
    final name = '${alert.kind.name} ${alert.progress}';
    log.add('post $name');
    final held = gate;
    gate = null;
    if (held != null) await held.future;
    log.add('posted $name');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearRide(String orderId) async {
    log.add('clear $orderId');
    return const Right(unit);
  }
}
