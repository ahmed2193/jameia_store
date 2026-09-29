import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_section_header.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/order_timeline.dart';
import 'tracking_copy_button.dart';
import 'tracking_timeline.dart';

/// "Order info": the order number (with a copy button, for a chat with
/// support), when it was placed, the invoice, and the folded "Order updates"
/// history — one hairline card.
class TrackingOrderInfo extends StatelessWidget {
  const TrackingOrderInfo({super.key, required this.order});

  final OrderEntity order;

  static final TextStyle _number = AppTextStyles.label.copyWith(
    fontFeatures: AppTextStyles.tabular,
  );

  @override
  Widget build(BuildContext context) {
    final placed = Formatters.dateTime(
      context.locale.languageCode,
      order.createdAt,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSectionHeader(
          title: 'orders.info_title'.tr(),
          titleStyle: AppTextStyles.groupTitle,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: HeroSurfaceCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: HeroSummaryLine(
                        label: 'orders.invoice_number'.tr(),
                        value: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(order.orderNumber, style: _number),
                        ),
                      ),
                    ),
                    TrackingCopyButton(text: order.orderNumber),
                  ],
                ),
                if (placed.isNotEmpty)
                  HeroSummaryLine(
                    label: 'orders.placed_on'.tr(),
                    value: Text(placed),
                  ),
                const ThinDivider(),
                HeroListRow(
                  title: 'orders.view_invoice'.tr(),
                  icon: Icons.receipt_long_outlined,
                  dense: true,
                  onTap: () =>
                      context.push(Routes.orderInvoice, extra: order.id),
                ),
                const ThinDivider(),
                TrackingTimeline(timeline: OrderTimeline.of(order)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
