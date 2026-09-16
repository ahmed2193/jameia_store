import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/order.dart';
import 'rider_action.dart';
import 'rider_more_row.dart';
import 'tracking_card.dart';
import 'tracking_divider.dart';
import 'tracking_helpers.dart';

class RiderBar extends StatelessWidget {
  const RiderBar({super.key, required this.rider});
  final RiderEntity rider;

  @override
  Widget build(BuildContext context) {
    // Real KeeTa (acf275): avatar 40×40dp, radius=13dp, 1.5dp white border.
    // Rider name: Medium 16dp (headingMedium). Vehicle: Regular 14dp secondaryText.
    return TrackingCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppSize.r13), // acf275: r=13dp
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              KeetaAssets.deliveryDriver,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                KeetaIcons.delivery,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Rider profile enrichment — ★ rating · N reviews (dummy getters).
                Row(
                  children: [
                    const Icon(
                      KeetaIcons.star,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      '${rider.rating} · ${'orders.reviews_count'.tr(namedArgs: {'count': '${rider.reviews}'})}',
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chat (IM) action with a small red unread badge "2".
          RiderAction(
            icon: KeetaIcons.chat,
            badgeCount: 2,
            onTap: () => Navigator.pushNamed(context, Routes.imChat),
          ),
          const SizedBox(width: AppSpacing.s8),
          RiderAction(icon: KeetaIcons.phone, onTap: () {}),
          // Bundle §2.3: rider action bar is call / IM / more (icon_rider_more).
          const SizedBox(width: AppSpacing.s8),
          RiderAction(
            icon: KeetaIcons.more,
            onTap: () => _showRiderMoreSheet(context, rider),
          ),
        ],
      ),
    );
  }
}

// ── Rider "more" actions sheet (feature #3) ───────────────────────────────────

void _showRiderMoreSheet(BuildContext context, RiderEntity rider) {
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
        padding: EdgeInsetsDirectional.only(bottom: bottomPad + AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.s12,
                  bottom: AppSpacing.s8,
                ),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            RiderMoreRow(
              icon: KeetaIcons.delivery,
              label: 'orders.rider_profile'.tr(),
              onTap: () {
                Navigator.maybePop(sheetCtx);
                trackingToast(context, '${rider.name} · ${rider.rating}★');
              },
            ),
            const TrackingDivider(),
            RiderMoreRow(
              icon: KeetaIcons.alert,
              label: 'orders.block_rider'.tr(),
              destructive: true,
              onTap: () {
                Navigator.maybePop(sheetCtx);
                _confirmBlockRider(context, rider);
              },
            ),
            const TrackingDivider(),
            RiderMoreRow(
              icon: KeetaIcons.notice,
              label: 'orders.report_rider'.tr(),
              onTap: () {
                Navigator.maybePop(sheetCtx);
                trackingToast(context, 'orders.report_submitted'.tr());
              },
            ),
            const TrackingDivider(),
            RiderMoreRow(
              icon: KeetaIcons.share,
              label: 'orders.share_order'.tr(),
              onTap: () {
                Navigator.maybePop(sheetCtx);
                trackingToast(context, 'orders.order_link_copied'.tr());
              },
            ),
          ],
        ),
      );
    },
  );
}

void _confirmBlockRider(BuildContext context, RiderEntity rider) {
  showKeetaDialog<void>(
    context,
    barrierLabel: 'orders.block_rider'.tr(),
    pageBuilder: (ctx) => Center(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'orders.block_rider_question'.tr(),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'orders.block_rider_desc'.tr(namedArgs: {'name': rider.name}),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'orders.cancel'.tr(),
                        color: AppColors.smallBackground,
                        foreground: AppColors.primaryText,
                        radius: AppRadius.pill,
                        onPressed: () => Navigator.maybePop(ctx),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppButton(
                        label: 'orders.block'.tr(),
                        radius: AppRadius.pill,
                        onPressed: () {
                          Navigator.maybePop(ctx);
                          trackingToast(context, 'orders.rider_blocked'.tr());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
