import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'reason_tile.dart';
import 'tracking_divider.dart';

// ── Cancel-reason bottom sheet ────────────────────────────────────────────────

/// Cancel-reason radio list modal bottom sheet.
///
/// Mirrors the KeeTa `mach_pro_sailor_c_cancel_order` flow: a list of
/// pre-defined reason options, one selectable at a time, with a "Confirm"
/// button that becomes enabled once a reason is chosen.
class CancelReasonSheet extends StatefulWidget {
  const CancelReasonSheet({super.key, required this.orderId});
  final String orderId;

  /// Convenience launcher — uses [showModalBottomSheet] so the sheet is
  /// correctly anchored to the nearest [Navigator].
  static Future<void> show(BuildContext context, {required String orderId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => CancelReasonSheet(orderId: orderId),
    );
  }

  @override
  State<CancelReasonSheet> createState() => _CancelReasonSheetState();
}

// Cancel-reason values are translation keys resolved via `.tr()` where each row
// is rendered; they also double as the selected-reason identity.
const List<String> _kCancelReasons = [
  'orders.cancel_reason_mistake',
  'orders.cancel_reason_change',
  'orders.cancel_reason_wait',
  'orders.cancel_reason_price',
  'orders.reason_other',
];

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPad + AppSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle
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
          // Title row
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'orders.why_cancelling'.tr(),
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(
                    KeetaIcons.close,
                    size: 20,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const TrackingDivider(),
          // Reason radio list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kCancelReasons.length,
            separatorBuilder: (_, _) => const TrackingDivider(),
            itemBuilder: (context, index) {
              final reason = _kCancelReasons[index];
              return ReasonTile(
                reason: reason,
                selected: _selected == reason,
                onTap: () => setState(() => _selected = reason),
              );
            },
          ),
          const TrackingDivider(),
          // Confirm button
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s16,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _selected != null
                      ? AppColors.primary
                      : AppColors.smallBackground,
                  foregroundColor: _selected != null
                      ? AppColors.black
                      : AppColors.disabledText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpacing.s14,
                  ),
                ),
                onPressed: _selected == null
                    ? null
                    : () {
                        // Dismiss the sheet — in a real integration this
                        // would dispatch a CancelOrderCubit event with
                        // (widget.orderId, _selected!).
                        Navigator.maybePop(context);
                      },
                child: Text(
                  'orders.confirm_cancellation'.tr(),
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
