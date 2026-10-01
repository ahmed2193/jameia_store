import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import 'courier_route.dart';
import 'courier_route_source.dart';
import 'courier_vehicle.dart';

/// A ride to follow on the live map: whose order it is, the [route] from the
/// store (its start) to the customer's door (its end), the rider's
/// [approach] to the store when they start somewhere else, and who rides it.
///
/// [path] is the whole ride in one road — the approach, then the route — so
/// the rider glides on without a seam when they leave the store with the
/// order.
///
/// A road drawn by a road service starts and ends on the street, a few
/// metres from the store's and the door's own pins; [store] and [home] are
/// those pins when the feed sends them, else the road's ends.
class CourierTrip extends Equatable {
  factory CourierTrip({
    required String orderId,
    required CourierRoute route,
    CourierRoute? approach,
    GeoPointEntity? store,
    String storeName = '',
    GeoPointEntity? home,
    String riderName = '',
    String riderPhone = '',
    CourierVehicle vehicle = CourierVehicle.other,
    CourierRouteSource routeSource = CourierRouteSource.estimated,
  }) => CourierTrip._(
    orderId: orderId,
    route: route,
    approach: approach,
    path: approach == null
        ? route
        : CourierRoute([...approach.points, ...route.points]),
    store: store ?? route.start,
    storeName: storeName,
    home: home ?? route.end,
    riderName: riderName,
    riderPhone: riderPhone,
    vehicle: vehicle,
    routeSource: routeSource,
  );

  const CourierTrip._({
    required this.orderId,
    required this.route,
    required this.approach,
    required this.path,
    required this.store,
    required this.storeName,
    required this.home,
    required this.riderName,
    required this.riderPhone,
    required this.vehicle,
    required this.routeSource,
  });

  final String orderId;

  /// Store → door.
  final CourierRoute route;

  /// Where the rider sets off → store; `null` when they start at the store.
  final CourierRoute? approach;

  /// [approach] then [route].
  final CourierRoute path;

  /// The store's pin and the door's pin.
  final GeoPointEntity store;
  final GeoPointEntity home;

  /// The store's name; empty when the feed does not name it.
  final String storeName;

  /// Empty when the feed does not name the rider.
  final String riderName;

  /// The number that reaches the rider (a masked line, never their own);
  /// empty when the rider cannot be called.
  final String riderPhone;
  final CourierVehicle vehicle;

  /// Who drew the road.
  final CourierRouteSource routeSource;

  /// Metres of [path] before the store: where the delivery itself begins.
  double get deliveryStartMeters => path.lengthMeters - route.lengthMeters;

  bool get canCall => riderPhone.isNotEmpty;

  /// How many of the line's last digits the customer is shown.
  static const int lineEndingDigits = 4;
  static final RegExp _notDigit = RegExp(r'\D');

  /// The last digits of [riderPhone] — enough to know the call that comes
  /// through is the rider's line, without showing the number.
  String get lineEnding {
    final digits = riderPhone.replaceAll(_notDigit, '');
    return digits.length <= lineEndingDigits
        ? digits
        : digits.substring(digits.length - lineEndingDigits);
  }

  @override
  List<Object?> get props => [
    orderId,
    route,
    approach,
    store,
    storeName,
    home,
    riderName,
    riderPhone,
    vehicle,
    routeSource,
  ];
}
