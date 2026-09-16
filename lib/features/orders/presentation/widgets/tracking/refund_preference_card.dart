import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'refund_option_row.dart';
import 'tracking_card.dart';
import 'tracking_divider.dart';

// ── Refund-method preference (feature #6) ─────────────────────────────────────
//
// Static stub: lets the user pick where a refund should land. Defaults to the
// KeeTa wallet. Uses the refund-method selected/unselected glyphs where present.

class RefundPreferenceCard extends StatefulWidget {
  const RefundPreferenceCard({super.key});

  @override
  State<RefundPreferenceCard> createState() => _RefundPreferenceCardState();
}

class _RefundPreferenceCardState extends State<RefundPreferenceCard> {
  // 0 = KeeTa wallet (default), 1 = original payment method.
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Text(
              'orders.refund_preference'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          const TrackingDivider(),
          RefundOptionRow(
            label: 'orders.refund_to_wallet'.tr(),
            selected: _selected == 0,
            onTap: () => setState(() => _selected = 0),
          ),
          const TrackingDivider(),
          RefundOptionRow(
            label: 'orders.refund_to_original_payment'.tr(),
            selected: _selected == 1,
            onTap: () => setState(() => _selected = 1),
          ),
        ],
      ),
    );
  }
}
