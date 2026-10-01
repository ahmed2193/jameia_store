import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/order_entity.dart';

/// What the live map asks the feed for: the ride of [orderId], with what the
/// order already knows — the store it leaves from, the door it goes to and
/// who drives it — for a feed that cannot look them up itself.
class CourierTripRequest extends Equatable {
  const CourierTripRequest({
    required this.orderId,
    this.storeId = '',
    this.destination,
    this.riderName = '',
  });

  factory CourierTripRequest.of(OrderEntity order) => CourierTripRequest(
    orderId: order.id,
    storeId: order.branch?.id ?? '',
    destination: order.address?.location,
    riderName: order.delivery?.driverName ?? '',
  );

  final String orderId;

  /// The branch the order is delivered from; empty when it names none.
  final String storeId;

  /// The delivery address's pin; `null` when the order has none.
  final GeoPointEntity? destination;

  /// The driver the order names; empty until one is assigned.
  final String riderName;

  @override
  List<Object?> get props => [orderId, storeId, destination, riderName];
}
