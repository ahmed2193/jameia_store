import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';

class OrderItems extends StatelessWidget {
  const OrderItems({super.key, required this.items});

  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    // Bundle: db08ab — Jameia-Regular 12dp #808080, max-lines 2, text-overflow ellipsis.
    // Show up to 2 items inline; if more, summarise with "+N more".
    final shown = items.length > 2 ? items.sublist(0, 2) : items;
    final extra = items.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    // Bundle: db08ab max-lines 2, text-overflow ellipsis
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      // Bundle: Jameia-Regular 12dp #808080
                      color: AppColors.secondaryText,
                      fontWeight: AppTextStyles.regular,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                // Bundle: qty badge right-aligned, Jameia-Regular 12dp tertiaryText
                Text(
                  '×${item.qty}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.tertiaryText,
                    fontWeight: AppTextStyles.regular,
                  ),
                ),
              ],
            ),
          ),
        if (extra > 0)
          Text(
            'orders.more_items'.tr(namedArgs: {'count': '$extra'}),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
      ],
    );
  }
}
