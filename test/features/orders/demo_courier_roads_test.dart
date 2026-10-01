import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/features/orders/data/datasources/courier_store_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_drive.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_paces.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_run.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_courier_tracking_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/road_route_data_source.dart';
import 'package:hero_mart/src/features/orders/data/mappers/courier_tracking_mapper.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_fix_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_point_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_store_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_trip_model.dart';
import 'package:hero_mart/src/features/orders/data/models/road_route_model.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route_source.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip_request.dart';
import 'package:hero_mart/src/features/orders/domain/entities/geo_metric_frame.dart';

import 'courier_test_fakes.dart';

class FakeStores implements CourierStoreDataSource {
  FakeStores({this.branch, this.error});

  final CourierStoreModel? branch;
  final AppException? error;
  final List<String> asked = [];

  @override
  Future<CourierStoreModel?> store(String storeId) async {
    asked.add(storeId);
    if (error != null) throw error!;
    return branch;
  }
}

class RecordingRoads implements RoadRouteDataSource {
  RecordingRoads({this.error});

  final AppException? error;
  final List<List<GeoPointEntity>> asked = [];

  @override
  Future<RoadRouteModel> route(
    List<GeoPointEntity> stops, {
    Duration? timeout,
  }) async {
    asked.add(stops);
    if (error != null) throw error!;
    CourierPointModel point(GeoPointEntity p) =>
        CourierPointModel(lat: p.lat, lng: p.lng);
    // Each leg: straight to a corner halfway, then on to the stop.
    RoadLegModel leg(GeoPointEntity from, GeoPointEntity to) => RoadLegModel(
      points: [
        point(from),
        point(GeoPointEntity(lat: to.lat, lng: from.lng)),
        point(to),
      ],
      paces: const [12, 12],
    );
    return RoadRouteModel(
      legs: [
        for (var i = 1; i < stops.length; i++) leg(stops[i - 1], stops[i]),
      ],
      source: RoadRouteModel.osmSource,
    );
  }
}

double metersBetween(GeoPointEntity a, GeoPointEntity b) {
  final frame = GeoMetricFrame(a);
  return frame.toMeters(a).distanceTo(frame.toMeters(b));
}

