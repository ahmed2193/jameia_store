import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/cart_offers_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_deals_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_deal_card.dart';

/// The sheet's offers, side by side: earned ones first, then the ones still
/// to unlock. They follow the cart live — adding from the grid below moves
/// an offer from "Add KD 2.750 more" to "Offer applied".
class CartDealCardsRow extends StatelessWidget {
  const CartDealCardsRow({super.key});

  /// Two text lines at the default scale, plus the card's padding.
  static const double _textBlock = AppSize.s46;
  static const double _cardChrome = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<CartDealsCubit, String?>(
      (cubit) => cubit.state.selectedOfferId,
    );
    final text = MediaQuery.textScalerOf(context).scale(_textBlock);
    return BlocSelector<CartCubit, CartState, CartOffersView>(
      selector: (cart) => CartOffersView.of(cart.cart),
      builder: (context, view) => SizedBox(
        height: text + _cardChrome + CartDealCard.pointerHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          itemCount: view.deals.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s10),
          itemBuilder: (context, index) {
            final deal = view.deals[index];
            return CartDealCard(
              key: ValueKey<String>(deal.offerId),
              deal: deal,
              selected: deal.offerId == selected,
              onTap: () => context.read<CartDealsCubit>().select(deal),
            );
          },
        ),
      ),
    );
  }
}
