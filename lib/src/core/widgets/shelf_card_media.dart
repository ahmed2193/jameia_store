import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../domain/entities/catalog_product_entity.dart';
import 'catalog_unavailable_overlay.dart';
import 'hero_image.dart';
import 'shelf_add_control.dart';
import 'shelf_save_badge.dart';

/// The picture of a product card: a light-grey rounded tile (no outline)
/// the product photo fills, the "Save" badge on a deal in the top
/// corner, the "out of stock" wash, and the basket control in the bottom
/// corner (outside the clip, so its shadow is whole).
class ShelfCardMedia extends StatelessWidget {
  const ShelfCardMedia({
    super.key,
    required this.product,
    required this.qty,
    required this.width,
    required this.onAdd,
    required this.onRemove,
    required this.onChooseOptions,
  });

  final CatalogProductEntity product;
  final int qty;
  final double width;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onChooseOptions;

  static const double radius = AppRadius.card;

  /// How far the "Save" badge and the basket control sit in from the
  /// tile's corners (the home "+1" rises from the control's spot).
  static const double controlInset = AppSpacing.s8;

  static const double _dimmed = 0.45;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: width,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              // The grey shows while the picture loads. The catalogue's
              // pictures are full-bleed photos, so they fill the tile: inset,
              // each one read as a framed print.
              child: ColoredBox(
                color: AppColors.smallBackground,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: product.inStock ? 1 : _dimmed,
                      child: HeroImage(
                        url: product.image,
                        width: width,
                        height: width,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!product.inStock) const CatalogUnavailableOverlay(),
                  ],
                ),
              ),
            ),
          ),
          if (product.hasDiscount)
            PositionedDirectional(
              top: controlInset,
              start: controlInset,
              child: ShelfSaveBadge(percent: product.discountPercent),
            ),
          PositionedDirectional(
            bottom: controlInset,
            end: controlInset,
            child: ShelfAddControl(
              product: product,
              qty: qty,
              onAdd: onAdd,
              onRemove: onRemove,
              onChooseOptions: onChooseOptions,
            ),
          ),
        ],
      ),
    );
  }
}
