import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
// TODO(P2.9-boundary): CartState is the cart feature's cubit state — read here
// to render the live cart lines; kept as-is at this cross-feature boundary.
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../util/shop_display.dart';
import 'item_row.dart';

/// Shop name + item rows. KeeTa section-header style: 16dp/w500/#222222,
/// padding 0dp 16dp, mb 12dp (from d9ac92/h827b7 in css.json).
class ItemsSection extends StatelessWidget {
  const ItemsSection({super.key, required this.shop, required this.cart});
  final ShopEntity shop;
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — KeeTa exact: pt:20dp, ph:16dp, mb:12dp, 16dp/w500
          const SizedBox(height: AppSpacing.s20),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            child: Row(
              children: [
                KeetaImage.circle(url: shop.logo, size: 24),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  shop.displayName,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          // Divider
          const ThinDivider(indent: AppSpacing.s16),
          // Item rows
          for (final line in cart.lines) ItemRow(line: line),
          // "Add more items" link row
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'checkout.add_more_items'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
