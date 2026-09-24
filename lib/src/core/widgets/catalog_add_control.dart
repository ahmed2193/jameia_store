import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../domain/entities/catalog_product_entity.dart';
import 'catalog_circle_add_button.dart';
import 'catalog_pill_stepper.dart';

/// The cart control floating over a product image. Must sit inside a [Stack].
///
/// - not in the cart → a round button at the bottom-end corner: "+" adds one,
///   or a tune icon opens the options when the product needs a choice first
///   (a variant product has no price of its own);
/// - in the cart → a centred "− qty +" pill.
///
/// Renders nothing for an out-of-stock product. The cart itself lives in the
/// feature: this widget only reports taps.
class CatalogAddControl extends StatelessWidget {
  const CatalogAddControl({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    required this.onChooseOptions,
  });

  final CatalogProductEntity product;

  /// Units of this product already in the cart (all variants together).
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Opens the product so a variant can be chosen.
  final VoidCallback onChooseOptions;

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) return const SizedBox.shrink();
    final add = product.canQuickAdd ? onAdd : onChooseOptions;
    if (qty <= 0) {
      return PositionedDirectional(
        bottom: AppSpacing.s6,
        end: AppSpacing.s6,
        child: CatalogCircleAddButton(
          label: product.canQuickAdd
              ? 'catalog.add_to_cart'.tr()
              : 'catalog.choose_options'.tr(),
          icon: product.canQuickAdd ? Icons.add_rounded : Icons.tune_rounded,
          onTap: add,
        ),
      );
    }
    return PositionedDirectional(
      bottom: AppSpacing.s6,
      start: 0,
      end: 0,
      child: Center(
        child: CatalogPillStepper(qty: qty, onAdd: add, onRemove: onRemove),
      ),
    );
  }
}
