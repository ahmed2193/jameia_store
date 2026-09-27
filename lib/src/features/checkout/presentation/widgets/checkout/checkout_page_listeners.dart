import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/confetti_overlay.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_auto_change_listeners.dart';
import 'checkout_ui_controller.dart';

/// The checkout page's reactions to its own calls, kept apart from its
/// composition; sits under the page's providers (checkout cubit,
/// [CheckoutUiController]) and wraps the [CheckoutAutoChangeListeners].
///
/// - A new destination re-reads the cart (its fee and totals changed).
/// - Placed: the cart lets go of the order, the wallet and points are
///   re-read, a success haptic and a confetti burst (the flow's one
///   celebration), then the tracking page.
/// - A failed call is a snack, except a load failure (its own view) and a
///   401 (the sign-in prompt); a refused order re-reads the cart (and the
///   wallet it tried to pay with) and puts the savings hint away.
/// - A delivery window the new address lost is announced.
class CheckoutPageListeners extends StatelessWidget {
  const CheckoutPageListeners({super.key, required this.child});

  final Widget child;

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

  void _onSelectionChanged(BuildContext context, CheckoutState state) {
    if (state.selection != null) context.read<CartCubit>().refresh();
  }

  void _onPlaced(BuildContext context, CheckoutState state) {
    final order = state.placedOrder;
    if (order == null) return;
    context.read<CartCubit>().onOrderPlaced();
    final session = context.read<AuthSessionCubit>();
    if (session.state.isSignedIn) unawaited(session.restore());
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
    if (state.requiresSignIn) return;
    showJameiaSnackBar(context, failure.localizedMessage);
    if (state.failedAction != CheckoutAction.place) return;
    context.read<CartCubit>().refresh();
    if (state.draft.paymentMethod == OrderPaymentMethod.wallet) {
      unawaited(context.read<AuthSessionCubit>().restore());
    }
    context.read<CheckoutUiController>().hintDismissed.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
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
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) =>
              current.notice == CheckoutNotice.slotReset,
          listener: (context, _) =>
              showJameiaSnackBar(context, 'checkout.slot_reset'.tr()),
        ),
      ],
      child: CheckoutAutoChangeListeners(child: child),
    );
  }
}
