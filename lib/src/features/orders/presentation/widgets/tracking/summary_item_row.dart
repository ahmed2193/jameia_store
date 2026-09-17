import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';

class SummaryItemRow extends StatelessWidget {
  const SummaryItemRow({super.key, required this.item});
  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    // Jameia item rows: qty chip in secondaryText 12dp, name Regular 14dp,
    // price Regular 14dp primaryText.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.qty}×',
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            item.displayName,
            style: AppTextStyles.bodyLarge, // Regular 14dp
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          Formatters.price(item.price * item.qty),
          style: AppTextStyles.bodyLarge, // Regular 14dp
        ),
      ],
    );
  }
}
