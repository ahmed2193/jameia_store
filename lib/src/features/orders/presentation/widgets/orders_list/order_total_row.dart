import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/widgets/hero_money_text.dart';

/// "n items" on the start side, the order total on the end side — the total
/// as one left-to-right money run, static (a list row never rolls).
class OrderTotalRow extends StatelessWidget {
  const OrderTotalRow({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'orders.item_count'.plural(order.itemCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.meta,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        HeroMoneyText(kd: order.totalKd, style: AppTextStyles.itemTitleStrong),
      ],
    );
  }
}
