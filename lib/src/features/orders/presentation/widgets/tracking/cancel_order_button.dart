import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'cancel_reason_sheet.dart';
import 'tracking_card.dart';

// ── Cancel order ──────────────────────────────────────────────────────────────

/// Destructive text row that opens [CancelReasonSheet].
/// Shown only when [JameiaOrder.isActive] (delivering or preparing).
/// Real Jameia: plain white card, centered text, Regular 14dp error-red — not a button.
class CancelOrderButton extends StatelessWidget {
  const CancelOrderButton({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => CancelReasonSheet.show(context, orderId: orderId),
        borderRadius: BorderRadius.circular(AppRadius.r3),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s16,
            horizontal: AppSpacing.s16,
          ),
          child: Center(
            child: Text(
              'orders.cancel_order'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
