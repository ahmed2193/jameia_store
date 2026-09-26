import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/catalog_pill_stepper.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// The quick look's basket control: "Add to cart" until the product is in the
/// basket, then the "− qty +" stepper, the one popping into the other's
/// place. Only this control rebuilds when the quantity changes.
class HomeQuickLookCartButton extends StatelessWidget {
  const HomeQuickLookCartButton({super.key, required this.product});

  final CatalogProductEntity product;

  static const double _height = AppSize.s48;
  static const double _poppedFrom = 0.8;

  @override
  Widget build(BuildContext context) {
    // The button clicks by itself; the stepper's + does not.
    void add() => context.read<CartCubit>().addCatalogProduct(product);

    void remove() {
      Haptics.tap();
      context.read<CartCubit>().removeProduct(product.id);
    }

    return SizedBox(
      height: _height,
      child: BlocSelector<CartCubit, CartState, int>(
        selector: (cart) => cart.qtyOfProduct(product.id),
        builder: (context, qty) => AnimatedSwitcher(
          duration: MotionGuard.duration(context, AppMotion.medium),
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: _poppedFrom,
                end: 1,
              ).animate(animation),
              child: child,
            ),
          ),
          child: qty <= 0
              ? AppButton(
                  key: const ValueKey<bool>(false),
                  label: 'catalog.add_to_cart'.tr(),
                  color: AppColors.martGreen,
                  onPressed: add,
                )
              : Center(
                  key: const ValueKey<bool>(true),
                  child: CatalogPillStepper(
                    qty: qty,
                    onAdd: () {
                      Haptics.selection();
                      add();
                    },
                    onRemove: remove,
                  ),
                ),
        ),
      ),
    );
  }
}
