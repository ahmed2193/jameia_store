import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/app_outline_button.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/cancel_order_request.dart';
import '../../cubit/orders_cubit.dart';
import 'cancel_order_sheet.dart';

/// What the customer can do with an order from the list: cancel (while the
/// API allows), rate a delivered order, reorder any past order.
class OrderActions extends StatelessWidget {
  const OrderActions({super.key, required this.order});

  final OrderEntity order;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<OrdersCubit>();
    final request = await showJameiaBottomSheet<CancelOrderRequest>(
      context,
      isScrollControlled: true,
      builder: (_) => CancelOrderSheet(orderId: order.id),
    );
    if (request != null) await cubit.cancel(request);
  }

  Future<void> _reorder(BuildContext context) async {
    final added = await context.read<CartCubit>().addItems(order.reorderItems);
    if (added && context.mounted) {
      showJameiaSnackBar(context, 'orders.reorder_done'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelling = context.select<OrdersCubit, bool>(
      (cubit) => cubit.state.isCancelling(order.id),
    );
    final reordering = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.addItems,
    );
    final buttons = <Widget>[
      if (order.canCancel)
        AppOutlineButton(
          label: 'orders.cancel_order'.tr(),
          onPressed: cancelling ? null : () => _cancel(context),
        ),
      if (order.canReview)
        AppOutlineButton(
          label: 'orders.review'.tr(),
          onPressed: () => context.push(Routes.orderReview, extra: order.id),
        ),
      if (order.isTerminal)
        AppOutlineButton(
          label: 'orders.reorder'.tr(),
          onPressed: reordering ? null : () => _reorder(context),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}
