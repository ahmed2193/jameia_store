import 'package:flutter/material.dart';

import '../data/models/shop.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'jameia_image.dart';
import 'price_text.dart';
import 'qty_stepper.dart';

export 'product_row.dart';

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
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  JameiaCardImage(
                    url: product.image,
                    width: width,
                    height: width,
                  ),
                  if (product.hasDiscount)
                    PositionedDirectional(
                      start: AppSize.s6,
                      top: AppSize.s6,
                      child: PopScale(
                        popKey: product.discountPercent,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.s5,
                            vertical: AppSpacing.s1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.finalPrice,
                            borderRadius: BorderRadius.circular(AppRadius.r7),
                          ),
                          child: Text(
                            '-${product.discountPercent}%',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                product.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: [
                  Expanded(
                    child: PriceText(
                      price: product.price,
                      originalPrice: product.originalPrice,
                      size: AppSize.font14,
                    ),
                  ),
                  QtyStepper(
                    qty: qty,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    size: AppSize.s26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
