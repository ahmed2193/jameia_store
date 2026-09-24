import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/summary_row.dart';

/// The ordered lines with their totals and, unless this IS the invoice,
/// a link to it.
class OrderLinesCard extends StatelessWidget {
  const OrderLinesCard({
    super.key,
    required this.order,
    this.showInvoiceLink = true,
  });

  final OrderEntity order;

  /// `false` on the invoice page itself, where the link would push a second
  /// copy of the page the customer is already reading.
  final bool showInvoiceLink;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in order.lines)
            Padding(
              key: ValueKey<String>(line.key),
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.quantity} × ${line.nameFor(lc)}'
                      '${line.variantNameFor(lc).isEmpty ? '' : ' · ${line.variantNameFor(lc)}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text(
                    Formatters.price(line.lineTotalKd),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          for (final line in order.offerLines)
            Padding(
              key: ValueKey<String>('offer:${line.offerId}:${line.productId}'),
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s4,
              ),
              child: Text(
                '${line.quantity} × ${line.nameFor(lc)} · ${line.offerNameFor(lc)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.freeDelivery,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s8),
          SummaryRow(
            label: 'orders.total'.tr(),
            value: Formatters.price(order.totalKd),
            emphasized: true,
          ),
          if (showInvoiceLink)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () =>
                    context.push(Routes.orderInvoice, extra: order.id),
                child: Text('orders.invoice'.tr()),
              ),
            ),
        ],
      ),
    );
  }
}
