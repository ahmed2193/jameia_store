import 'package:flutter/widgets.dart';

import '../../../../../core/domain/entities/auth_customer_entity.dart';
import 'mine_header.dart';
import 'mine_header_metrics.dart';

/// Pinned, collapsing profile header of the Mine tab: open at the top of the
/// page, a slim bar with the docked avatar once the menu scrolls under it.
/// The collapse follows the finger, so it stays under reduced motion too.
class MineHeaderDelegate extends SliverPersistentHeaderDelegate {
  MineHeaderDelegate({required this.customer, required this.metrics});

  /// The signed-in customer; `null` for a guest.
  final AuthCustomerEntity? customer;
  final MineHeaderMetrics metrics;

  @override
  double get minExtent => metrics.minExtent;

  @override
  double get maxExtent => metrics.maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => MineHeader(
    customer: customer,
    metrics: metrics,
    shrinkOffset: shrinkOffset,
  );

  @override
  bool shouldRebuild(MineHeaderDelegate oldDelegate) =>
      oldDelegate.customer != customer || oldDelegate.metrics != metrics;
}
