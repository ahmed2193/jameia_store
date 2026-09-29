import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/widgets/catalog_circle_add_button.dart';
import '../../../../../core/widgets/catalog_pill_stepper.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import 'assistant_cart_taps.dart';

/// The cart control of the wide product card: + (or "choose options" for a
/// product with variants), then a stepper once it is in the cart — the one
/// add → stepper pop of every add surface ([PopSwitcher]). Nothing for a
/// product out of stock.
class AssistantProductDetailAction extends StatelessWidget {
  const AssistantProductDetailAction({super.key, required this.product});

  final CatalogProductEntity product;

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) return const SizedBox.shrink();
    return BlocSelector<CartCubit, CartState, int>(
      selector: (cart) => cart.qtyOfProduct(product.id),
      builder: (context, qty) {
        final quick = product.canQuickAdd;
        void add() => quick
            ? AssistantCartTaps.add(context, product)
            : AssistantCartTaps.open(context, product);
        final inCart = qty > 0;
        return PopSwitcher(
          stateKey: inCart,
          alignment: AlignmentDirectional.centerEnd,
          from: PopSwitcher.cartFrom,
          child: inCart
              ? CatalogPillStepper(
                  qty: qty,
                  onAdd: add,
                  onRemove: () => AssistantCartTaps.remove(context, product),
                )
              : CatalogCircleAddButton(
                  label:
                      (quick ? 'catalog.add_to_cart' : 'catalog.choose_options')
                          .tr(),
                  options: !quick,
                  onTap: add,
                ),
        );
      },
    );
  }
}
