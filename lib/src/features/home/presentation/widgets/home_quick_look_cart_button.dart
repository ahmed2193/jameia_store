import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/pop_switcher.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../core/widgets/catalog_pill_stepper.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// The quick look's basket control: "Add to cart" until the product is in the
/// basket, then the "− qty +" stepper, the one popping into the other's
/// place — the one add → stepper swap of every add surface ([PopSwitcher]).
/// An add is the app's one add gesture ([CatalogCartGestures]: a click, the
/// photo flying to the cart, the badge bumping on landing). Only this
/// control rebuilds when the quantity changes.
class HomeQuickLookCartButton extends StatelessWidget {
  const HomeQuickLookCartButton({super.key, required this.product});

  final CatalogProductEntity product;

  static const double _height = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: BlocSelector<CartCubit, CartState, int>(
        selector: (cart) => cart.qtyOfProduct(product.id),
        builder: (context, qty) {
          void add() => CatalogCartGestures.add(
            context,
            image: product.image,
            commit: () => context.read<CartCubit>().addCatalogProduct(product),
          );
          final inCart = qty > 0;
          return PopSwitcher(
            stateKey: inCart,
            from: PopSwitcher.cartFrom,
            child: inCart
                ? Center(
                    child: CatalogPillStepper(
                      qty: qty,
                      onAdd: add,
                      onRemove: () => CatalogCartGestures.remove(
                        commit: () =>
                            context.read<CartCubit>().removeProduct(product.id),
                      ),
                    ),
                  )
                : AppButton(
                    label: 'catalog.add_to_cart'.tr(),
                    // The add gesture sends the one click.
                    haptic: null,
                    onPressed: add,
                  ),
          );
        },
      ),
    );
  }
}
