import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/deferred_value.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/hero_section_header.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/order_line_changes.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../invoice/invoice_totals.dart';
import '../order_lines_sliver.dart';
import 'tracking_cancel_button.dart';
import 'tracking_cancellation_notice.dart';
import 'tracking_delivery_details.dart';
import 'tracking_help_row.dart';
import 'tracking_order_info.dart';
import 'tracking_payment_row.dart';
import 'tracking_people_card.dart';
import 'tracking_picking_notice.dart';
import 'tracking_rate_card.dart';
import 'tracking_status_hero.dart';
import 'tracking_store_row.dart';

/// The order page, top to bottom, the way delivery apps lay it out: the
/// status panel (time, stage, bar), what changed (cancelled, picking
/// changes), who handles it, the rating card once delivered, the delivery
/// details, the order summary (items with photos folded to three, the bill,
/// how it is paid), the order info (number, invoice, history), help, and
/// cancel while the API still allows it. Pull down to check the order now.
///
/// A change moves in order (backlog B2-03): the panel answers first, the
/// cancellation notice and the rating card open a beat later, the cancel
/// button folds last. Each optional block keeps its place and opens / folds
/// itself, so nothing jumps.
class TrackingBody extends StatelessWidget {
  const TrackingBody({super.key, required this.order, required this.onHelp});

  final OrderEntity order;
  final VoidCallback onHelp;

  /// Rows shown before "Show N more".
  static const int _foldedItems = 3;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderTrackingCubit>();
    return BrandedRefresh(
      onRefresh: cubit.refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TrackingStatusHero(order: order),
                DeferredValue<OrderCancellationEntity?>(
                  value: order.cancellation,
                  delay: AppMotion.page,
                  builder: (context, cancellation) =>
                      TrackingCancellationNotice(cancellation: cancellation),
                ),
                TrackingPickingNotice(picking: order.picking),
                TrackingPeopleCard(order: order),
                DeferredValue<bool>(
                  value: order.canReview,
                  delay: AppMotion.page,
                  builder: (context, canReview) => CollapseReveal(
                    visible: canReview,
                    child: TrackingRateCard(orderId: order.id),
                  ),
                ),
                TrackingDeliveryDetails(order: order),
                HeroSectionHeader(
                  title: 'orders.summary_items_title'.tr(),
                  titleStyle: AppTextStyles.groupTitle,
                ),
              ],
            ),
          ),
          OrderLinesSliver(
            orderId: order.id,
            lines: order.lines,
            offerLines: order.offerLines,
            totalKd: order.totalKd,
            changes: OrderLineChanges.of(order.picking),
            card: true,
            leading: TrackingStoreRow(order: order),
            leadingKey: order.branch,
            collapsedCount: _foldedItems,
            showThumbs: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                InvoiceTotals(
                  order: order,
                  trailing: [
                    const Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.s8,
                      ),
                      child: ThinDivider(),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.s6,
                      ),
                      child: TrackingPaymentRow(
                        payment: order.payment,
                        cancelled: order.status == OrderStatus.cancelled,
                      ),
                    ),
                  ],
                ),
                TrackingOrderInfo(order: order),
                TrackingHelpRow(onPressed: onHelp),
                // The pointer follows the live state at once; the fold waits
                // its turn, after the panel and the notice.
                IgnorePointer(
                  ignoring: !order.canCancel,
                  child: DeferredValue<bool>(
                    value: order.canCancel,
                    delay: AppMotion.slow,
                    builder: (context, canCancel) => CollapseReveal(
                      visible: canCancel,
                      child: TrackingCancelButton(orderId: order.id),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
