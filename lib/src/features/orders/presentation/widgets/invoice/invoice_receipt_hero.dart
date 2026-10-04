import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/hero_tag.dart';
import '../../../domain/entities/order_invoice_summary.dart';
import '../../../domain/entities/order_payment_standing.dart';
import 'invoice_payment_status.dart';

/// The top of the invoice, the part a customer looks for first (and
/// screenshots): what the order comes to in large digits, where the payment
/// stands, when it was placed, and what the discounts saved. Stacked, so a
/// narrow phone or large text wraps the pill and the date instead of
/// squeezing them, and the amount scales down rather than overflow.
class InvoiceReceiptHero extends StatelessWidget {
  const InvoiceReceiptHero({super.key, required this.order});

  static final TextStyle _totalStyle = AppTextStyles.digits(AppSize.font40);

  static const ShapeDecoration _pill = ShapeDecoration(
    color: AppColors.white,
    shape: StadiumBorder(),
  );

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final summary = OrderInvoiceSummary.of(order);
    final createdAt = order.createdAt;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSurfaceCard(
        tone: HeroSurfaceTone.brand,
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DecoratedBox(
                  decoration: _pill,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s10,
                      vertical: AppSpacing.s4,
                    ),
                    child: DefaultTextStyle.merge(
                      style: AppTextStyles.label,
                      child: InvoicePaymentStatus(
                        standing: OrderPaymentStanding.ofOrder(order),
                      ),
                    ),
                  ),
                ),
                if (createdAt != null)
                  Text(
                    Formatters.dateTime(context.locale.languageCode, createdAt),
                    style: AppTextStyles.meta,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('orders.total'.tr(), style: AppTextStyles.meta),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: HeroMoneyText(kd: summary.totalKd, style: _totalStyle),
            ),
            if (summary.savedFils > 0) ...[
              const SizedBox(height: AppSpacing.s8),
              HeroTag(
                label: 'orders.invoice_saved'.tr(
                  namedArgs: {
                    'amount': Formatters.priceInline(summary.savedKd),
                  },
                ),
                icon: HeroIcons.savings,
                tone: HeroTagTone.brand,
                pill: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
