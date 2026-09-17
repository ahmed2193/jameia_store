import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/order.dart';
import 'order_card.dart';

class OrdersList extends StatelessWidget {
  const OrdersList({
    super.key,
    required this.orders,
    required this.emptyMessage,
  });

  final List<OrderEntity> orders;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyStateView(message: emptyMessage, icon: JameiaIcons.orders);
    }
    return ContentClamp(
      child: ListView.builder(
        // Bundle: f99e48 padding 0dp 12dp (H inset 12dp each side); first card
        // gets 12dp top via its own margin-top. Bottom = 16dp safe-area pad.
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.s12,
          end: AppSpacing.s12,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
        ),
        itemCount: orders.length,
        itemBuilder: (_, i) => StaggerEntrance(
          index: i,
          child: OrderCard(order: orders[i]),
        ),
      ),
    );
  }
}
