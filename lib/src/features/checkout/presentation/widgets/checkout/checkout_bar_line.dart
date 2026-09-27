import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/domain/entities/offer_entity.dart';
import '../../../../../core/motion/rotating_line.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_bar_facts.dart';
import '../../../domain/entities/checkout_offer_hints.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_offers_cubit.dart';
import 'checkout_bar_fact_text.dart';

/// The line under the bar's total ([CheckoutBarFacts]). A fact that must
/// not move — the price is not quoted yet, or a reason the order cannot go —
/// stays put, alone. Otherwise the true positive facts (savings, the
/// coupon's and the points' saving, free delivery, the gap to it) take turns
/// on a [RotatingLine], frozen while the cart re-prices or a sheet is on
/// top (the fact on screen stays, even one hidden for the re-price, and no
/// swap plays). The bar reads every fact once.
///
/// Rebuilds only when the facts change: the rotation itself is the
/// [RotatingLine]'s own state.
class CheckoutBarLine extends StatelessWidget {
  const CheckoutBarLine({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutCubit>();
    // What the facts read from the checkout besides the cart, so a note
    // being saved does not wake the line.
    context.select<CheckoutCubit, Object>(
      (cubit) => (
        cubit.state.blockInputs,
        cubit.state.draft.isPickup,
        cubit.state.selection?.branchId,
        cubit.state.selection?.deliveryFeeFils,
      ),
    );
    final offers = context.select<CheckoutOffersCubit, List<OfferEntity>>(
      (cubit) => cubit.state.offers,
    );
    final (walletFils, isPro) = context.select<AuthSessionCubit, (int?, bool)>(
      (cubit) => (
        cubit.state.customer?.walletFils,
        cubit.state.customer?.isPro ?? false,
      ),
    );
    final (
      facts,
      updating,
    ) = context.select<CartCubit, (CheckoutBarFacts, bool)>((cubit) {
      final cart = cubit.state;
      final state = checkout.state;
      final selection = state.selection;
      return (
        CheckoutBarFacts.of(
          cart: cart.cart,
          savings: CartSavings.of(
            cart.cart,
            quotedDeliveryFeeFils: selection?.deliveryFeeFils,
          ),
          hints: CheckoutOfferHints.of(
            cart: cart.cart,
            offers: offers,
            branchId: selection?.branchId,
            pickup: state.draft.isPickup,
            proFreeDelivery: state.rules.proFreeDelivery && isPro,
          ),
          quoted: state.hasSelection,
          updating: cart.isUpdating,
          reason: state.reasonFor(cart.checkoutFacts(walletFils: walletFils)),
        ),
        cart.isUpdating,
      );
    });
    final pinned = facts.pinned;
    if (pinned != null) return CheckoutBarFactText(fact: pinned);
    final covered = !(ModalRoute.isCurrentOf(context) ?? true);
    return Semantics(
      label: facts.rotating.map(CheckoutBarFactText.textOf).join('\n'),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          // Keeps the line's height with nothing to say, so the bar never
          // jumps when a first fact arrives.
          Text('', style: AppTextStyles.bodyLarge),
          // Mounted even with nothing to rotate: a fact that only leaves
          // while the cart re-prices is held on screen and comes back in
          // place (RotatingLine freezes while paused), never re-mounted.
          RotatingLine(
            paused: updating || covered,
            items: <RotatingLineItem>[
              for (final fact in facts.rotating)
                RotatingLineItem(
                  id: fact.id,
                  child: CheckoutBarFactText(fact: fact),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
