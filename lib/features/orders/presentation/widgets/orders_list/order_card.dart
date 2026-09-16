import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/order.dart';
import '../../cubit/orders_cubit.dart';
import 'cancel_order_sheet.dart';
import 'order_actions.dart';
import 'order_footer.dart';
import 'order_header.dart';
import 'order_items.dart';
import 'order_no_row.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderEntity order;

  void _openTracking(BuildContext context) =>
      Navigator.pushNamed(context, Routes.orderTracking, arguments: order.id);

  void _openReview(BuildContext context) =>
      Navigator.pushNamed(context, Routes.orderReview, arguments: order.id);

  void _openRefundDetail(BuildContext context) => Navigator.pushNamed(
    context,
    Routes.orderRefundDetail,
    arguments: order.id,
  );

  void _openImChat(BuildContext context) =>
      Navigator.pushNamed(context, Routes.imChat, arguments: order.id);

  void _openCancelSheet(BuildContext context) {
    // Capture the list cubit so the sheet (a separate route, outside this
    // subtree) can dispatch the cancel through it.
    final cubit = context.read<OrdersCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CancelOrderSheet(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bundle: df92d6 / dff3a3 — card margin-top 12dp (gap between cards),
    // radius 12dp, padding 16dp top / 10dp horizontal / 20dp bottom, white bg.
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => order.isActive
              ? _openTracking(context)
              : Navigator.pushNamed(
                  context,
                  Routes.shop,
                  arguments: order.shopId,
                ),
          child: Padding(
            // Bundle: dff3a3 — padding 16dp 10dp 20dp 10dp (top/H/bottom)
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s10,
              AppSpacing.s16,
              AppSpacing.s10,
              AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderHeader(order: order),
                const SizedBox(height: AppSpacing.s10),
                // Bundle: a7df55 divider — height 1dp, #00000014 (overlayDivider),
                // margin-left 9dp (we span full width inside the 10dp horizontal padding)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.overlayDivider,
                ),
                const SizedBox(height: AppSpacing.s8),
                OrderItems(items: order.items),
                const SizedBox(height: AppSpacing.s8),
                OrderNoRow(orderId: order.id),
                const SizedBox(height: AppSpacing.s4),
                OrderFooter(order: order),
                const SizedBox(height: AppSpacing.s12),
                OrderActions(
                  order: order,
                  onTrack: () => _openTracking(context),
                  onChat: () => _openImChat(context),
                  onCancelOrder: () => _openCancelSheet(context),
                  onReview: () => _openReview(context),
                  onReorder: () => Navigator.pushNamed(
                    context,
                    Routes.shop,
                    arguments: order.shopId,
                  ),
                  onRefundStatus: () => _openRefundDetail(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
