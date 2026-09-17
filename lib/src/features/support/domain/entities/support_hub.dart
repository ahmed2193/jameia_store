import 'package:equatable/equatable.dart';

import 'jameia_order_entity.dart';

/// Help-center hub snapshot — the order-scoped help card source plus the
/// scripted FAQ topic list rendered as chevron rows.
class SupportHub extends Equatable {
  const SupportHub({required this.recentOrder, required this.faqTopics});

  /// Newest order shown in the "Get help with this order" card. Null when the
  /// user has no orders.
  final JameiaOrderEntity? recentOrder;

  /// FAQ topics rendered as a chevron list → `customer_service_question`.
  final List<String> faqTopics;

  @override
  List<Object?> get props => [recentOrder, faqTopics];
}
