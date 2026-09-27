import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../domain/entities/cart_offers_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_deals_cubit.dart';
import '../cart/cart_checkout_bar.dart';
import 'cart_deal_products.dart';
import 'cart_deals_band.dart';

/// "Buy more, save more" over the cart: the cart's offers as cards (earned
/// ones say what they saved, the others what is still missing), the
/// products to add towards the selected one, and the basket bar with
/// "Checkout" at the bottom — the products added here fly into its basket.
class CartDealsSheet extends StatelessWidget {
  const CartDealsSheet({super.key});

  /// Of the screen's height.
  static const double _heightFactor = 0.9;

  /// Opens over the cart page, sharing the page's [CartDealsCubit]; the
  /// cubit starts on the next deal to unlock.
  static Future<void> show(BuildContext context) {
    final deals = context.read<CartDealsCubit>();
    deals.open(CartOffersView.of(context.read<CartCubit>().state.cart));
    return showHeroBottomSheet<void>(
      context,
      large: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) =>
          BlocProvider.value(value: deals, child: const CartDealsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * _heightFactor,
        child: const Column(
          children: [
            CartDealsBand(),
            Expanded(child: CartDealProducts()),
            CartCheckoutBar(inSheet: true),
          ],
        ),
      ),
    );
  }
}
