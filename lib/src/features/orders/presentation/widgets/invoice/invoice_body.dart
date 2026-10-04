import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_section_header.dart';
import '../../../domain/entities/order_line_changes.dart';
import '../order_lines_sliver.dart';
import '../tracking/tracking_store_row.dart';
import 'invoice_facts.dart';
import 'invoice_receipt_hero.dart';
import 'invoice_section.dart';
import 'invoice_totals.dart';

/// The receipt on the white page, read top-down the way people check one:
/// what it came to and where the payment stands ([InvoiceReceiptHero]),
/// the order's facts ([InvoiceFacts]), the items on the order page's card
/// (store, count, each line with its unit price and what picking did to
/// it; lazy, so a 60-line order builds only what is on screen), and the
/// payment summary under a tear line. A document: nothing on it moves.
class InvoiceBody extends StatelessWidget {
  const InvoiceBody({super.key, required this.order});

  /// The receipt's width on a tablet or a phone on its side: a paper
  /// receipt's column, not the whole screen (the page and its "Download
  /// invoice" bar both hold to it).
  static const double maxWidth = AppSize.s520;

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: InvoiceReceiptHero(order: order)),
        SliverToBoxAdapter(child: InvoiceFacts(order: order)),
        SliverToBoxAdapter(
          child: HeroSectionHeader(
            title: 'orders.items_title'.tr(),
            titleStyle: AppTextStyles.groupTitle,
            padding: InvoiceSection.between,
          ),
        ),
        OrderLinesSliver(
          orderId: order.id,
          lines: order.lines,
          offerLines: order.offerLines,
          totalKd: order.totalKd,
          changes: OrderLineChanges.of(order.picking),
          card: true,
          leading: TrackingStoreRow(order: order),
          leadingKey: order.branch,
          showUnitPrice: true,
        ),
        SliverToBoxAdapter(
          child: InvoiceTotals(order: order, perforated: true),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
    );
  }
}
