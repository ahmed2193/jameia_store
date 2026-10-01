import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_progress.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_journey.dart';
import 'package:hero_mart/src/features/orders/domain/entities/steady_eta.dart';

import 'courier_test_fakes.dart';

void main() {
  const tolerance = 0.5;

  CourierProgress progressOf(
    CourierFixState state, {
    required double pathMeters,
    int? etaSeconds,
  }) => CourierProgress.of(
    testTrip(),
    fixAt(at(0, 0), state: state, etaSeconds: etaSeconds),
    pathMeters: pathMeters,
  );

  group('CourierProgress', () {
    test('reads each report of the feed as the customer\'s stage', () {
      expect(
        progressOf(CourierFixState.assigning, pathMeters: 50).stage,
        CourierStage.assigning,
      );
      expect(
        progressOf(CourierFixState.toStore, pathMeters: 50).stage,
        CourierStage.toStore,
      );
      expect(
        progressOf(CourierFixState.atStore, pathMeters: 0).stage,
        CourierStage.atStore,
      );
      expect(
        progressOf(CourierFixState.onTheWay, pathMeters: 300).stage,
        CourierStage.onTheWay,
      );
      expect(
        progressOf(CourierFixState.arrived, pathMeters: 0).stage,
        CourierStage.arrived,
      );
    });

    test('bringing the order within 300 m of the door is "almost there"', () {
      // The path is 900 m: 610 m along leaves 290 m.
      expect(
        progressOf(CourierFixState.onTheWay, pathMeters: 610).stage,
        CourierStage.nearby,
      );
      expect(
        progressOf(CourierFixState.other, pathMeters: 610).stage,
        CourierStage.nearby,
      );
    });

    test('a rider at the store or the door is exactly there', () {
      final atStore = progressOf(CourierFixState.atStore, pathMeters: 10);
      expect(atStore.pathMeters, closeTo(200, tolerance));
      expect(atStore.deliveryFraction, closeTo(0, 0.001));

      final arrived = progressOf(CourierFixState.arrived, pathMeters: 10);
      expect(arrived.pathMeters, closeTo(900, tolerance));
      expect(arrived.deliveryFraction, 1);
      expect(arrived.minutesLeft, isNull);
      expect(arrived.arrived, isTrue);
    });

    test('the share of the road is counted from the store', () {
      expect(
        progressOf(CourierFixState.toStore, pathMeters: 100).deliveryFraction,
        0,
      );
      expect(
        progressOf(CourierFixState.onTheWay, pathMeters: 550).deliveryFraction,
        closeTo(0.5, 0.01),
      );
    });

    test('minutes: the feed\'s estimate rounded up, else the road left', () {
      expect(
        progressOf(
          CourierFixState.onTheWay,
          pathMeters: 300,
          etaSeconds: 61,
        ).minutesLeft,
        2,
      );
      expect(
        progressOf(
          CourierFixState.onTheWay,
          pathMeters: 890,
          etaSeconds: 0,
        ).minutesLeft,
        1,
      );
      // 540 m left at 6 m/s = 90 s → 2 min.
      expect(
        progressOf(CourierFixState.onTheWay, pathMeters: 360).minutesLeft,
        2,
      );
    });
  });

  test('arrives at the fix time plus the exact seconds left', () {
    final progress = progressOf(
      CourierFixState.onTheWay,
      pathMeters: 360,
      etaSeconds: 150,
    );

    expect(progress.minutesLeft, 3);
    expect(progress.secondsLeft, 150);
    expect(progress.arrivesAt, progress.at.add(const Duration(seconds: 150)));
    // With no estimate: 540 m left at 6 m/s.
    final estimated = progressOf(CourierFixState.onTheWay, pathMeters: 360);
    expect(estimated.secondsLeft, 90);
    expect(estimated.arrivesAt, estimated.at.add(const Duration(seconds: 90)));
    final arrived = progressOf(CourierFixState.arrived, pathMeters: 700);
    expect(arrived.secondsLeft, isNull);
    expect(arrived.arrivesAt, isNull);
  });

  test('a countdown never jumps back up within the same minute', () {
    // 359 s left, then 18 s later 341 s: both "6 min".
    final first = CourierProgress.of(
      testTrip(),
      fixAt(at(0, 0), etaSeconds: 359),
      pathMeters: 300,
    );
    final second = CourierProgress.of(
      testTrip(),
      fixAt(at(0, 0), second: 18, etaSeconds: 341),
      pathMeters: 450,
    );

    expect(first.minutesLeft, second.minutesLeft);
    expect(
      second.arrivesAt!.difference(first.arrivesAt!).inMilliseconds.abs(),
      lessThanOrEqualTo(Duration.millisecondsPerSecond),
    );
    // Held minutes keep the seconds.
    expect(second.withMinutes(7).secondsLeft, 341);
    expect(second.withMinutes(7).arrivesAt, second.arrivesAt);
  });

  group('CourierProgress.glideFrom', () {
    CourierProgress atSecond(int second) => CourierProgress.of(
      testTrip(),
      fixAt(at(0, 0), second: second),
      pathMeters: 300,
    );

    test('glides across the gap between two close fixes', () {
      expect(atSecond(12).glideFrom(atSecond(10)), const Duration(seconds: 2));
      expect(
        atSecond(15).glideFrom(atSecond(10)),
        CourierProgress.longestGlide,
      );
    });

    test('steps after no gap, a gap back in time, a long gap or no fix', () {
      expect(atSecond(10).glideFrom(atSecond(10)), isNull);
      expect(atSecond(8).glideFrom(atSecond(10)), isNull);
      expect(atSecond(16).glideFrom(atSecond(10)), isNull);
      expect(atSecond(10).glideFrom(null), isNull);
    });
  });

  group('SteadyEta', () {
    test('shows a drop at once', () {
      final eta = const SteadyEta(minutes: 6).next(4);
      expect(eta.minutes, 4);
    });

    test('holds a one-minute rise until three fixes carry it', () {
      var eta = const SteadyEta(minutes: 5);
      eta = eta.next(6);
      expect(eta.minutes, 5);
      eta = eta.next(6);
      expect(eta.minutes, 5);
      eta = eta.next(6);
      expect(eta.minutes, 6);
    });

    test('a single noisy fix never bumps the minutes', () {
      var eta = const SteadyEta(minutes: 5);
      eta = eta.next(6);
      eta = eta.next(5);
      eta = eta.next(6);
      expect(eta.minutes, 5);
    });

    test('shows a rise of two minutes or more at once', () {
      expect(const SteadyEta(minutes: 5).next(7).minutes, 7);
    });

    test('nothing to promise clears it; the first reading shows as is', () {
      expect(const SteadyEta(minutes: 5).next(null).minutes, isNull);
      expect(const SteadyEta().next(9).minutes, 9);
    });
  });

  group('OrderJourney.tracksRider', () {
    OrderEntity order(
      OrderStatus status, {
      FulfillmentMode mode = FulfillmentMode.delivery,
    }) => OrderEntity(
      id: 'o1',
      orderNumber: '1001',
      status: status,
      fulfillmentMode: mode,
    );

    test('while a delivery is on its way', () {
      for (final status in [
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.picking,
        OrderStatus.ready,
        OrderStatus.outForDelivery,
      ]) {
        expect(
          OrderJourney.of(order(status)).tracksRider,
          isTrue,
          reason: '$status',
        );
      }
    });

    test('not once it stopped, nor for a pickup order', () {
      for (final status in [
        OrderStatus.delivered,
        OrderStatus.cancelled,
        OrderStatus.deliveryFailed,
        OrderStatus.other,
      ]) {
        expect(
          OrderJourney.of(order(status)).tracksRider,
          isFalse,
          reason: '$status',
        );
      }
      expect(
        OrderJourney.of(
          order(OrderStatus.picking, mode: FulfillmentMode.pickup),
        ).tracksRider,
        isFalse,
      );
    });
  });
}
