import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_fulfillment_entities.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_courier_trip_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_courier_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/courier_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/courier_tracking_state.dart';

import 'courier_test_fakes.dart';

void main() {
  const order = OrderEntity(
    id: 'o1',
    orderNumber: '1001',
    address: OrderAddressEntity(location: testOrigin),
  );

  late FakeCourierTrackingRepository repository;

  CourierTrackingCubit build({
    Duration staleAfter = const Duration(seconds: 15),
  }) {
    repository = FakeCourierTrackingRepository();
    return CourierTrackingCubit(
      getTrip: GetCourierTripUseCase(repository),
      watchCourier: WatchCourierUseCase(repository),
      staleAfter: staleAfter,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('WatchCourierUseCase', () {
    test(
      'snaps fixes to the road, forward only, and drops stragglers',
      () async {
        repository = FakeCourierTrackingRepository();
        final progress = <double>[];
        final sub = WatchCourierUseCase(repository)(
          WatchCourierParams(testTrip()),
        ).listen((value) => progress.add(value.pathMeters));
        final feed = repository.feed;

        feed
          ..add(fixAt(at(3, 100), second: 1)) // 300 m down the path
          ..add(fixAt(at(0, 80), second: 2)) // noise behind: stays
          ..add(fixAt(at(0, 380), second: 0)) // older than the last: dropped
          // 8 s after the last kept fix: within reach of a rider at city pace.
          ..add(fixAt(at(0, 300), second: 10));
        await settle();

        expect(progress, hasLength(3));
        expect(progress[0], closeTo(300, 1));
        expect(progress[1], closeTo(300, 1));
        expect(progress[2], closeTo(500, 1));
        await sub.cancel();
      },
    );

    test(
      'keeps the rider on their leg where the legs share a street',
      () async {
        repository = FakeCourierTrackingRepository();
        // To the store up one side of a street, to the door back down the
        // other, 10 m apart.
        final trip = CourierTrip(
          orderId: 'o1',
          approach: CourierRoute([at(0, -200), at(0, 0)]),
          route: CourierRoute([at(0, 0), at(10, 0), at(10, -200)]),
        );
        final progress = <double>[];
        final sub = WatchCourierUseCase(repository)(WatchCourierParams(trip))
            .listen((value) => progress.add(value.pathMeters));

        repository.feed
          // Heading to the store, noise nearer the far side: still the way up.
          ..add(fixAt(at(8, -100), second: 1, state: CourierFixState.toStore))
          // On the way, noise nearer the near side: still the way down.
          ..add(fixAt(at(2, -100), second: 5));
        await settle();

        expect(progress[0], closeTo(100, 1));
        expect(progress[1], closeTo(310, 1));
        await sub.cancel();
      },
    );

    test('holds the minutes steady against one noisy fix', () async {
      repository = FakeCourierTrackingRepository();
      final minutes = <int?>[];
      final sub = WatchCourierUseCase(repository)(
        WatchCourierParams(testTrip()),
      ).listen((value) => minutes.add(value.minutesLeft));

      repository.feed
        ..add(fixAt(at(0, 0), second: 1, etaSeconds: 290)) // 5
        ..add(fixAt(at(0, 10), second: 2, etaSeconds: 310)) // 6: noise
        ..add(fixAt(at(0, 20), second: 3, etaSeconds: 230)); // 4
      await settle();

      expect(minutes, [5, 5, 4]);
      await sub.cancel();
    });
  });

  group('CourierTrackingCubit', () {
    test('reads the ride, then follows the rider fix by fix', () async {
      final cubit = build();

      await cubit.start(order);

      expect(cubit.state.status, CourierTrackingStatus.live);
      expect(cubit.state.trip?.orderId, 'o1');
      expect(repository.requests.single.destination, testOrigin);
      expect(cubit.isFollowing, isTrue);

      repository.feed.add(
        fixAt(at(0, -100), second: 1, state: CourierFixState.toStore),
      );
      await settle();
      expect(cubit.state.stage, CourierStage.toStore);
      expect(cubit.state.progress?.pathMeters, closeTo(100, 1));
      await cubit.close();
    });

    test('a ride that cannot be read fails, and retry asks again', () async {
      final cubit = build();
      repository.tripFailure = const NetworkFailure();

      await cubit.start(order);
      expect(cubit.state.status, CourierTrackingStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());

      repository.tripFailure = null;
      await cubit.retry();
      expect(cubit.state.status, CourierTrackingStatus.live);
      expect(repository.requests, hasLength(2));
      await cubit.close();
    });

    test('a quiet feed turns stale; the next fix clears it', () async {
      final cubit = build(staleAfter: const Duration(milliseconds: 20));
      await cubit.start(order);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(cubit.state.stale, isTrue);

      repository.feed.add(fixAt(at(0, 0), second: 1));
      await settle();
      expect(cubit.state.stale, isFalse);
      await cubit.close();
    });

    test('follows one feed for the whole ride; closing stops it', () async {
      final cubit = build();
      await cubit.start(order);
      final feed = repository.feed;

      feed.add(fixAt(at(0, 100), second: 1));
      feed.add(fixAt(at(0, 200), second: 3));
      await settle();
      expect(cubit.isFollowing, isTrue);
      expect(repository.feeds, hasLength(1));

      await cubit.close();
      expect(feed.hasListener, isFalse);
    });

    test('a feed that broke keeps the map, tells it, and follows again on '
        'reconnect', () async {
      final cubit = build();
      await cubit.start(order);
      repository.feed.add(fixAt(at(0, 0), second: 1));
      await settle();

      repository.feed.addError(const NetworkFailure());
      await repository.feed.close();
      await settle();
      expect(cubit.state.status, CourierTrackingStatus.live);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.stale, isTrue);
      expect(cubit.isFollowing, isFalse);

      cubit.onReconnected();
      expect(cubit.isFollowing, isTrue);
      expect(repository.feeds, hasLength(2));
      await cubit.close();
    });

    test('at the door the feed ends and nothing turns stale', () async {
      final cubit = build(staleAfter: const Duration(milliseconds: 20));
      await cubit.start(order);

      repository.feed.add(
        fixAt(at(300, 400), second: 1, state: CourierFixState.arrived),
      );
      await repository.feed.close();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(cubit.state.arrived, isTrue);
      expect(cubit.state.stale, isFalse);
      cubit.onReconnected();
      expect(cubit.isFollowing, isFalse);
      await cubit.close();
    });

    test('closing the map stops the feed', () async {
      final cubit = build();
      await cubit.start(order);
      final feed = repository.feed;

      await cubit.close();
      expect(feed.hasListener, isFalse);
    });
  });
}
