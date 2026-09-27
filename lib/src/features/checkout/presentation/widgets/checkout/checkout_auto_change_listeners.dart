import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_entity.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../auth/presentation/cubit/auth_session_state.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/checkout_coupon_drop.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../../domain/entities/checkout_payment_choice.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_ui_controller.dart';

/// What the checkout changes on the customer's behalf when the cart, the
/// store rules or the wallet move — and says so:
///
/// - A wallet that no longer covers the total falls back to cash on
///   delivery (announced, the payment rows bump); a store that takes no
///   cash (or prefers the wallet) moves a covering wallet in.
/// - A coupon the server dropped and an express option the new destination
///   lost are announced. What the customer did themselves
///   (`CartState.changedBy`) is not news, and a pickup order drops express
///   without a word (it has no delivery time to change).
///
/// Every `listenWhen` is a pure predicate; the one reaction that needs the
/// cart before the change (the dropped coupon's code) remembers it here.
class CheckoutAutoChangeListeners extends StatefulWidget {
  const CheckoutAutoChangeListeners({super.key, required this.child});

  final Widget child;

  @override
  State<CheckoutAutoChangeListeners> createState() =>
      _CheckoutAutoChangeListenersState();
}

class _CheckoutAutoChangeListenersState
    extends State<CheckoutAutoChangeListeners> {
  /// The cart the next cart change starts from.
  late CartEntity _cart;

  @override
  void initState() {
    super.initState();
    _cart = context.read<CartCubit>().state.cart;
  }

  bool _placed(BuildContext context) =>
      context.read<CheckoutCubit>().state.status == CheckoutStatus.placed;

  int? _walletFils(BuildContext context) =>
      context.read<AuthSessionCubit>().state.customer?.walletFils;

  /// The wallet pays for the whole order or not at all (`paymentMethod`
  /// takes one method), so a total that grew past the balance — express
  /// switched on, a re-price after a new destination — takes the choice
  /// back.
  void _onTotalChanged(BuildContext context, CartState cart) {
    if (_placed(context)) return;
    final checkout = context.read<CheckoutCubit>();
    final next = CheckoutPaymentChoice.onTotal(
      rules: checkout.state.rules,
      current: checkout.state.draft.paymentMethod,
      cart: cart.checkoutFacts(walletFils: _walletFils(context)),
    );
    if (next == null) return;
    checkout.setPaymentMethod(next);
    showHeroSnackBar(context, 'checkout.wallet_reverted'.tr());
    context.read<CheckoutUiController>().bumpPayment();
  }

  /// The store rules arrived or the wallet changed: a store that takes no
  /// cash, or prefers the wallet, pays with a wallet that covers the order.
  void _applyPaymentRules(BuildContext context) {
    final checkout = context.read<CheckoutCubit>();
    if (checkout.state.status != CheckoutStatus.ready) return;
    final next = CheckoutPaymentChoice.onRules(
      rules: checkout.state.rules,
      current: checkout.state.draft.paymentMethod,
      cart: context.read<CartCubit>().state.checkoutFacts(
        walletFils: _walletFils(context),
      ),
    );
    if (next != null) checkout.setPaymentMethod(next);
  }

  /// A coupon the last cart change dropped, unless the change was the
  /// customer's own coupon action (removed on "Coupons & offers").
  void _onCartChanged(BuildContext context, CartState state) {
    final before = _cart;
    _cart = state.cart;
    if (state.changedBy == CartAction.coupon || _placed(context)) return;
    final code = CheckoutCouponDrop.droppedCode(before, state.cart);
    if (code == null) return;
    showHeroSnackBar(
      context,
      'checkout.coupon_dropped'.tr(namedArgs: {'code': code}),
    );
  }

  /// The server let go of express on its own: the draft follows back to
  /// "as soon as possible". Said for a delivery (the new address has no
  /// express); silent for pickup, which has no delivery time to change.
  void _onExpressDropped(BuildContext context, CartState _) {
    if (_placed(context)) return;
    final checkout = context.read<CheckoutCubit>();
    final draft = checkout.state.draft;
    if (draft.timing != DeliveryTiming.express) return;
    checkout.setTiming(DeliveryTiming.asap);
    if (draft.isPickup) return;
    showHeroSnackBar(context, 'checkout.express_reset'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              previous.rules != current.rules ||
              previous.status != current.status,
          listener: (context, _) => _applyPaymentRules(context),
        ),
        BlocListener<AuthSessionCubit, AuthSessionState>(
          listenWhen: (previous, current) =>
              previous.customer?.walletFils != current.customer?.walletFils,
          listener: (context, _) => _applyPaymentRules(context),
        ),
        BlocListener<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              previous.cart.totals.totalFils != current.cart.totals.totalFils,
          listener: _onTotalChanged,
        ),
        BlocListener<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              !identical(previous.cart, current.cart),
          listener: _onCartChanged,
        ),
        BlocListener<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              previous.cart.expressSelected &&
              !current.cart.expressSelected &&
              current.changedBy != CartAction.express,
          listener: _onExpressDropped,
        ),
      ],
      child: widget.child,
    );
  }
}
