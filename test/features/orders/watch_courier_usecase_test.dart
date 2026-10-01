import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_courier_usecase.dart';

import 'courier_test_fakes.dart';

void main() {
  const tolerance = 1.0; // metres

  late FakeCourierTrackingRepository repository;

  setUp(() => repository = FakeCourierTrackingRepository());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Up one side of a street for 200 m, a U-turn, back down the other side
  /// 10 m away: 410 m.
  CourierTrip uTurnTrip() => CourierTrip(
    orderId: 'o1',
    route: CourierRoute([at(0, 0), at(0, 200), at(10, 200), at(10, 0)]),
  );

  /// The path metres of every progress [trip] emits while the test runs.
  List<double> follow(CourierTrip trip) {
    final progress = <double>[];
    final sub = WatchCourierUseCase(repository)(WatchCourierParams(trip))
        .listen((value) => progress.add(value.pathMeters));
    addTearDown(sub.cancel);
    return progress;
  }

  group('WatchCourierUseCase reach', () {
    test('the first fix lands anywhere on the road (a map opened '
        'mid-ride)', () async {
      final progress = follow(testTrip());

      repository.feed.add(fixAt(at(0, 300), second: 1));
      await settle();

      expect(progress.single, closeTo(500, tolerance));
    });

    test('a fix nearer the way back right after the last one stays on the '
        'way out', () async {
      final progress = follow(uTurnTrip());

      repository.feed
        ..add(fixAt(at(0, 20), second: 1))
        // 2 m from the way back, 8 m from the way out, one second later.
        ..add(fixAt(at(8, 40), second: 2));
      await settle();

      expect(progress[0], closeTo(20, tolerance));
      expect(progress[1], closeTo(40, tolerance));
    });

    test('a long gap still reaches far ahead', () async {
      final progress = follow(uTurnTrip());

      repository.feed
        ..add(fixAt(at(0, 20), second: 1))
        // A minute later the rider is on the way back.
        ..add(fixAt(at(10, 50), second: 61));
      await settle();

      expect(progress[1], closeTo(360, tolerance));
    });

    test('a rider at city pace is followed fix by fix', () async {
      final progress = follow(uTurnTrip());

      repository.feed
        ..add(fixAt(at(0, 20), second: 1))
        ..add(fixAt(at(1, 37), second: 3))
        ..add(fixAt(at(-1, 54), second: 5));
      await settle();

      expect(progress[1], closeTo(37, tolerance));
      expect(progress[2], closeTo(54, tolerance));
    });

    test('a dropped straggler never widens the reach', () async {
      final progress = follow(uTurnTrip());

      repository.feed
        ..add(fixAt(at(0, 20), second: 10))
        // Older than the last: dropped, the reach still counts from 10 s.
        ..add(fixAt(at(0, 10), second: 1))
        ..add(fixAt(at(8, 40), second: 11));
      await settle();

      expect(progress, hasLength(2));
      expect(progress[1], closeTo(40, tolerance));
    });

    test('heading to the store the reach stops at the store', () async {
      final progress = follow(testTrip());

      repository.feed
        ..add(fixAt(at(0, -150), second: 1, state: CourierFixState.toStore))
        // Already past the store, 30 s on: held at the store while the feed
        // still says "to the store".
        ..add(fixAt(at(0, 100), second: 31, state: CourierFixState.toStore));
      await settle();

      expect(progress[0], closeTo(50, tolerance));
      expect(progress[1], closeTo(200, tolerance));
    });
  });
}
