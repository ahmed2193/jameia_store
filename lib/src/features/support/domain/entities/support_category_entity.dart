import 'package:equatable/equatable.dart';

import 'support_category.dart';

/// One topic of a support category, and what a ticket about it must carry.
class SupportTopicEntity extends Equatable {
  const SupportTopicEntity({
    required this.topic,
    this.requireOrder = false,
    this.requireProducts = false,
  });

  final SupportTopic topic;

  /// The ticket must name the order (`orderId`).
  final bool requireOrder;

  /// The ticket must name the products concerned (`productIds`).
  final bool requireProducts;

  @override
  List<Object?> get props => [topic, requireOrder, requireProducts];
}

/// One category of `GET /v1/support/categories`: its key, what a ticket in
/// it must carry, and its topics.
class SupportCategoryEntity extends Equatable {
  const SupportCategoryEntity({
    required this.category,
    this.requireOrder = false,
    this.requireProducts = false,
    this.topics = const <SupportTopicEntity>[],
  });

  final SupportCategory category;
  final bool requireOrder;
  final bool requireProducts;
  final List<SupportTopicEntity> topics;

  @override
  List<Object?> get props => [category, requireOrder, requireProducts, topics];
}
