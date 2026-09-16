import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';
import 'rider_entity.dart';

/// Framework-free order entity.
///
/// Owned by the support feature (no reuse of the core `KeetaOrder` DTO, no
/// `easy_localization`). Carries the raw bilingual shop name / date so the
/// help-center recent-order card renders them directly; `isActive` / `itemCount`
/// are pure derivations kept on the entity. Only the fields the support surfaces
/// need are carried — the tracking-only dummy-backend getters stay off this
/// entity.
class KeetaOrderEntity extends Equatable {
  const KeetaOrderEntity({
    required this.id,
    required this.shopName,
    this.shopNameAr = '',
    this.shopId = '',
    required this.shopLogo,
    required this.status,
    required this.statusStep,
    required this.total,
    required this.date,
    this.dateAr = '',
    required this.items,
    required this.rider,
  });

  final String id;
  final String shopName; // English / default
  final String shopNameAr; // Arabic counterpart
  final String shopId; // catalogue shop id ('' for seed orders)
  final String shopLogo;
  final String status; // delivering | completed | preparing | cancelled
  final int statusStep; // 1..5 for the tracking stepper
  final double total;
  final String date; // English / default
  final String dateAr; // Arabic counterpart
  final List<OrderItemEntity> items;
  final RiderEntity? rider;

  bool get isActive => status == 'delivering' || status == 'preparing';

  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  @override
  List<Object?> get props => [
        id,
        shopName,
        shopNameAr,
        shopId,
        shopLogo,
        status,
        statusStep,
        total,
        date,
        dateAr,
        items,
        rider,
      ];
}
