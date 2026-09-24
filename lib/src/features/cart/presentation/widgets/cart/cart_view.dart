import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/empty_state_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_body.dart';

/// The cart's content, shared by the Cart tab and the pushed cart page:
/// loader until the device copy is read, empty state, or the cart. Failures
/// surface as a snack bar; a customer route that answers "signed out" sends
/// the customer to login.
class CartView extends StatelessWidget {
  const CartView({super.key, required this.onBrowse, this.showHeader = false});

  /// "Start shopping" from an empty cart.
  final VoidCallback onBrowse;

  /// Adds the "n items · Clear cart" row, for a host with no app bar.
  final bool showHeader;

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
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous != current,
      listener: _onFailure,
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (previous, current) =>
            previous.isRestored != current.isRestored ||
            previous.isEmpty != current.isEmpty,
        builder: (context, state) {
          if (!state.isRestored) return const AppLoader();
          if (state.isEmpty) {
            return EmptyStateView(
              message: 'cart.empty'.tr(),
              icon: JameiaIcons.cart,
              actionLabel: 'cart.start_shopping'.tr(),
              onAction: onBrowse,
            );
          }
          return CartBody(showHeader: showHeader);
        },
      ),
    );
  }
}
