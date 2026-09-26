import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../order_lines_sliver.dart';
import 'tracking_cancel_button.dart';
import 'tracking_cancellation_notice.dart';
import 'tracking_delivery_notice.dart';
import 'tracking_destination_card.dart';
import 'tracking_picking_notice.dart';
import 'tracking_status_header.dart';

/// The loaded order on the white page: status + journey, what changed while
/// picking, who is handling it, where it goes, what it contains (a lazy
/// sliver of rows) and the cancel action. Each optional notice keeps its
/// place and opens / folds itself (height + fade) when a poll or a cancel
/// changes it, so nothing jumps.
class TrackingBody extends StatelessWidget {
  const TrackingBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final picking = order.picking;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TrackingStatusHeader(order: order),
              TrackingCancellationNotice(cancellation: order.cancellation),
              TrackingPickingNotice(picking: picking),
              TrackingDeliveryNotice(
                delivery: order.delivery,
                pickerName: picking?.pickerName ?? '',
              ),
              TrackingDestinationCard(order: order),
            ],
          ),
        ),
        OrderLinesSliver(
          orderId: order.id,
          lines: order.lines,
          offerLines: order.offerLines,
          totalKd: order.totalKd,
        ),
        SliverToBoxAdapter(
          // The pointer follows the live state at once; the fold only draws
          // the last button while it closes.
          child: IgnorePointer(
            ignoring: !order.canCancel,
            child: CollapseReveal(
              visible: order.canCancel,
              child: TrackingCancelButton(orderId: order.id),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
    );
  }
}
