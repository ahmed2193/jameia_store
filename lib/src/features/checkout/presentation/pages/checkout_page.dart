import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/signed_out_view.dart';
import '../../../address/presentation/cubit/address_book_cubit.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/checkout/checkout_body.dart';

/// Checkout (`Routes.checkout`): destination, timing, payment and notes over
/// the app-global cart, then `POST /v1/orders`. Placing the order empties the
/// cart, refreshes the wallet snapshot when it paid, and swaps this page for
/// the order's tracking. A signed-out answer sends the customer to login.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  String? _defaultAddressId(BuildContext context) =>
      context.read<AddressBookCubit>().state.book.defaultAddress?.id;

  /// The cart owns the express flag on the server, so the draft has to open
  /// on whatever the cart already selected.
  bool _expressSelected(BuildContext context) =>
      context.read<CartCubit>().state.cart.expressSelected;

  void _onSelectionChanged(BuildContext context, CheckoutState state) {
    if (state.selection != null) context.read<CartCubit>().refresh();
  }

  /// The wallet pays for the whole order or not at all (`paymentMethod` takes
  /// one method), so a total that grew past the balance — express switched on,
  /// a re-price after a new destination — has to take the choice back.
  void _onTotalChanged(BuildContext context, CartState state) {
    final checkout = context.read<CheckoutCubit>();
    if (checkout.state.draft.paymentMethod != OrderPaymentMethod.wallet) return;
    final balance = context.read<AuthSessionCubit>().state.customer?.walletFils;
    if (balance != null && balance >= state.cart.totals.totalFils) return;
    checkout.setPaymentMethod(OrderPaymentMethod.cod);
  }

  void _onPlaced(BuildContext context, CheckoutState state) {
    final order = state.placedOrder;
    if (order == null) return;
    context.read<CartCubit>().onOrderPlaced();
    if (order.payment.method == OrderPaymentMethod.wallet) {
      context.read<AuthSessionCubit>().restore();
    }
    context.pushReplacement(Routes.orderTracking, extra: order.id);
  }

  void _onFailure(BuildContext context, CheckoutState state) {
    final failure = state.failure;
    if (failure == null || state.loadFailure != null) return;
    if (state.isSignedOut) {
      context.go(Routes.login);
      return;
    }
    showJameiaSnackBar(context, failure.localizedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CheckoutCubit>()
        ..start(
          defaultAddressId: _defaultAddressId(context),
          expressSelected: _expressSelected(context),
        ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<CheckoutCubit, CheckoutState>(
            listenWhen: (previous, current) =>
                previous.selection != current.selection,
            listener: _onSelectionChanged,
          ),
          BlocListener<CheckoutCubit, CheckoutState>(
            listenWhen: (previous, current) =>
                previous.status != CheckoutStatus.placed &&
                current.status == CheckoutStatus.placed,
            listener: _onPlaced,
          ),
          BlocListener<CheckoutCubit, CheckoutState>(
            listenWhen: (previous, current) =>
                current.failure != null && previous != current,
            listener: _onFailure,
          ),
          BlocListener<CartCubit, CartState>(
            listenWhen: (previous, current) =>
                previous.cart.totals.totalFils != current.cart.totals.totalFils,
            listener: _onTotalChanged,
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.mediumBackground,
          appBar: AppBar(
            title: Text('checkout.title'.tr()),
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
          ),
          body: BlocBuilder<CheckoutCubit, CheckoutState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.loadFailure != current.loadFailure,
            builder: (context, state) {
              switch (state.status) {
                case CheckoutStatus.initial:
                case CheckoutStatus.loading:
                  return const AppLoader();
                case CheckoutStatus.error:
                  final failure = state.loadFailure;
                  if (failure != null && state.isSignedOut) {
                    return SignedOutView(
                      message: 'checkout.sign_in_required'.tr(),
                    );
                  }
                  return ErrorView(
                    message: failure?.localizedMessage,
                    onRetry: () => context.read<CheckoutCubit>().retry(
                      defaultAddressId: _defaultAddressId(context),
                      expressSelected: _expressSelected(context),
                    ),
                  );
                case CheckoutStatus.ready:
                case CheckoutStatus.placed:
                  return const CheckoutBody();
              }
            },
          ),
        ),
      ),
    );
  }
}
