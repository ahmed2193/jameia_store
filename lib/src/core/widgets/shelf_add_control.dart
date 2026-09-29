import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/entities/catalog_product_entity.dart';
import '../motion/pop_switcher.dart';
import 'catalog_pill_stepper.dart';
import 'shelf_add_button.dart';

/// A listing card's basket control, in the picture's bottom corner: the
/// round "+" until the product is in the basket, then the "− qty +" pill,
/// which pops out of the "+" corner in place (and fades back into it at
/// zero) — the one add → stepper swap of every add surface ([PopSwitcher]
/// from [PopSwitcher.cartFrom], docs/motion BX-09). A product with sizes
/// shows the options glyph and opens its page; nothing for a product out of
/// stock.
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

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) return const SizedBox.shrink();
    final quick = product.canQuickAdd;
    final add = quick ? onAdd : onChooseOptions;
    final inBasket = qty > 0;
    return PopSwitcher(
      stateKey: inBasket,
      alignment: AlignmentDirectional.centerEnd,
      from: PopSwitcher.cartFrom,
      child: inBasket
          ? CatalogPillStepper(qty: qty, onAdd: add, onRemove: onRemove)
          : ShelfAddButton(
              label: (quick ? 'catalog.add_to_cart' : 'catalog.choose_options')
                  .tr(),
              options: !quick,
              onTap: add,
            ),
    );
  }
}
