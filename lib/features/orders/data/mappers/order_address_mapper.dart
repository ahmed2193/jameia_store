import '../../../../core/data/models/models.dart';
import '../../domain/entities/order_address.dart';

/// DTO → entity mapping for the delivery address. Lives in the data layer so the
/// core [KeetaAddress] DTO (and its schema enums) never crosses into the domain
/// [OrderAddressEntity], which carries only the raw fields the tracking / map
/// screens render.
extension OrderAddressMapper on KeetaAddress {
  OrderAddressEntity toEntity() => OrderAddressEntity(
        id: id,
        label: label,
        line: line,
        area: area,
        recipient: recipient,
        phone: phone,
        poiName: poiName,
        brief: brief,
        lat: lat,
        lng: lng,
      );
}
