import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'delivery_code_dialog.dart';
import 'tracking_card.dart';

// ── Contactless delivery code ─────────────────────────────────────────────────
//
// Real Jameia shows a delivery-code popup (`delivery_code_popup_*`,
// `delivery_code_icon`, `delivery_code_info`) for contactless handoff: a short
// code the rider confirms on delivery. The static clone derives a stable 4-digit
// code from the order id (no model/API change) and surfaces it as a tappable
// card that opens a centered dialog (8dp radius, scale-in via showJameiaDialog).

class DeliveryCodeCard extends StatelessWidget {
  const DeliveryCodeCard({super.key, required this.code});

  /// Contactless handoff code from the dummy backend (order.deliveryCode).
  final String code;

  @override
  Widget build(BuildContext context) {
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDeliveryCodeDialog(context, code),
        borderRadius: BorderRadius.circular(AppRadius.r3),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          child: Row(
            children: [
              // Delivery-code icon (delivery_code_icon_in3fn9.webp).
              Image.asset(
                JameiaAssets.deliveryCodeIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  JameiaIcons.confirmReceipt,
                  size: 22,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  'map.delivery_code'.tr(),
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              // Mono-ish code chip.
              Text(
                code,
                style: AppTextStyles.subheadingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                JameiaIcons.arrowRight,
                size: 16,
                color: AppColors.tertiaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryCodeDialog(BuildContext context, String code) {
    showJameiaDialog<void>(
      context,
      barrierLabel: 'map.delivery_code'.tr(),
      pageBuilder: (ctx) => DeliveryCodeDialog(code: code),
    );
  }
}
