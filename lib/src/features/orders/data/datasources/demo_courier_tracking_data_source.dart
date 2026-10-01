import 'dart:async';
import 'dart:developer';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/courier_trip_request.dart';
import '../../domain/entities/geo_metric_frame.dart';
import '../mappers/courier_tracking_mapper.dart';
import '../models/courier_fix_model.dart';
import '../models/courier_store_model.dart';
import '../models/courier_trip_model.dart';
import '../models/road_route_model.dart';
import 'courier_store_data_source.dart';
import 'courier_tracking_data_source.dart';
import 'demo_courier_run.dart';
import 'demo_courier_streets.dart';
import 'road_route_data_source.dart';

/// The rider feed, simulated (dummy data until the backend tracks riders) —
/// but on the real map: the ride leaves from the order's own branch
/// ([CourierStoreDataSource]), goes to the order's own door, and follows the
/// real roads between them ([RoadRouteDataSource]); the rider sets off from
/// the store. With no road service reachable the ride runs on streets made
/// up around the door (from a store on them); with no branch pin, from a
/// stand-in store nearby; with no door pin, to the centre of Kuwait City.
///
/// The first time an order's map opens, a [DemoCourierRun] starts for it and
/// keeps its clock while the app runs — close the map and open it again and
/// the rider is further down the road. A ride that has ended starts over on
/// the next open. The frames go through the same DTOs a real feed would,
/// one every [pingEvery] (the pace of a courier app's GPS reports).
class DemoCourierTrackingDataSource implements CourierTrackingDataSource {
  DemoCourierTrackingDataSource({
    this._stores,
    this._roads,
    DateTime Function()? now,
    this.pingEvery = defaultPingEvery,
    this.branchBudget = AppConstants.roadRouteBudget,
  }) : _now = now ?? DateTime.now;

  static const Duration defaultPingEvery = Duration(seconds: 2);

  /// How long the ride waits for the order's branch before it leaves from a
  /// stand-in store instead (the same budget as each road service, so a slow
  /// link never holds the loader for the API client's full timeouts). The
  /// branch list keeps loading meanwhile, so a later open gets the real one.
  final Duration branchBudget;

  /// Where a ride goes when the order's address has no pin.
  static const GeoPointEntity fallbackDestination = GeoPointEntity(
    lat: 29.3759,
    lng: 47.9774,
  );

  /// A branch further than this from the door (straight line) is not where a
  /// real rider would come from: a stand-in store nearby is used instead.
  static const double maxStoreMeters = 8000;

  static const String _logName = 'courier';

  final CourierStoreDataSource? _stores;
  final RoadRouteDataSource? _roads;
  final DateTime Function() _now;
  final Duration pingEvery;
  final Map<String, DemoCourierRun> _runs = <String, DemoCourierRun>{};

  /// Rides being planned: the map opened again meanwhile waits for the same
  /// plan (one road request, one ride), never starts a second.
  final Map<String, Future<DemoCourierRun>> _planning =
      <String, Future<DemoCourierRun>>{};

  @override
  Future<CourierTripModel> getTrip(CourierTripRequest request) async {
    // A ride that has ended is forgotten (its road and samples freed): the
    // next open of its order plans a new one, as it always did.
    final now = _now();
    _runs.removeWhere((_, run) => run.isOverAt(now));
    final current = _runs[request.orderId];
    if (current != null) {
      return CourierTripModel.fromJson(current.tripJson());
    }
    final orderId = request.orderId;
    final DemoCourierRun run;
    try {
      run = await (_planning[orderId] ??= _plan(request));
    } finally {
      unawaited(_planning.remove(orderId));
    }
    _runs[orderId] = run;
    return CourierTripModel.fromJson(run.tripJson());
  }

  @override
  Stream<CourierFixModel> watchCourier(String orderId) async* {
    final run = _runs[orderId];
    if (run == null) throw const NotFoundException('no ride for this order');
    while (true) {
      final frame = run.fixJsonAt(_now());
      final CourierFixModel fix;
      try {
        fix = CourierFixModel.fromJson(frame);
      } on ParsingException catch (error) {
        log('dropped frame: $error', name: _logName);
        await Future<void>.delayed(pingEvery);
        continue;
      }
      yield fix;
      if (fix.state == CourierFixModel.arrivedState) return;
      await Future<void>.delayed(pingEvery);
    }
  }

  Future<DemoCourierRun> _plan(CourierTripRequest request) async {
    final home = request.destination ?? fallbackDestination;
    final branch = await _branchOf(request.storeId);
    final pin = branch?.point?.toEntity();
    final atBranch = pin != null && _metersBetween(pin, home) <= maxStoreMeters;
    final store = atBranch
        ? pin
        : DemoCourierStreets.storeNear(home, request.orderId);
    final storeName = atBranch ? branch?.name ?? '' : '';
    final riderPhone = branch?.phone ?? '';
    final roads = _roads;
    if (roads != null) {
      try {
        final road = await roads.route([store, home]);
        return _onRoads(request, road, store, home, riderPhone, storeName);
      } on AppException catch (error) {
        log('no road route, made-up streets: $error', name: _logName);
      }
    }
    return DemoCourierRun.onGrid(
      orderId: request.orderId,
      destination: home,
      startedAt: _now(),
      riderName: request.riderName,
      riderPhone: riderPhone,
    );
  }

  DemoCourierRun _onRoads(
    CourierTripRequest request,
    RoadRouteModel road,
    GeoPointEntity store,
    GeoPointEntity home,
    String riderPhone,
    String storeName,
  ) {
    // Two stops, one leg: the store → the door.
    final route = road.legs.last;
    return DemoCourierRun.onRoads(
      orderId: request.orderId,
      startedAt: _now(),
      route: [for (final point in route.points) point.toEntity()],
      routePaces: route.paces,
      routeSource: road.source == RoadRouteModel.googleSource
          ? CourierTripModel.googleSource
          : CourierTripModel.osmSource,
      store: store,
      home: home,
      riderName: request.riderName,
      riderPhone: riderPhone,
      storeName: storeName,
    );
  }

  /// The order's branch; `null` when unknown or unreachable (the ride then
  /// leaves from a stand-in store), and when slower than [branchBudget].
  Future<CourierStoreModel?> _branchOf(String storeId) async {
    final stores = _stores;
    if (stores == null) return null;
    try {
      return await stores
          .store(storeId)
          .timeout(branchBudget, onTimeout: () => null);
    } on AppException catch (error) {
      log('no branch pin: $error', name: _logName);
      return null;
    }
  }

  static double _metersBetween(GeoPointEntity a, GeoPointEntity b) {
    final frame = GeoMetricFrame(a);
    return frame.toMeters(a).distanceTo(frame.toMeters(b));
  }
}
