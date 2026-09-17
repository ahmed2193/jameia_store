import '../../../../core/data/models/models.dart';
import '../../domain/entities/order.dart';

/// DTO → entity mapping for the order lifecycle. Lives in the data layer, so the
/// framework coupling of the core [JameiaOrder] DTO (its `easy_localization`-backed
/// display getters) never crosses into the domain [OrderEntity], which stays
/// plain Dart. Display resolution happens in presentation, off the raw fields
/// carried here.
extension OrderMapper on JameiaOrder {
  /// Maps the DTO to the entity. [navShopId] overrides the raw `shopId` with the
  /// data-layer-resolved navigable shop id (used for the order list so seed
  /// orders still navigate to a real shop); omit it to keep the raw value.
  OrderEntity toEntity({String? navShopId}) => OrderEntity(
    id: id,
    shopName: shopName,
    shopNameAr: shopNameAr,
    shopId: navShopId ?? shopId,
    shopLogo: shopLogo,
    status: status,
    statusStep: statusStep,
    total: total,
    date: date,
    dateAr: dateAr,
    items: items.toEntities(),
    rider: rider?.toEntity(),
  );
}

extension OrderItemMapper on OrderItem {
  OrderItemEntity toEntity() =>
      OrderItemEntity(name: name, nameAr: nameAr, qty: qty, price: price);
}

extension RiderMapper on Rider {
  RiderEntity toEntity() =>
      RiderEntity(name: name, phone: phone, vehicle: vehicle);
}

/// Convenience for mapping whole lists.
extension OrderListMapper on List<JameiaOrder> {
  List<OrderEntity> toEntities() => map((o) => o.toEntity()).toList();
}

extension OrderItemListMapper on List<OrderItem> {
  List<OrderItemEntity> toEntities() => map((i) => i.toEntity()).toList();
}
