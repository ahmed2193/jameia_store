import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/order.dart';
import '../../screens/order_invoice_screen.dart';
import 'delivery_code_dialog.dart';
import 'help_row.dart';
import 'tracking_card.dart';
import 'tracking_divider.dart';
import 'tracking_helpers.dart';

// ── Help / refund entry ───────────────────────────────────────────────────────

class HelpRefundCard extends StatelessWidget {
  const HelpRefundCard({super.key, required this.order});

  /// Tracked order — its id is forwarded to the e-invoice screen and its dummy
  /// getters feed the delivery-code / speed-up stubs.
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    // Real KeeTa a15c8b: padding=14dp 20dp per row, card radius=16dp.
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Delivery-code entry (feature #4) — always reachable from help.
          HelpRow(
            icon: KeetaIcons.confirmReceipt,
            label: 'map.delivery_code'.tr(),
            onTap: () => showKeetaDialog<void>(
              context,
              barrierLabel: 'map.delivery_code'.tr(),
              pageBuilder: (ctx) =>
                  DeliveryCodeDialog(code: order.deliveryCode),
            ),
          ),
          const TrackingDivider(),
          // Rush / speed-up entry (feature #7).
          HelpRow(
            icon: KeetaIcons.urgeOrder,
            label: 'orders.speed_up_delivery'.tr(),
            onTap: () => _showSpeedUpSheet(context),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: KeetaIcons.confirmReceipt,
            label: 'orders.view_einvoice'.tr(),
            onTap: () => Navigator.of(context).push(
              KeetaPageRoute<void>(
                page: OrderInvoiceScreen(orderId: order.id),
                settings: const RouteSettings(name: Routes.orderInvoice),
              ),
            ),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: KeetaIcons.customerService,
            label: 'orders.get_help'.tr(),
            onTap: () => Navigator.pushNamed(context, Routes.customerService),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: KeetaIcons.refund,
            label: 'orders.request_refund'.tr(),
            onTap: () => Navigator.pushNamed(context, Routes.orderRefund),
          ),
        ],
      ),
    );
  }
}

// ── Speed-up / rush sheet (feature #7) ────────────────────────────────────────

void _showSpeedUpSheet(BuildContext context) {
  showKeetaBottomSheet<void>(
    context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheetCtx) {
      final bottomPad = MediaQuery.paddingOf(sheetCtx).bottom;
      return Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.s20,
          end: AppSpacing.s20,
          top: AppSpacing.s16,
          bottom: bottomPad + AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                KeetaIcons.urgeOrder,
                size: 26,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'orders.speed_up_delivery'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'orders.speed_up_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(
              label: 'orders.confirm_rush'.tr(),
              radius: AppRadius.pill,
              onPressed: () {
                Navigator.maybePop(sheetCtx);
                trackingToast(context, 'orders.rush_requested'.tr());
              },
            ),
          ],
        ),
      );
    },
  );
}
