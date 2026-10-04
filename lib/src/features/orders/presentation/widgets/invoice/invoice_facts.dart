import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/order_type_label.dart';
import '../tracking/tracking_copy_button.dart';
import 'invoice_fact_tile.dart';
import 'invoice_section.dart';

/// "Order info": the order number (with a copy button), how the order
/// reaches the customer, the day and window it was booked for, how it is
/// paid (with the wallet's share), and where it goes. The tiles sit two to a row when
/// two fit — a narrow phone or large text puts them one under the other —
/// and the address always takes the whole width.
class InvoiceFacts extends StatelessWidget {
  const InvoiceFacts({super.key, required this.order});

  /// The narrowest a tile may be at text scale 1 before the grid drops to
  /// one column.
  static const double _minTileWidth = AppSize.s140;

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final slot = order.deliverySlot;
    final slotDay = slot?.day;
    final payment = order.payment;
    final address = order.isPickup ? null : order.address;
    final tiles = <Widget>[
      InvoiceFactTile(
        label: 'orders.invoice_number'.tr(),
        value: order.orderNumber,
        trailing: TrackingCopyButton(text: order.orderNumber),
      ),
      InvoiceFactTile(
        label: 'orders.invoice_pdf_type'.tr(),
        value: order.typeLabelKey.tr(),
      ),
      if (slot != null)
        InvoiceFactTile(
          label: 'orders.invoice_pdf_slot'.tr(),
          value: slotDay == null ? slot.date : Formatters.dayMonth(lc, slotDay),
          detail: 'orders.eta_window_value'.tr(
            namedArgs: {
              'start': Formatters.isolate(slot.start),
              'end': Formatters.isolate(slot.end),
            },
          ),
        ),
      InvoiceFactTile(
        label: 'orders.invoice_payment'.tr(),
        value: payment.method.labelKey.tr(),
        detail: payment.walletShareFils > 0
            ? 'orders.payment_wallet_share'.tr(
                namedArgs: {
                  'amount': Formatters.priceInline(payment.walletShareKd),
                },
              )
            : '',
      ),
    ];
    return InvoiceSection(
      title: 'orders.info_title'.tr(),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns = width >= 2 * _minTileWidth * scale + AppSpacing.s16
                ? 2
                : 1;
            final tileWidth =
                (width - AppSpacing.s16 * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpacing.s16,
              children: [
                for (final tile in tiles)
                  SizedBox(width: tileWidth, child: tile),
                if (address != null)
                  SizedBox(
                    width: width,
                    child: InvoiceFactTile(
                      label: 'orders.deliver_to'.tr(),
                      value: address.label.isEmpty
                          ? address.summary
                          : address.label,
                      detail: address.label.isEmpty ? '' : address.summary,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
