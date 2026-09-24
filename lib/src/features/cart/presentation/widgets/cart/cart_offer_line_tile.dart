import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_card_image.dart';

/// A free product an offer put in the cart: not editable, marked as a gift.
class CartOfferLineTile extends StatelessWidget {
  const CartOfferLineTile({super.key, required this.line});

  final CartOfferLineEntity line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          JameiaCardImage(
            url: line.product.image,
            width: AppSize.s56,
            height: AppSize.s56,
            radius: AppRadius.r4,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'cart.free_gift'.tr(namedArgs: {'offer': line.offerName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.freeDelivery,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            '× ${line.quantity}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
