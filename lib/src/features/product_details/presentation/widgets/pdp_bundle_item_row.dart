import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/product_detail.dart';

/// One product inside a bundle: thumbnail, "2 × name" and what it costs in
/// the bundle. A tap opens that product.
class PdpBundleItemRow extends StatelessWidget {
  const PdpBundleItemRow({super.key, required this.item, required this.onTap});

  final ProductBundleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s6),
        child: Row(
          children: [
            JameiaImage(
              url: item.product.image,
              width: AppSize.s48,
              height: AppSize.s48,
              radius: AppSize.r8,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                'product.bundle_item'.tr(
                  namedArgs: {
                    'quantity': '${item.quantity}',
                    'name': item.product.name,
                  },
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              Formatters.price(item.unitPriceKd),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: AppSize.s18,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
