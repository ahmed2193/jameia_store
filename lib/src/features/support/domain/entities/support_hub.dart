import 'package:equatable/equatable.dart';

import 'faq_item.dart';
import 'support_order.dart';

/// Help-center hub snapshot — the order-scoped help card source plus the FAQ
/// topics rendered as chevron rows.
class SupportHub extends Equatable {
  const SupportHub({required this.recentOrder, required this.faqTopics});

  /// How many FAQ topics the hub lists (the first ones of the full list).
  static const int topicCount = 6;

  /// Newest order shown in the "Get help with this order" card. Null when the
  /// user has no orders.
  final SupportOrder? recentOrder;

  /// FAQ topics rendered as a chevron list → `customer_service_question`.
  final List<FaqItem> faqTopics;

  @override
  List<Object?> get props => [recentOrder, faqTopics];
}
