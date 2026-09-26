import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/view_cart_pill.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// The offers page's bottom bar: the "View cart" card with the basket's
/// count, subtotal and delivery line, opening the cart on top. Nothing while the basket is
/// empty; the pill rises out of the bottom edge when the first item lands
/// and sinks back when the basket empties (at once under reduced motion).
class OffersCartBar extends StatelessWidget {
  const OffersCartBar({super.key});

  static const ValueKey<String> _pillKey = ValueKey<String>('offers-cart-pill');
  static const ValueKey<String> _emptyKey = ValueKey<String>('offers-no-cart');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.totalQty != current.totalQty ||
          previous.subtotalKd != current.subtotalKd ||
          previous.cart.deliveryQuoteFils != current.cart.deliveryQuoteFils,
      builder: (context, cart) => AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.medium),
        switchInCurve: AppMotion.emphasizedDecelerate,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: cart.totalQty > 0
            ? SafeArea(
                key: _pillKey,
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
                  child: ViewCartPill(
                    count: cart.totalQty,
                    totalKd: cart.subtotalKd,
                    deliveryKd: cart.cart.deliveryQuoteKd,
                    onTap: () => context.push(Routes.cartPreview),
                  ),
                ),
              )
            // Keeps the list off the home indicator (the frame's scaffold
            // hands its body no bottom inset while it has a bottom bar).
            : const SafeArea(
                key: _emptyKey,
                top: false,
                child: SizedBox.shrink(),
              ),
      ),
    );
  }
}
