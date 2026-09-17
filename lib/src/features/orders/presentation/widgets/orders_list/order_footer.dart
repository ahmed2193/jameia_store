import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';

class OrderFooter extends StatelessWidget {
  const OrderFooter({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    // Bundle: c197ff — Jameia-Regular 12dp #999999 (tertiaryText) for meta line.
    // Total: Jameia-Bold 14dp #222222 (headingSmall bold).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Date/time with clock icon
        Icon(JameiaIcons.time, size: 12, color: AppColors.tertiaryText),
        const SizedBox(width: AppSpacing.s4),
        Text(
          order.displayDate,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.tertiaryText,
            fontWeight: AppTextStyles.regular,
          ),
        ),
        const Spacer(),
        // Item count + total
        Text(
          '${'orders.item_count'.tr(namedArgs: {'count': '${order.itemCount}'})}  ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.tertiaryText,
            fontWeight: AppTextStyles.regular,
          ),
        ),
        // Bundle: price text Jameia-Bold 14dp #222222
        Text(
          Formatters.price(order.total),
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
