import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/order.dart';
import 'map_app_row.dart';
import 'tracking_divider.dart';
import 'tracking_helpers.dart';

class EtaBubble extends StatelessWidget {
  const EtaBubble({super.key, required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.statusStep >= 5;
    // Real KeeTa metrics (a5883b / e8cf8d):
    //   height=46dp, radius=16dp, h-padding=10dp, shadow=0 0 7.5dp #95959514
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3), // 16dp
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withValues(
              alpha: 0.08,
            ), // #95959514 ≈ 8%
            blurRadius: 7.5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Yellow circle icon — KeeTa uses the brand primary circle
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              KeetaIcons.deliveryTime,
              size: 16,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivered
                      ? 'map.delivered'.tr()
                      : 'map.estimated_arrival'.tr(),
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
                // Real ETA from the dummy backend getter (order.etaMinutes).
                // Pops on each live update as the simulation advances the step.
                PopScale(
                  popKey: delivered ? 'done' : order.etaMinutes,
                  child: Text(
                    delivered
                        ? 'map.order_completed'.tr()
                        : 'map.eta_minutes'.tr(args: ['${order.etaMinutes}']),
                    style: AppTextStyles.subheadingMedium.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // "Open in Maps" affordance — opens the map-app picker dialog (no real
          // launch; SnackBar feedback only).
          if (!delivered) ...[
            GestureDetector(
              onTap: () => _showMapPickerDialog(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.smallBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  KeetaAssets.navigationIcon,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    KeetaIcons.location,
                    size: 16,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          Image.asset(
            KeetaAssets.onTimePromiseLogo,
            height: 20,
            errorBuilder: (_, _, _) => const Icon(
              KeetaIcons.confirm,
              size: 18,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map-app picker (feature #9) ───────────────────────────────────────────────
//
// Static stub: lists "Google Maps" / "Apple Maps" and shows a SnackBar instead
// of a real deep-link launch (no url_launcher per constraints).

void _showMapPickerDialog(BuildContext context) {
  showKeetaDialog<void>(
    context,
    barrierLabel: 'map.open_in_maps'.tr(),
    pageBuilder: (ctx) => Center(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Text(
                  'map.open_in_maps'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              const TrackingDivider(),
              MapAppRow(
                label: 'map.google'.tr(),
                onTap: () {
                  Navigator.maybePop(ctx);
                  trackingToast(context, 'orders.opening_google_maps'.tr());
                },
              ),
              const TrackingDivider(),
              MapAppRow(
                label: 'map.apple'.tr(),
                onTap: () {
                  Navigator.maybePop(ctx);
                  trackingToast(context, 'orders.opening_apple_maps'.tr());
                },
              ),
              const TrackingDivider(),
              MapAppRow(
                label: 'common.cancel'.tr(),
                emphasize: false,
                center: true,
                onTap: () => Navigator.maybePop(ctx),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
