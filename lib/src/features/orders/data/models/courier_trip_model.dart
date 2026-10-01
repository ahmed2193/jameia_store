import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'courier_point_model.dart';

/// The rider feed's ride:
/// `{ orderId, rider: { name, vehicle, phone }, approach: [{ lat, lng }],
/// route: [{ lat, lng }], store: { lat, lng }, storeName, home: { lat, lng },
/// routeSource }` — the road from the store to the door point by point, the
/// rider's way to the store (empty when they start there), the store's and
/// the door's own pins, and who drew the road. A malformed point is
/// skipped; a ride without an order or a road of two points is no ride.
class CourierTripModel {
  const CourierTripModel({
    required this.orderId,
    required this.route,
    this.approach = const <CourierPointModel>[],
    this.store,
    this.storeName = '',
    this.home,
    this.riderName = '',
    this.riderPhone = '',
    this.vehicle = '',
    this.routeSource = '',
  });

  factory CourierTripModel.fromJson(Map<String, dynamic> json) {
    final orderId = JsonRead.string(json[orderIdKey]);
    final route = _road(json[routeKey]);
    if (orderId == null || route.length < minRoutePoints) {
      throw const ParsingException('courier trip without an order or a road');
    }
    final rider = JsonRead.object(json[riderKey]);
    return CourierTripModel(
      orderId: orderId,
      route: route,
      approach: _road(json[approachKey]),
      store: _point(json[storeKey]),
      storeName: JsonRead.string(json[storeNameKey]) ?? '',
      home: _point(json[homeKey]),
      riderName: rider == null ? '' : JsonRead.string(rider[nameKey]) ?? '',
      riderPhone: rider == null ? '' : JsonRead.string(rider[phoneKey]) ?? '',
      vehicle: rider == null ? '' : JsonRead.string(rider[vehicleKey]) ?? '',
      routeSource: JsonRead.string(json[routeSourceKey]) ?? '',
    );
  }

  static List<CourierPointModel> _road(Object? value) =>
      JsonRead.rows(value, CourierPointModel.fromJson, logName: _logName);

  static CourierPointModel? _point(Object? value) {
    final json = JsonRead.object(value);
    if (json == null) return null;
    try {
      return CourierPointModel.fromJson(json);
    } on ParsingException {
      return null;
    }
  }

  static const String orderIdKey = 'orderId';
  static const String routeKey = 'route';
  static const String approachKey = 'approach';
  static const String storeKey = 'store';
  static const String storeNameKey = 'storeName';
  static const String homeKey = 'home';
  static const String routeSourceKey = 'routeSource';
  static const String riderKey = 'rider';
  static const String nameKey = 'name';
  static const String phoneKey = 'phone';
  static const String vehicleKey = 'vehicle';

  static const String motorbikeVehicle = 'motorbike';
  static const String carVehicle = 'car';
  static const String bicycleVehicle = 'bicycle';

  /// `routeSource`: Google's roads, OpenStreetMap roads, or estimated streets.
  static const String googleSource = 'google';
  static const String osmSource = 'osm';
  static const String estimatedSource = 'estimated';

  static const int minRoutePoints = 2;
  static const String _logName = 'CourierTripModel';

  final String orderId;

  /// Store → door.
  final List<CourierPointModel> route;

  /// The rider's way to the store; fewer than two points = none.
  final List<CourierPointModel> approach;

  /// The store's and the door's pins; `null` = the road's ends.
  final CourierPointModel? store;
  final CourierPointModel? home;

  /// The store's name; empty when the feed does not name it.
  final String storeName;
  final String riderName;

  /// A line that reaches the rider; empty when they cannot be called.
  final String riderPhone;

  /// `motorbike`, `car`, `bicycle` (anything else is kept as sent).
  final String vehicle;

  /// `google`, `osm`, `estimated` (anything else reads as estimated).
  final String routeSource;
}
