import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/entities/catalog_product_entity.dart';
import '../motion/motion.dart';
import 'catalog_pill_stepper.dart';
import 'shelf_add_button.dart';

/// A listing card's basket control, in the picture's bottom corner: the
/// round "+" until the product is in the basket, then the "− qty +" pill,
/// which grows out of the "+" (and shrinks back into it at zero). A product
/// with sizes shows the options glyph and opens its page; nothing for a
/// product out of stock.
class ShelfAddControl extends StatelessWidget {
  const ShelfAddControl({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    required this.onChooseOptions,
  });

  final CatalogProductEntity product;

  /// Units of this product in the basket (all variants together).
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Opens the product so a size can be chosen.
  final VoidCallback onChooseOptions;

  static const double _grownFrom = 0.6;

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) return const SizedBox.shrink();
    final quick = product.canQuickAdd;
    final add = quick ? onAdd : onChooseOptions;
    final corner = AlignmentDirectional.centerEnd.resolve(
      Directionality.of(context),
    );
    return AnimatedSwitcher(
      duration: MotionGuard.duration(context, AppMotion.medium),
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(Tween<double>(begin: _grownFrom, end: 1)),
          alignment: corner,
          child: child,
        ),
      ),
      child: qty <= 0
          ? ShelfAddButton(
              key: const ValueKey<bool>(false),
              label: (quick ? 'catalog.add_to_cart' : 'catalog.choose_options')
                  .tr(),
              icon: quick ? Icons.add_rounded : Icons.tune_rounded,
              onTap: add,
            )
          : CatalogPillStepper(
              key: const ValueKey<bool>(true),
              qty: qty,
              onAdd: add,
              onRemove: onRemove,
            ),
    );
  }
}
