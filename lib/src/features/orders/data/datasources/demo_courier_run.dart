import 'dart:math' as math;

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/courier_route.dart';
import '../../domain/entities/geo_metric_frame.dart';
import '../models/courier_fix_model.dart';
import '../models/courier_point_model.dart';
import '../models/courier_trip_model.dart';
import 'demo_courier_drive.dart';
import 'demo_courier_paces.dart';
import 'demo_courier_streets.dart';

/// One simulated ride — the stand-in for the rider feed the backend does not
/// have yet — reporting what a courier app would, phase by phase from
/// [startedAt]:
///
/// 1. `assigning` for [assigningDwell]: a rider at the store is being
///    given the order;
/// 2. `at_store` for [pickupDwell]: they collect it;
/// 3. `on_the_way`: they ride it from the store to the door ([route], one
///    red light on the way);
/// 4. `arrived`: at the door.
///
/// The rider sets off from the store: the ride has no way in to it.
///
/// The roads are real ones a road service drew ([DemoCourierRun.onRoads]),
/// or streets made up around the door when none answered
/// ([DemoCourierRun.onGrid]). A fix carries the seconds left to the door and
/// a position a few metres off the road, like real GPS.
class DemoCourierRun {
  /// A ride on real roads: [route] (the store → the door) as [routeSource]
  /// drew it, [routePaces] how fast each stretch may be ridden (empty =
  /// unknown), and [store] / [home] the pins the road starts and ends near.
  factory DemoCourierRun.onRoads({
    required String orderId,
    required DateTime startedAt,
    required List<GeoPointEntity> route,
    required String routeSource,
    required GeoPointEntity store,
    required GeoPointEntity home,
    List<double> routePaces = const <double>[],
    String riderName = '',
    String riderPhone = '',
    String storeName = '',
  }) {
    final routeRoad = CourierRoute(route);
    final routePace = DemoCourierPaces(route, routePaces);
    return DemoCourierRun._(
      orderId: orderId,
      riderName: riderName,
      riderPhone: riderPhone,
      storeName: storeName,
      startedAt: startedAt,
      route: routeRoad,
      store: store,
      home: home,
      routeSource: routeSource,
      frame: GeoMetricFrame(home),
      routeDrive: DemoCourierDrive(
        routeRoad.lengthMeters,
        DemoCourierDrive.turnsOf(routeRoad),
        redLight: true,
        paceAt: routePace.at,
      ),
    );
  }

  /// A ride on streets made up around [destination]
  /// ([DemoCourierStreets]).
  factory DemoCourierRun.onGrid({
    required String orderId,
    required GeoPointEntity destination,
    required DateTime startedAt,
    String riderName = '',
    String riderPhone = '',
    String storeName = '',
  }) {
    final frame = GeoMetricFrame(destination);
    final streets = DemoCourierStreets(orderId);
    CourierRoute road(List<math.Point<double>> corners) => CourierRoute([
      for (final point in DemoCourierStreets.rounded(corners))
        frame.toPoint(point),
    ]);
    List<double> turnsOf(CourierRoute road, List<math.Point<double>> corners) {
      final turns = <double>[];
      var along = 0.0;
      for (final corner in corners.sublist(1, corners.length - 1)) {
        along = road.project(frame.toPoint(corner), from: along);
        turns.add(along);
      }
      return turns;
    }

    final route = road(streets.route);
    return DemoCourierRun._(
      orderId: orderId,
      riderName: riderName,
      riderPhone: riderPhone,
      storeName: storeName,
      startedAt: startedAt,
      route: route,
      store: route.start,
      home: route.end,
      routeSource: CourierTripModel.estimatedSource,
      frame: frame,
      routeDrive: DemoCourierDrive(
        route.lengthMeters,
        turnsOf(route, streets.route),
        redLight: true,
      ),
    );
  }

  DemoCourierRun._({
    required this.orderId,
    required this.riderName,
    required this.riderPhone,
    required this.storeName,
    required this.startedAt,
    required this.route,
    required this.store,
    required this.home,
    required this.routeSource,
    required this._frame,
    required this._routeDrive,
  });

  /// How long finding a rider takes.
  static const Duration assigningDwell = Duration(seconds: 5);

