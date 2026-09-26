import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import 'catalog_cart_pill.dart';

/// The bottom bar of every catalogue page: the "View cart" card
/// ([CatalogCartPill]) while the basket has items. It rises out of the bottom
/// edge when the first item goes in and sinks back when the basket empties
/// (instantly under reduced motion). Rebuilds only when the count, the
/// subtotal or the delivery quote changes.
class CatalogCartBar extends StatelessWidget {
  const CatalogCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.totalQty != current.totalQty ||
          previous.subtotalKd != current.subtotalKd ||
          previous.cart.deliveryQuoteFils != current.cart.deliveryQuoteFils,
      builder: (context, cart) => AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.slow),
        switchInCurve: AppMotion.emphasizedDecelerate,
        switchOutCurve: AppMotion.exit,
        // Rises out of the bottom edge, and sinks back into it.
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: cart.isEmpty
            ? const SizedBox.shrink()
            : CatalogCartPill(
                count: cart.totalQty,
                totalKd: cart.subtotalKd,
                deliveryKd: cart.cart.deliveryQuoteKd,
              ),
      ),
    );
  }
}
