import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/checkout_thumbs.dart';
import 'checkout_items_list.dart';
import 'checkout_sheet_frame.dart';

/// The "Total 12 pcs" sheet: every line of the order (then the free gifts)
/// in the checkout sheet shell, the title counting the pieces. It reads
/// only the app-global cart, so it needs no page cubit. When the last line
/// goes (the customer removed every unavailable one), it closes itself.
class CheckoutItemsSheet extends StatelessWidget {
  const CheckoutItemsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pieces = context.select<CartCubit, int>(
      (cubit) => CheckoutThumbs.piecesOf(cubit.state.cart),
    );
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          previous.cart.isNotEmpty && current.cart.isEmpty,
      listener: (context, _) {
        if (ModalRoute.isCurrentOf(context) ?? false) context.pop();
      },
      child: CheckoutSheetFrame(
        title: 'checkout.items_sheet_title'.plural(pieces),
        child: const CheckoutItemsList(),
      ),
    );
  }
}