  /// How long the rider spends collecting the order at the store.
  static const Duration pickupDwell = Duration(seconds: 8);

  /// The vehicle every simulated rider rides.
  static const String vehicle = CourierTripModel.motorbikeVehicle;

  /// GPS noise: metres off the road, and how fast it wanders (rad / s).
  static const double _gpsNoiseMeters = 2;
  static const double _gpsNoiseRate = 1.7;
  static const double _halfTurnDegrees = 180;

  final String orderId;
  final String riderName;
  final String riderPhone;

  /// The store's name; empty for a stand-in store.
  final String storeName;
  final DateTime startedAt;

  /// Store → door.
  final CourierRoute route;

  /// The store's and the door's pins.
  final GeoPointEntity store;
  final GeoPointEntity home;

  /// [CourierTripModel.routeSource].
  final String routeSource;
  final GeoMetricFrame _frame;
  final DemoCourierDrive _routeDrive;

  static double _secondsOf(Duration duration) =>
      duration.inMilliseconds / Duration.millisecondsPerSecond;

  // When each phase starts, in seconds from [startedAt].
  double get _atStoreAt => _secondsOf(assigningDwell);
  double get _onTheWayAt => _atStoreAt + _secondsOf(pickupDwell);
  double get _arrivedAt => _onTheWayAt + _routeDrive.totalSeconds;

  bool isOverAt(DateTime now) =>
      _secondsOf(now.difference(startedAt)) >= _arrivedAt;

  /// The ride as the feed sends it ([CourierTripModel]).
  Map<String, dynamic> tripJson() => <String, dynamic>{
    CourierTripModel.orderIdKey: orderId,
    CourierTripModel.riderKey: <String, dynamic>{
      CourierTripModel.nameKey: riderName,
      CourierTripModel.phoneKey: riderPhone,
      CourierTripModel.vehicleKey: vehicle,
    },
    CourierTripModel.routeKey: _json(route),
    CourierTripModel.storeKey: _point(store),
    CourierTripModel.storeNameKey: storeName,
    CourierTripModel.homeKey: _point(home),
    CourierTripModel.routeSourceKey: routeSource,
  };

  static List<Map<String, dynamic>> _json(CourierRoute road) => [
    for (final point in road.points) _point(point),
  ];

  static Map<String, dynamic> _point(GeoPointEntity point) =>
      CourierPointModel(lat: point.lat, lng: point.lng).toJson();

  /// The fix the rider would send at [now] ([CourierFixModel]).
  Map<String, dynamic> fixJsonAt(DateTime now) {
    final elapsed = _secondsOf(now.difference(startedAt));
    final String state;
    final GeoPointEntity position;
    if (elapsed < _atStoreAt) {
      state = CourierFixModel.assigningState;
      position = route.start;
    } else if (elapsed < _onTheWayAt) {
      state = CourierFixModel.atStoreState;
      position = route.start;
    } else if (elapsed < _arrivedAt) {
      final riding = elapsed - _onTheWayAt;
      state = CourierFixModel.onTheWayState;
      position = _offRoad(route, _routeDrive.metersAt(riding), riding);
    } else {
      state = CourierFixModel.arrivedState;
      position = route.end;
    }
    return <String, dynamic>{
      ..._point(position),
      CourierFixModel.atKey: now.toUtc().toIso8601String(),
      CourierFixModel.stateKey: state,
      CourierFixModel.etaSecondsKey: math.max(0, _arrivedAt - elapsed).ceil(),
    };
  }

  /// The point [meters] down [road], pushed sideways by GPS noise.
  GeoPointEntity _offRoad(CourierRoute road, double meters, double seconds) {
    final heading = road.headingAt(meters) * math.pi / _halfTurnDegrees;
    final offset = _gpsNoiseMeters * math.sin(seconds * _gpsNoiseRate);
    final onRoad = _frame.toMeters(road.pointAt(meters));
    // Right of the direction of travel: (cos h, −sin h) east / north.
    return _frame.toPoint(
      math.Point<double>(
        onRoad.x + math.cos(heading) * offset,
        onRoad.y - math.sin(heading) * offset,
      ),
    );
  }
}
