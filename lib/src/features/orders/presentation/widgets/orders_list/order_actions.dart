import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../cubit/orders_cubit.dart';
import 'cancel_order_sheet.dart';

/// What the customer can do with an order from the list: cancel (while the
/// API allows), rate a delivered order, reorder any past order — compact
/// white pills side by side. The row owns its top gap, so an order with no
/// action leaves no empty space at the foot of its card.
class OrderActions extends StatelessWidget {
  const OrderActions({super.key, required this.order});

  final OrderEntity order;

  /// The card-action size of a compact secondary pill.
  static const double _actionHeight = AppSize.s44;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<OrdersCubit>();
    final request = await CancelOrderSheet.show(context, orderId: order.id);
    if (request != null) await cubit.cancel(request);
  }

  /// The order page's flow: every paid line back in the cart in one
  /// request, then the add-to-cart gesture of every product surface (the
  /// click, the first line's photo flying from the pill to the cart on
  /// screen), then the cart opens to check it before checking out — after
  /// the landing, so the sheet never covers the flight. A failure is told
  /// the cart's way (offline: the connection banner).
  Future<void> _reorder(BuildContext context) async {
    final cart = context.read<CartCubit>();
    final added = await cart.addItems(order.reorderItems);
    if (!context.mounted) return;
    if (added) {
      await CatalogCartGestures.added(context, image: order.reorderImage);
      if (!context.mounted) return;
      await context.push(Routes.cartPreview);
      return;
    }
    final failure = cart.state.failure;
    if (failure != null) showFailureSnackBar(context, failure, action: true);
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
        HeroSecondaryButton(
          label: 'orders.cancel_order'.tr(),
          compact: true,
          height: _actionHeight,
          onPressed: cancelling ? null : () => _cancel(context),
        ),
      if (order.canReview)
        HeroSecondaryButton(
          label: 'orders.review'.tr(),
          compact: true,
          height: _actionHeight,
          onPressed: () => context.push(Routes.orderReview, extra: order.id),
        ),
      if (order.isTerminal)
        // Its own context: the flight leaves from the pill, not the row.
        Builder(
          builder: (context) => HeroSecondaryButton(
            label: 'orders.reorder'.tr(),
            compact: true,
            height: _actionHeight,
            onPressed: reordering ? null : () => _reorder(context),
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s16),
      child: Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s8),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }
}
