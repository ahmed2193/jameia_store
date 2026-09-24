import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';

/// Order number, date, payment method and payment status.
class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key, required this.order});

  final OrderEntity order;

  String get _method => switch (order.payment.method) {
    OrderPaymentMethod.cod => 'orders.payment_cod'.tr(),
    OrderPaymentMethod.wallet => 'orders.payment_wallet'.tr(),
    OrderPaymentMethod.other => 'orders.payment_other'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'orders.invoice_number'.tr(),
            value: order.orderNumber,
          ),
          SummaryRow(
            label: 'orders.invoice_date'.tr(),
            value: Formatters.dateTime(
              context.locale.languageCode,
              order.createdAt,
            ),
          ),
          SummaryRow(label: 'orders.invoice_payment'.tr(), value: _method),
          SummaryRow(
            label: 'orders.invoice_status'.tr(),
            value: order.payment.isPaid
                ? 'orders.payment_paid'.tr()
                : 'orders.payment_pending'.tr(),
            valueColor: order.payment.isPaid
                ? AppColors.success
                : AppColors.warn,
          ),
        ],
      ),
    );
  }
}
