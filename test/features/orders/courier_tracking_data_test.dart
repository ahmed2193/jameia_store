import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/data/datasources/courier_store_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_run.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_tracking_data_source.dart';
import 'package:hero_mart/src/features/orders/data/mappers/courier_tracking_mapper.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_fix_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_store_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_trip_model.dart';
import 'package:hero_mart/src/features/orders/data/repositories/courier_tracking_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip_request.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_vehicle.dart';

import 'courier_test_fakes.dart';

/// A branch list that never answers (a very slow link).
class HangingStores implements CourierStoreDataSource {
  final List<String> asked = [];

  @override
  Future<CourierStoreModel?> store(String storeId) {
    asked.add(storeId);
    return Completer<CourierStoreModel?>().future;
  }
}

void main() {
  Map<String, dynamic> point(double lat, double lng) => {
    'lat': lat,
    'lng': lng,
  };

  group('CourierTripModel', () {
    test('reads the ride, skipping a malformed corner', () {
      final trip = CourierTripModel.fromJson({
        'orderId': 'o1',
        'rider': {'name': 'Ali', 'vehicle': 'motorbike'},
        'approach': [point(29.32, 48.07), point(29.33, 48.07)],
        'route': [
          point(29.33, 48.07),
          {'lat': 'x'},
          point(29.34, 48.07),
        ],
      }).toEntity();

      expect(trip.orderId, 'o1');
      expect(trip.riderName, 'Ali');
      expect(trip.vehicle, CourierVehicle.motorbike);
      expect(trip.route.points, hasLength(2));
      expect(trip.approach, isNotNull);
    });

    test('a ride with no order or no road is no ride', () {
      expect(
        () => CourierTripModel.fromJson({
          'route': [point(1, 1), point(2, 2)],
        }),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => CourierTripModel.fromJson({
          'orderId': 'o1',
          'route': [point(1, 1)],
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('no approach and an unknown vehicle read as none', () {
      final trip = CourierTripModel.fromJson({
        'orderId': 'o1',
        'rider': {'vehicle': 'hoverboard'},
        'route': [point(1, 1), point(2, 2)],
      }).toEntity();

      expect(trip.approach, isNull);
      expect(trip.vehicle, CourierVehicle.other);
      expect(trip.riderName, '');
    });
  });

  group('CourierFixModel', () {
    test('reads a fix and its state', () {
      final fix = CourierFixModel.fromJson({
        ...point(29.33, 48.07),
        'at': '2026-09-30T10:00:00.000Z',
        'state': 'to_store',
        'etaSeconds': 240,
      }).toEntity();

      expect(fix.state, CourierFixState.toStore);
      expect(fix.etaSeconds, 240);
      expect(fix.at, DateTime.utc(2026, 9, 30, 10));
    });

    test('a fix nobody can place or date is no fix; an odd state is kept', () {
      expect(
        () => CourierFixModel.fromJson({'lat': 1, 'at': '2026-09-30T10:00Z'}),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => CourierFixModel.fromJson(point(1, 1)),
        throwsA(isA<ParsingException>()),
      );
      final odd = CourierFixModel.fromJson({
        ...point(1, 1),
        'at': '2026-09-30T10:00:00Z',
        'state': 'teleporting',
      }).toEntity();
      expect(odd.state, CourierFixState.other);
    });
  });

  group('DemoCourierRun', () {
    final start = DateTime.utc(2026, 9, 30, 10);
    DemoCourierRun run([String orderId = 'o1']) => DemoCourierRun.onGrid(
      orderId: orderId,
      destination: testOrigin,
      startedAt: start,
      riderName: 'Ali',
    );

    String stateAt(DemoCourierRun ride, Duration after) =>
        ride.fixJsonAt(start.add(after))[CourierFixModel.stateKey] as String;

    test('the same order always gets the same ride', () {
      expect(run().route.points, run().route.points);
      expect(run('o2').route.points, isNot(run().route.points));
    });

    test('the rider sets off from the store: one road, store to door', () {
      final ride = run();
      expect(ride.route.end, testOrigin);
      expect(ride.route.lengthMeters, greaterThan(700));
      final trip = CourierTripModel.fromJson(ride.tripJson()).toEntity();
      expect(trip.store, ride.route.start);
      expect(trip.approach, isNull);
      expect(trip.path.start, trip.store);
      expect(trip.vehicle, CourierVehicle.motorbike);
    });

    test('plays the phases in order, then stays at the door', () {
      final ride = run();
      final states = <String>[];
      int? lastEta;
      for (var s = 0; !ride.isOverAt(start.add(Duration(seconds: s))); s++) {
        final fix = ride.fixJsonAt(start.add(Duration(seconds: s)));
        final state = fix[CourierFixModel.stateKey] as String;
        if (states.isEmpty || states.last != state) states.add(state);
        final eta = fix[CourierFixModel.etaSecondsKey] as int;
        if (lastEta != null) expect(eta, lessThanOrEqualTo(lastEta));
        lastEta = eta;
      }
      expect(states, [
        CourierFixModel.assigningState,
        CourierFixModel.atStoreState,
        CourierFixModel.onTheWayState,
      ]);
      expect(
        stateAt(ride, const Duration(hours: 1)),
        CourierFixModel.arrivedState,
      );
      final done = ride.fixJsonAt(start.add(const Duration(hours: 1)));
      expect(done[CourierFixModel.etaSecondsKey], 0);
    });
  });

  group('DemoCourierTrackingDataSource', () {
    test(
      'keeps a ride\'s clock across opens and starts over once it ended',
      () async {
        var now = DateTime.utc(2026, 9, 30, 10);
        final source = DemoCourierTrackingDataSource(now: () => now);
        const request = CourierTripRequest(
          orderId: 'o1',
          destination: testOrigin,
        );

        final first = await source.getTrip(request);
        now = now.add(const Duration(seconds: 30));
        final again = await source.getTrip(request);
        expect(again.route.length, first.route.length);
        final fix = await source.watchCourier('o1').first;
        expect(fix.state, isNot(CourierFixModel.assigningState));

        now = now.add(const Duration(hours: 1));
        await source.getTrip(request);
        final restarted = await source.watchCourier('o1').first;
        expect(restarted.state, CourierFixModel.assigningState);
      },
    );

    test('pings until the rider is at the door, then ends', () async {
      var now = DateTime.utc(2026, 9, 30, 10);
      final source = DemoCourierTrackingDataSource(
        now: () => now = now.add(const Duration(seconds: 20)),
        pingEvery: Duration.zero,
      );
      await source.getTrip(
        const CourierTripRequest(orderId: 'o1', destination: testOrigin),
      );

      final fixes = await source.watchCourier('o1').toList();

      expect(fixes.last.state, CourierFixModel.arrivedState);
      expect(
        fixes.map((fix) => fix.state).toSet(),
        allOf(
          contains(CourierFixModel.onTheWayState),
          isNot(contains(CourierFixModel.toStoreState)),
        ),
      );
    });

    test('a branch slower than its budget: the ride leaves from a stand-in '
        'store', () async {
      final stores = HangingStores();
      final source = DemoCourierTrackingDataSource(
        stores: stores,
        branchBudget: const Duration(milliseconds: 10),
      );

      final trip = await source.getTrip(
        const CourierTripRequest(
          orderId: 'o1',
          storeId: 'b1',
          destination: testOrigin,
        ),
      );

      expect(stores.asked, ['b1']);
      expect(trip.store, isNotNull);
      expect(trip.storeName, '');
      expect(trip.route.last.lat, testOrigin.lat);
    });

    test('an ended ride is dropped when another order is planned', () async {
      var now = DateTime.utc(2026, 9, 30, 10);
      final source = DemoCourierTrackingDataSource(now: () => now);
      const first = CourierTripRequest(orderId: 'o1', destination: testOrigin);

      await source.getTrip(first);
      now = now.add(const Duration(hours: 1));
      await source.getTrip(
        const CourierTripRequest(orderId: 'o2', destination: testOrigin),
      );

      await expectLater(
        source.watchCourier('o1'),
        emitsError(isA<NotFoundException>()),
      );
      await source.getTrip(first);
      final restarted = await source.watchCourier('o1').first;
      expect(restarted.state, CourierFixModel.assigningState);
    });

    test('an order without a pin rides to the centre of Kuwait City', () async {
      final source = DemoCourierTrackingDataSource();
      final trip = await source.getTrip(
        const CourierTripRequest(orderId: 'o9'),
      );
      final door = trip.route.last;
      expect(door.lat, DemoCourierTrackingDataSource.fallbackDestination.lat);
      expect(door.lng, DemoCourierTrackingDataSource.fallbackDestination.lng);
    });
  });

  group('CourierTrackingRepositoryImpl', () {
    test('maps the ride and the fixes to entities', () async {
      final repository = CourierTrackingRepositoryImpl(
        DemoCourierTrackingDataSource(),
      );
      final trip = (await repository.getTrip(
        const CourierTripRequest(
          orderId: 'o1',
          destination: testOrigin,
          riderName: 'Ali',
        ),
      )).getOrElse(() => throw StateError('no trip'));
      expect(trip.riderName, 'Ali');

      final fix = await repository.watchCourier('o1').first;
      expect(fix.state, CourierFixState.assigning);
    });

    test('a feed with no ride is told as a failure', () async {
      final repository = CourierTrackingRepositoryImpl(
        DemoCourierTrackingDataSource(),
      );
      await expectLater(
        repository.watchCourier('nothing'),
        emitsError(isA<NotFoundFailure>()),
      );
    });
  });
}
