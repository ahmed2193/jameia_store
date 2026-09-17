import '../../domain/entities/jameia_order_entity.dart';
import '../models/order.dart';
import 'order_item_mapper.dart';
import 'rider_mapper.dart';

/// `JameiaOrder` DTO ⇄ [JameiaOrderEntity] (lossless both ways).
extension JameiaOrderMapper on JameiaOrder {
  /// Maps the DTO to the entity. [shopIdOverride] replaces the raw `shopId`
  /// with a data-layer-resolved navigable shop id (the orders list resolves a
  /// real shop for seed orders); omit it to keep the raw value.
  JameiaOrderEntity toEntity({String? shopIdOverride}) => JameiaOrderEntity(
    id: id,
    shopName: shopName,
    shopNameAr: shopNameAr,
    shopId: shopIdOverride ?? shopId,
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

extension JameiaOrderListMapper on List<JameiaOrder> {
  List<JameiaOrderEntity> toEntities() =>
      map((o) => o.toEntity()).toList(growable: false);
}

/// Reverse map — a freshly-built order flows into `JameiaRepository.addOrder`
/// (persisted to local storage via `JameiaOrder.toJson`).
extension JameiaOrderEntityMapper on JameiaOrderEntity {
  JameiaOrder toModel() => JameiaOrder(
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
    items: items.toModels(),
    rider: rider?.toModel(),
  );
}
