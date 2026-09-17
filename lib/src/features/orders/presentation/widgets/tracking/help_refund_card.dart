import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/order.dart';
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
    // Real Jameia a15c8b: padding=14dp 20dp per row, card radius=16dp.
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Delivery-code entry (feature #4) — always reachable from help.
          HelpRow(
            icon: JameiaIcons.confirmReceipt,
            label: 'map.delivery_code'.tr(),
            onTap: () => showJameiaDialog<void>(
              context,
              barrierLabel: 'map.delivery_code'.tr(),
              pageBuilder: (ctx) =>
                  DeliveryCodeDialog(code: order.deliveryCode),
            ),
          ),
          const TrackingDivider(),
          // Rush / speed-up entry (feature #7).
          HelpRow(
            icon: JameiaIcons.urgeOrder,
            label: 'orders.speed_up_delivery'.tr(),
            onTap: () => _showSpeedUpSheet(context),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: JameiaIcons.confirmReceipt,
            label: 'orders.view_einvoice'.tr(),
            onTap: () => context.push(Routes.orderInvoice, extra: order.id),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: JameiaIcons.customerService,
            label: 'orders.get_help'.tr(),
            onTap: () => context.push(Routes.customerService),
          ),
          const TrackingDivider(),
          HelpRow(
            icon: JameiaIcons.refund,
            label: 'orders.request_refund'.tr(),
            onTap: () => context.push(Routes.orderRefund),
          ),
        ],
      ),
    );
  }
}

// ── Speed-up / rush sheet (feature #7) ────────────────────────────────────────

void _showSpeedUpSheet(BuildContext context) {
  showJameiaBottomSheet<void>(
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
                JameiaIcons.urgeOrder,
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
