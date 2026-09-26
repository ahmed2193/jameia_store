import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/jameia_state_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_body.dart';

/// What the cart page shows; the page cross-fades only when this changes.
enum _CartBucket { loading, empty, content }

/// The cart's content, shared by the Cart tab and the pushed cart page:
/// loader until the device copy is read, empty state, or the cart — swapped
/// with a fade-through. Failures surface as a snack bar; a customer route
/// that answers "signed out" sends the customer to login.
///
/// The Cart tab stays mounted (off screen) in the shell, and every "+" on
/// Home reaches it: while hidden, its animations are muted so nothing ticks.
class CartView extends StatelessWidget {
  const CartView({super.key, required this.onBrowse});

  /// "Start shopping" from an empty cart.
  final VoidCallback onBrowse;

  void _onFailure(BuildContext context, CartState state) {
    final failure = state.failure;
    if (failure == null) return;
    if (state.isSignedOut) {
      context.go(Routes.login);
      return;
    }
    showJameiaSnackBar(context, failure.localizedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: Visibility.of(context),
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
                _CartBucket.empty => JameiaStateView(
                  message: 'cart.empty'.tr(),
                  icon: Icons.shopping_cart_outlined,
                  actionLabel: 'cart.start_shopping'.tr(),
                  onAction: onBrowse,
                ),
                _CartBucket.content => const CartBody(),
              },
            );
          },
        ),
      ),
    );
  }
}
