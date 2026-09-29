import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/hero_money_text.dart';
import '../../../../core/widgets/hero_section_header.dart';
import '../../../../core/widgets/hero_summary_line.dart';
import '../../../../core/widgets/thin_divider.dart';

/// The receipt look of the item list (a sliver): the "Your items" heading
/// (with an underlined "Invoice" link when [showInvoiceLink]), the flat
/// rows [list] and the order total under them.
class OrderLinesReceiptSection extends StatelessWidget {
  const OrderLinesReceiptSection({
    super.key,
    required this.list,
    required this.orderId,
    required this.totalKd,
    required this.showInvoiceLink,
  });

  /// The rows, a sliver.
  final Widget list;
  final String orderId;
  final double totalKd;
  final bool showInvoiceLink;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: HeroSectionHeader(
            title: 'orders.items_title'.tr(),
            titleStyle: AppTextStyles.groupTitle,
            seeAllLabel: 'orders.invoice'.tr(),
            onSeeAll: showInvoiceLink
                ? () => context.push(Routes.orderInvoice, extra: orderId)
                : null,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          sliver: list,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThinDivider(),
                const SizedBox(height: AppSpacing.s6),
                HeroSummaryLine(
                  label: 'orders.total'.tr(),
                  emphasized: true,
                  value: HeroMoneyText(kd: totalKd),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
