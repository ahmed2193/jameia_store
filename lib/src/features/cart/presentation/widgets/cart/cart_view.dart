import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes/route_args/shell_tabs.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/navigation/sign_in_flow.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../../core/widgets/hero_state_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_body.dart';

/// What the cart page shows; the page cross-fades only when this changes.
enum _CartBucket { loading, empty, content }

/// The cart's content, shared by the Cart tab and the pushed cart page:
/// loader until the device copy is read, empty state, or the cart — swapped
/// with a fade-through. Failures surface as a snack bar — except the cart's
/// own sync failing offline, which the banner and the "not synced" line
/// already tell — and a customer route that answers "signed out" sends the
/// customer to login.
///
/// The Cart tab stays mounted (off screen) in the shell, and every "+" on
/// Home reaches it: while hidden, its animations are muted so nothing ticks.
/// A confirmed "Clear cart" holds the screen until the server answers.
class CartView extends StatelessWidget {
  const CartView({super.key, required this.onBrowse});

  /// "Start shopping" from an empty cart.
  final VoidCallback onBrowse;

  void _onFailure(BuildContext context, CartState state) {
    final failure = state.failure;
    if (failure == null) return;
    if (state.isSignedOut) {
      SignInFlow.open(context, tab: ShellTab.cart);
      return;
    }
    final background =
        state.failedAction == CartAction.sync ||
        state.failedAction == CartAction.none;
    final transport = failure.isTransport;
    // The cart's own sync (taps going out, a re-read) could not reach the
    // server: offline it retries by itself and says nothing more.
    if (background && transport && ConnectivityScope.readIsOffline(context)) {
      return;
    }
    // Coupon, points, express, clear, reorder are the customer's actions; a
    // sync or a refresh is a read.
    showFailureSnackBar(
      context,
      failure,
      action: !background && state.failedAction != CartAction.fetch,
    );
  }

  static bool _clearing(CartState state) =>
      state.busyAction == CartAction.clear;

  static bool _clearFailed(CartState state) =>
      state.failedAction == CartAction.clear && state.failure != null;

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: Visibility.of(context),
      child: CubitBusyOverlay<CartCubit, CartState>(
        busyOf: _clearing,
        failOf: _clearFailed,
        child: BlocListener<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              current.failure != null && previous != current,
          listener: _onFailure,
          child: BlocBuilder<CartCubit, CartState>(
            buildWhen: (previous, current) =>
                previous.isRestored != current.isRestored ||
                previous.isEmpty != current.isEmpty,
            builder: (context, state) {
              final bucket = !state.isRestored
                  ? _CartBucket.loading
                  : state.isEmpty
                  ? _CartBucket.empty
                  : _CartBucket.content;
              return FadeThroughSwitcher(
                stateKey: bucket,
                alignment: AlignmentDirectional.topCenter,
                child: switch (bucket) {
                  _CartBucket.loading => const AppLoader(),
                  _CartBucket.empty => HeroStateView(
                    message: 'cart.empty'.tr(),
                    art: HeroAssets.emptyBasket,
                    actionLabel: 'cart.start_shopping'.tr(),
                    onAction: onBrowse,
                  ),
                  _CartBucket.content => const CartBody(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
