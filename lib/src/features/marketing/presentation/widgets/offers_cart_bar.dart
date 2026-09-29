import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/collapse_reveal.dart';
import '../../../../core/widgets/view_cart_pill.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// The offers page's bottom bar: the "View cart" card with the basket's
/// count, subtotal and delivery line, opening the cart on top. Nothing while
/// the basket is empty; the pill rises out of the bottom edge when the first
/// item lands and sinks back when the basket empties — [CollapseReveal], the
/// one bottom-bar timing (in medium, out fast; at once under reduced motion).
class OffersCartBar extends StatelessWidget {
  const OffersCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Keeps the list off the home indicator either way (the frame's scaffold
    // hands its body no bottom inset while it has a bottom bar).
    return SafeArea(
      top: false,
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (previous, current) =>
            previous.totalQty != current.totalQty ||
            previous.subtotalKd != current.subtotalKd ||
            previous.cart.deliveryQuoteFils != current.cart.deliveryQuoteFils,
        builder: (context, cart) => CollapseReveal(
          visible: cart.totalQty > 0,
          alignment: AlignmentDirectional.topCenter,
          child: cart.totalQty > 0
              ? Padding(
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
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
