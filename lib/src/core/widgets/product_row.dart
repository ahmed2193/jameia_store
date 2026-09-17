import 'package:flutter/material.dart';

import '../data/models/shop.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../utils/formatters.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'jameia_image.dart';
import 'price_text.dart';
import 'qty_stepper.dart';

/// Horizontal menu row (Jameia shop menu item): thumbnail, name, desc, price + add.
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
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JameiaCardImage(
                url: product.image,
                width: AppSize.s92,
                height: AppSize.s92,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    if (product.desc.isNotEmpty)
                      Text(
                        product.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      Formatters.sold(product.soldCount),
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Row(
                      children: [
                        Expanded(
                          child: PriceText(
                            price: product.price,
                            originalPrice: product.originalPrice,
                          ),
                        ),
                        QtyStepper(qty: qty, onAdd: onAdd, onRemove: onRemove),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
