import 'package:flutter/material.dart';
import '../data/models/shop.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'keeta_image.dart';
import 'price_text.dart';
import 'qty_stepper.dart';

/// Horizontal menu row (KeeTa shop menu item): thumbnail, name, desc, price + add.
class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
  });

  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeetaCardImage(url: product.image, width: 92, height: 92),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall
                          .copyWith(fontWeight: AppTextStyles.bold)),
                  const SizedBox(height: 2),
                  if (product.desc.isNotEmpty)
                    Text(product.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge
                            .copyWith(color: AppColors.tertiaryText)),
                  const SizedBox(height: AppSpacing.s4),
                  Text(Formatters.sold(product.soldCount),
                      style: AppTextStyles.captionSmall
                          .copyWith(color: AppColors.tertiaryText)),
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    children: [
                      Expanded(
                          child: PriceText(
                              price: product.price,
                              originalPrice: product.originalPrice)),
                      QtyStepper(qty: qty, onAdd: onAdd, onRemove: onRemove),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact vertical product card for grids / rails (home & grocery).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.width = 132,
    this.onTap,
  });

  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                KeetaCardImage(
                    url: product.image, width: width, height: width),
                if (product.hasDiscount)
                  PositionedDirectional(
                    start: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.finalPrice,
                        borderRadius: BorderRadius.circular(AppRadius.r7),
                      ),
                      child: Text('-${product.discountPercent}%',
                          style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                    child: PriceText(
                        price: product.price,
                        originalPrice: product.originalPrice,
                        size: 14)),
                QtyStepper(
                    qty: qty, onAdd: onAdd, onRemove: onRemove, size: 26),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
