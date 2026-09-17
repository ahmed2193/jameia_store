import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';
import 'copyable_line.dart';
import 'summary_item_row.dart';
import 'summary_line.dart';
import 'tracking_card.dart';
import 'tracking_divider.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    // Real Jameia: section title uses bad7c1 (margin=12dp 16dp, Medium 16dp).
    // Inner content padding bde1e4: padding=0dp 16dp 16dp 16dp.
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title row — margin 12dp top, 16dp horizontal (bad7c1)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Text(
              'orders.order_summary'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          const TrackingDivider(),
          // Content area — padding 0dp 16dp 16dp 16dp (bde1e4)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list
                for (final item in order.items) ...[
                  SummaryItemRow(item: item),
                  const SizedBox(height: AppSpacing.s8),
                ],
                const SizedBox(height: AppSpacing.s4),
                const TrackingDivider(),
                const SizedBox(height: AppSpacing.s12),
                SummaryLine(
                  label: 'map.platform_fee'.tr(),
                  value: Formatters.price(order.platformFee),
                ),
                const SizedBox(height: AppSpacing.s8),
                SummaryLine(
                  label: 'orders.total'.tr(),
                  value: Formatters.price(order.total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.s8),
                // Real payment method from the dummy backend getter.
                SummaryLine(
                  label: 'orders.payment'.tr(),
                  value: order.paymentMethod,
                ),
                const SizedBox(height: AppSpacing.s8),
                SummaryLine(
                  label: 'orders.payment_id'.tr(),
                  value: order.paymentId,
                ),
                const SizedBox(height: AppSpacing.s8),
                SummaryLine(
                  label: 'orders.order_date'.tr(),
                  value: order.displayDate,
                ),
                const SizedBox(height: AppSpacing.s8),
                // Order id with a copy-to-clipboard affordance.
                CopyableLine(
                  label: 'orders.order_id'.tr(),
                  value: '#${order.id.toUpperCase()}',
                  copyValue: order.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
