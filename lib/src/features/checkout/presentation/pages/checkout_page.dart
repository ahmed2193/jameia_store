import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/motion/confetti_overlay.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/jameia_state_view.dart';
import '../../../../core/widgets/jameia_title_bar.dart';
import '../../../address/presentation/cubit/address_book_cubit.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/checkout/checkout_body.dart';

/// What the page shows; the switch between them fades through.
enum _CheckoutBucket { loading, error, content }

/// Checkout (`Routes.checkout`): destination, timing, payment and notes over
/// the app-global cart, then `POST /v1/orders`. Placing the order empties the
/// cart, refreshes the wallet snapshot when it paid, and swaps this page for
/// the order's tracking. A signed-out answer sends the customer to login.
///
/// Placing is the flow's one celebration: a success haptic and a confetti
/// burst in the root overlay that keeps falling over the tracking page.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  /// The home confetti palette (`home_confetti.dart`).
  static const List<Color> _confetti = <Color>[
    AppColors.martGreen,
    AppColors.accent3,
    AppColors.accent4,
    AppColors.martGreenDark,
    AppColors.accent1,
  ];

  /// Near the place-order button (fractions of the screen).
  static const Offset _confettiOrigin = Offset(0.5, 0.8);
  static const int _confettiPieces = 36;

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
    Haptics.success();
    ConfettiOverlay.play(
      context,
      colors: _confetti,
      origin: _confettiOrigin,
      count: _confettiPieces,
    );
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
          backgroundColor: AppColors.white,
          appBar: JameiaTitleBar(title: 'checkout.title'.tr()),
          body: BlocBuilder<CheckoutCubit, CheckoutState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.loadFailure != current.loadFailure,
            builder: (context, state) {
              // Keyed by status bucket only: `ready` and `placed` share one
              // key, so placing never re-mounts the page (nor the notes).
              final bucket = switch (state.status) {
                CheckoutStatus.initial ||
                CheckoutStatus.loading => _CheckoutBucket.loading,
                CheckoutStatus.error => _CheckoutBucket.error,
                CheckoutStatus.ready ||
                CheckoutStatus.placed => _CheckoutBucket.content,
              };
              final failure = state.loadFailure;
              return FadeThroughSwitcher(
                stateKey: bucket,
                alignment: AlignmentDirectional.topCenter,
                child: switch (bucket) {
                  _CheckoutBucket.loading => const AppLoader(),
                  _CheckoutBucket.error
                      when failure != null && state.isSignedOut =>
                    JameiaStateView.signedOut(
                      message: 'checkout.sign_in_required'.tr(),
                    ),
                  _CheckoutBucket.error => JameiaStateView.error(
                    message: failure?.localizedMessage,
                    onRetry: () => context.read<CheckoutCubit>().retry(
                      defaultAddressId: _defaultAddressId(context),
                      expressSelected: _expressSelected(context),
                    ),
                  ),
                  _CheckoutBucket.content => const CheckoutBody(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
