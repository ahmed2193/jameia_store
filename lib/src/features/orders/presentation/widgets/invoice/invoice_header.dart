import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import 'invoice_payment_status.dart';
import 'invoice_section.dart';

/// "Order info": order number, date, payment method and payment status on a
/// hairline card — the first section of the invoice.
class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key, required this.order});

  static const TextStyle _numberStyle = TextStyle(
    fontFeatures: AppTextStyles.tabular,
  );

  final OrderEntity order;

  String get _method => switch (order.payment.method) {
    OrderPaymentMethod.cod => 'orders.payment_cod'.tr(),
    OrderPaymentMethod.wallet => 'orders.payment_wallet'.tr(),
    OrderPaymentMethod.other => 'orders.payment_other'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return InvoiceSection(
      title: 'orders.info_title'.tr(),
      headerPadding: InvoiceSection.pageTop,
      children: [
        HeroSummaryLine(
          label: 'orders.invoice_number'.tr(),
          value: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(order.orderNumber, style: _numberStyle),
          ),
        ),
        HeroSummaryLine(
          label: 'orders.invoice_date'.tr(),
          value: Text(
            Formatters.dateTime(context.locale.languageCode, order.createdAt),
          ),
        ),
        HeroSummaryLine(
          label: 'orders.invoice_payment'.tr(),
          value: Text(_method),
        ),
        HeroSummaryLine(
          label: 'orders.invoice_status'.tr(),
          value: InvoicePaymentStatus(paid: order.payment.isPaid),
        ),
      ],
    );
  }
}
