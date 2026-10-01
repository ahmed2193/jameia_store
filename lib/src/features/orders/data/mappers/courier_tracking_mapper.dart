import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/courier_fix.dart';
import '../../domain/entities/courier_route.dart';
import '../../domain/entities/courier_route_source.dart';
import '../../domain/entities/courier_trip.dart';
import '../../domain/entities/courier_vehicle.dart';
import '../models/courier_fix_model.dart';
import '../models/courier_point_model.dart';
import '../models/courier_trip_model.dart';

extension CourierPointMapper on CourierPointModel {
  GeoPointEntity toEntity() => GeoPointEntity(lat: lat, lng: lng);
}

extension CourierTripMapper on CourierTripModel {
  CourierTrip toEntity() => CourierTrip(
    orderId: orderId,
    route: _road(route),
    approach: approach.length < CourierTripModel.minRoutePoints
        ? null
        : _road(approach),
    store: store?.toEntity(),
    storeName: storeName,
    home: home?.toEntity(),
    riderName: riderName,
    riderPhone: riderPhone,
    vehicle: switch (vehicle) {
      CourierTripModel.motorbikeVehicle => CourierVehicle.motorbike,
      CourierTripModel.carVehicle => CourierVehicle.car,
      CourierTripModel.bicycleVehicle => CourierVehicle.bicycle,
      _ => CourierVehicle.other,
    },
    routeSource: switch (routeSource) {
      CourierTripModel.googleSource => CourierRouteSource.google,
      CourierTripModel.osmSource => CourierRouteSource.openStreetMap,
      _ => CourierRouteSource.estimated,
    },
  );

  static CourierRoute _road(List<CourierPointModel> points) =>
      CourierRoute([for (final point in points) point.toEntity()]);
}

extension CourierFixMapper on CourierFixModel {
  CourierFix toEntity() => CourierFix(
    position: position.toEntity(),
    at: at,
    state: switch (state) {
      CourierFixModel.assigningState => CourierFixState.assigning,
      CourierFixModel.toStoreState => CourierFixState.toStore,
      CourierFixModel.atStoreState => CourierFixState.atStore,
      CourierFixModel.onTheWayState => CourierFixState.onTheWay,
      CourierFixModel.arrivedState => CourierFixState.arrived,
      _ => CourierFixState.other,
    },
    etaSeconds: etaSeconds,
  );
}
