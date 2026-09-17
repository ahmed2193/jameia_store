import '../../domain/entities/order_item_entity.dart';
import '../models/order.dart';

/// `OrderItem` DTO ⇄ [OrderItemEntity] (lossless both ways).
extension OrderItemMapper on OrderItem {
  OrderItemEntity toEntity() =>
      OrderItemEntity(name: name, nameAr: nameAr, qty: qty, price: price);
}

extension OrderItemListMapper on List<OrderItem> {
  List<OrderItemEntity> toEntities() =>
      map((i) => i.toEntity()).toList(growable: false);
}

/// Reverse map — order lines flow back into `JameiaRepository.addOrder`.
extension OrderItemEntityMapper on OrderItemEntity {
  OrderItem toModel() =>
      OrderItem(name: name, nameAr: nameAr, qty: qty, price: price);
}

extension OrderItemEntityListMapper on List<OrderItemEntity> {
  List<OrderItem> toModels() => map((i) => i.toModel()).toList(growable: false);
}