void main() {
  final now = DateTime.utc(2026, 9, 30, 12);
  final door = at(0, 0);
  final branchPin = at(600, 900);
  final branch = CourierStoreModel(
    id: 'b1',
    name: 'Salmiya',
    point: CourierPointModel(lat: branchPin.lat, lng: branchPin.lng),
    phone: '+96522221111',
  );
  final request = CourierTripRequest(
    orderId: 'o1',
    storeId: 'b1',
    destination: door,
    riderName: 'Ali',
  );

  Future<CourierTrip> tripOf(DemoCourierTrackingDataSource source) async =>
      (await source.getTrip(request)).toEntity();

  group('DemoCourierTrackingDataSource on real roads', () {
    test(
      'rides from the order branch to the door on the drawn roads',
      () async {
        final roads = RecordingRoads();
        final stores = FakeStores(branch: branch);
        final source = DemoCourierTrackingDataSource(
          stores: stores,
          roads: roads,
          now: () => now,
        );

        final trip = await tripOf(source);

        expect(stores.asked, ['b1']);
        // The rider sets off from the store: one road, store → door.
        expect(roads.asked.single, [branchPin, door]);
        expect(trip.routeSource, CourierRouteSource.openStreetMap);
        expect(trip.store, branchPin);
        expect(trip.home, door);
        expect(trip.riderPhone, '+96522221111');
        expect(trip.canCall, isTrue);
        expect(trip.lineEnding, '1111');
        expect(trip.storeName, 'Salmiya');
        expect(trip.approach, isNull);
        expect(trip.route.start, branchPin);
        expect(trip.route.end, door);
      },
    );

    test('keeps the ride, and its roads, while it runs', () async {
      final roads = RecordingRoads();
      final source = DemoCourierTrackingDataSource(
        stores: FakeStores(branch: branch),
        roads: roads,
        now: () => now,
      );

      final first = await tripOf(source);
      final again = await tripOf(source);

      expect(again, first);
      expect(roads.asked, hasLength(1));
    });

    test('opened twice while planning: one road request, one ride', () async {
      final roads = RecordingRoads();
      final source = DemoCourierTrackingDataSource(
        stores: FakeStores(branch: branch),
        roads: roads,
        now: () => now,
      );

      final trips = await Future.wait([tripOf(source), tripOf(source)]);

      expect(trips.last, trips.first);
      expect(roads.asked, hasLength(1));
    });

    test('no road service: made-up streets, still the branch line', () async {
      final source = DemoCourierTrackingDataSource(
        stores: FakeStores(branch: branch),
        roads: RecordingRoads(error: const NoInternetConnectionException()),
        now: () => now,
      );

      final trip = await tripOf(source);

      expect(trip.routeSource, CourierRouteSource.estimated);
      expect(trip.route.lengthMeters, greaterThan(0));
      expect(trip.riderPhone, '+96522221111');
    });

    test('a branch far from the door, or none: a stand-in store', () async {
      final far = CourierStoreModel(
        id: 'b1',
        point: CourierPointModel(lat: at(0, 20000).lat, lng: door.lng),
      );
      for (final stores in [
        FakeStores(branch: far),
        FakeStores(error: const ServerException('down')),
      ]) {
        final roads = RecordingRoads();
        final source = DemoCourierTrackingDataSource(
          stores: stores,
          roads: roads,
          now: () => now,
        );

        final trip = await tripOf(source);

        final store = roads.asked.single.first;
        expect(metersBetween(store, door), inInclusiveRange(899, 1601));
        expect(trip.riderPhone, isEmpty);
        expect(trip.canCall, isFalse);
        expect(trip.storeName, isEmpty);
      }
    });

    test('the rider collects at the store, then rides the real road', () async {
      var clock = now;
      final source = DemoCourierTrackingDataSource(
        stores: FakeStores(branch: branch),
        roads: RecordingRoads(),
        now: () => clock,
      );
      final trip = await tripOf(source);

      final first = await source.watchCourier('o1').first;
      clock = now.add(DemoCourierRun.assigningDwell);
      final collecting = await source.watchCourier('o1').first;
      clock = now.add(
        DemoCourierRun.assigningDwell +
            DemoCourierRun.pickupDwell +
            const Duration(seconds: 20),
      );
      final riding = await source.watchCourier('o1').first;

      expect(first.state, CourierFixModel.assigningState);
      expect(collecting.state, CourierFixModel.atStoreState);
      expect(collecting.position.toEntity(), trip.store);
      expect(riding.state, CourierFixModel.onTheWayState);
      final along = trip.path.project(riding.position.toEntity());
      expect(along, greaterThan(50));
    });
  });

  group('DemoCourierDrive on a drawn road', () {
    test('finds the corner of an L road once', () {
      final turns = DemoCourierDrive.turnsOf(lRoute());

      expect(turns, hasLength(1));
      expect(turns.single, closeTo(400, 20));
    });

    test('a faster road is ridden faster, within a rider pace', () {
      final road = lRoute();
      final turns = DemoCourierDrive.turnsOf(road);
      final slow = DemoCourierDrive(road.lengthMeters, turns, paceAt: (_) => 5);
      final fast = DemoCourierDrive(
        road.lengthMeters,
        turns,
        paceAt: (_) => 30,
      );
      final unknown = DemoCourierDrive(
        road.lengthMeters,
        turns,
        paceAt: (_) => 0,
      );
      final plain = DemoCourierDrive(road.lengthMeters, turns);

      expect(fast.totalSeconds, lessThan(slow.totalSeconds));
      expect(unknown.totalSeconds, closeTo(plain.totalSeconds, 1e-9));
      // Capped at 16 m/s: 700 m takes well over 700 / 30 s.
      expect(fast.totalSeconds, greaterThan(700 / 16));
    });

    test('paces are looked up by metres along the road', () {
      final paces = DemoCourierPaces(
        [at(0, 0), at(0, 100), at(0, 300)],
        [5, 10],
      );

      expect(paces.at(50), 5);
      expect(paces.at(150), 10);
      expect(paces.at(1000), 10);
      expect(DemoCourierPaces([at(0, 0), at(0, 1)], const []).at(0), 0);
    });
  });

  group('CourierTripModel', () {
    test('reads the pins, the rider line and who drew the road', () {
      final trip = CourierTripModel.fromJson({
        'orderId': 'o1',
        'route': [
          {'lat': 29.3, 'lng': 48.0},
          {'lat': 29.31, 'lng': 48.01},
        ],
        'store': {'lat': 29.29, 'lng': 47.99},
        'home': {'lat': 'bad'},
        'rider': {'name': 'Ali', 'phone': '+965', 'vehicle': 'car'},
        'routeSource': 'google',
      }).toEntity();

      expect(trip.store, const GeoPointEntity(lat: 29.29, lng: 47.99));
      expect(trip.home, trip.route.end);
      expect(trip.riderPhone, '+965');
      expect(trip.routeSource, CourierRouteSource.google);
    });

    test('an unknown road source reads as estimated', () {
      final trip = CourierTripModel.fromJson({
        'orderId': 'o1',
        'route': [
          {'lat': 29.3, 'lng': 48.0},
          {'lat': 29.31, 'lng': 48.01},
        ],
        'routeSource': 'mystery',
      }).toEntity();

      expect(trip.routeSource, CourierRouteSource.estimated);
      expect(trip.canCall, isFalse);
    });
  });
}
