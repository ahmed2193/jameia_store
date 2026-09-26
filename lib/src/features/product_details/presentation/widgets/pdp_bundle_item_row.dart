import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/product_detail.dart';

/// One product inside a bundle, as a flat row: the photo on a light-grey
/// tile, "2 × name", what it costs in the bundle and a chevron. A tap opens
/// that product.
class PdpBundleItemRow extends StatelessWidget {
  const PdpBundleItemRow({super.key, required this.item, required this.onTap});

  final ProductBundleItem item;
  final VoidCallback onTap;

  static const double _thumb = AppSize.s56;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s10,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r5),
                child: ColoredBox(
                  color: AppColors.smallBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: JameiaImage(
                      url: item.product.image,
                      width: _thumb - AppSpacing.s8,
                      height: _thumb - AppSpacing.s8,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
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
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                Formatters.price(item.unitPriceKd),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppSize.s20,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
