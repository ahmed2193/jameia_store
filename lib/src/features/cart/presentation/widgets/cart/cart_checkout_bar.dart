import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_entity.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/motion/blocked_tap_shake.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cart_bar_summary.dart';
import '../../../../../core/widgets/jameia_bottom_bar.dart';
import '../../../../../core/widgets/sticker_button.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_block_reason.dart';

/// Pinned footer: the green basket with the item count, the total (struck
/// beside it: what it was before the discounts), the delivery line ("Free
/// delivery" / "KD 0.650 delivery"), and the big green "Checkout" block.
/// Disabled with the reason while the server says the cart cannot be
/// ordered (minimum order, closed branch, no capacity, unavailable lines) or
/// while taps are still on their way; pending taps are flushed before the
/// checkout opens. A tap on the button while a reason is shown shakes it.
/// The total rolls from the old amount to the new one when the server's
/// reply lands.
///
/// [inSheet]: the copy at the foot of the "Buy more, save more" sheet —
/// products added there fly into its basket, and "Checkout" closes the
/// sheet before the checkout opens.
class CartCheckoutBar extends StatefulWidget {
  const CartCheckoutBar({super.key, this.inSheet = false});

  final bool inSheet;

  @override
  State<CartCheckoutBar> createState() => _CartCheckoutBarState();
}

class _CartCheckoutBarState extends State<CartCheckoutBar> {
  final GlobalKey _basket = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.inSheet) FlyToCart.pushTarget(_basket);
  }

  @override
  void dispose() {
    if (widget.inSheet) FlyToCart.popTarget(_basket);
    super.dispose();
  }

  Future<void> _checkout(BuildContext context) async {
    final router = GoRouter.of(context);
    final synced = await context.read<CartCubit>().prepareCheckout();
    if (!synced || !context.mounted) return;
    if (widget.inSheet) context.pop();
    await router.push(Routes.checkout);
  }

  String? _reason(CartState state) {
    if (state.isUnsynced) return 'cart.block_offline'.tr();
    return switch (state.cart.checkoutBlock) {
      null || CartCheckoutBlock.empty => null,
      CartCheckoutBlock.lineIssue => 'cart.block_line_issue'.tr(),
      CartCheckoutBlock.belowMinOrder => 'cart.block_min_order'.tr(
        namedArgs: {'amount': Formatters.price(state.cart.totals.shortfallKd)},
      ),
      CartCheckoutBlock.branchClosed => 'cart.block_branch_closed'.tr(),
      CartCheckoutBlock.noCapacity => 'cart.block_no_capacity'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.cart.totals != current.cart.totals ||
          previous.cart.checkoutBlock != current.cart.checkoutBlock ||
          previous.totalQty != current.totalQty ||
          previous.cart.deliveryQuoteFils != current.cart.deliveryQuoteFils ||
          previous.isUpdating != current.isUpdating ||
          previous.isUnsynced != current.isUnsynced ||
          previous.busyAction != current.busyAction,
      builder: (context, state) {
        final reason = _reason(state);
        final busy = state.busyAction == CartAction.sync;
        final totals = state.cart.totals;
        return JameiaBottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CollapseReveal(
                visible: reason != null,
                child: reason == null
                    ? const SizedBox.shrink()
                    : CartBlockReason(text: reason),
              ),
              Row(
                children: [
                  // The last total the server priced is stale while taps
                  // are still on their way, and this bar is what the
                  // customer reads before paying — so it says "updating"
                  // exactly like the summary above it instead of naming
                  // an amount the order will not have. The amount stays
                  // mounted underneath, so the new one rolls in.
                  Expanded(
                    flex: 3,
                    child: CartBarSummary(
                      count: state.totalQty,
                      amountKd: state.isUpdating ? null : totals.totalKd,
                      struckKd: CartSavings.of(state.cart).struckTotalKd,
                      deliveryKd: state.cart.deliveryQuoteKd,
                      placeholder: 'cart.updating'.tr(),
                      targetKey: widget.inSheet ? _basket : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    flex: 2,
                    child: BlockedTapShake(
                      blocked: reason != null && !busy,
                      child: StickerButton(
                        label: 'cart.checkout'.tr(),
                        loading: busy,
                        enabled: reason == null && !state.isUpdating && !busy,
                        onPressed: () => _checkout(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
