import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import 'tracking_cancel_button.dart';
import 'tracking_cancellation_notice.dart';
import 'tracking_delivery_notice.dart';
import 'tracking_destination_card.dart';
import '../order_lines_card.dart';
import 'tracking_picking_notice.dart';
import 'tracking_status_header.dart';

/// The loaded order: status + progress, what changed while picking, who is
/// handling it, where it goes, what it contains, and the cancel action.
class TrackingBody extends StatelessWidget {
  const TrackingBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final picking = order.picking;
    final cancellation = order.cancellation;
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      children: [
        TrackingStatusHeader(order: order),
        if (cancellation != null) ...[
          const SizedBox(height: AppSpacing.s8),
          TrackingCancellationNotice(cancellation: cancellation),
        ],
        if (picking != null && picking.hasChanges) ...[
          const SizedBox(height: AppSpacing.s8),
          TrackingPickingNotice(picking: picking),
        ],
        const SizedBox(height: AppSpacing.s8),
        TrackingDeliveryNotice(
          delivery: order.delivery,
          pickerName: picking?.pickerName ?? '',
        ),
        const SizedBox(height: AppSpacing.s8),
        TrackingDestinationCard(order: order),
        const SizedBox(height: AppSpacing.s8),
        OrderLinesCard(order: order),
        if (order.canCancel) ...[
          const SizedBox(height: AppSpacing.s16),
          TrackingCancelButton(orderId: order.id),
        ],
      ],
    );
  }
}
