import '../../../../core/data/models/models.dart';
import '../../domain/entities/jameia_order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/rider_entity.dart';

/// DTO → entity mapping for the support feature's order/rider models. Lives in
/// the data layer, so the framework coupling of the core [JameiaOrder] /
/// [OrderItem] / [Rider] DTOs (their `easy_localization`-backed display getters)
/// never crosses into the framework-free domain entities. Display resolution, if
/// needed, happens in presentation off the raw fields carried here.
extension RiderMapper on Rider {
  RiderEntity toEntity() =>
      RiderEntity(name: name, phone: phone, vehicle: vehicle);
}

extension OrderItemMapper on OrderItem {
  OrderItemEntity toEntity() =>
      OrderItemEntity(name: name, nameAr: nameAr, qty: qty, price: price);
}

extension OrderItemListMapper on List<OrderItem> {
  List<OrderItemEntity> toEntities() => map((i) => i.toEntity()).toList();
}

extension JameiaOrderMapper on JameiaOrder {
  JameiaOrderEntity toEntity() => JameiaOrderEntity(
    id: id,
    shopName: shopName,
    shopNameAr: shopNameAr,
    shopId: shopId,
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
