import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/order_status.dart';

/// One of the customer's orders as an `order` / `order_status` block shows
/// it. [id] opens tracking (`Routes.orderTracking`), never [orderNumber].
class AssistantOrderSummary extends Equatable {
  const AssistantOrderSummary({
    required this.id,
    this.orderNumber = '',
    this.status = OrderStatus.other,
    this.totalFils = 0,
    this.createdAt,
    this.itemCount = 0,
    this.thumbnails = const <String>[],
  });

  /// The card shows at most this many thumbnails.
  static const int maxThumbnails = 4;

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int totalFils;
  final DateTime? createdAt;
  final int itemCount;
  final List<String> thumbnails;

  double get totalKd => totalFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    totalFils,
    createdAt,
    itemCount,
    thumbnails,
  ];
}
