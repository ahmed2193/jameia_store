import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../domain/entities/cancel_order_request.dart';

/// The five reasons `POST /v1/orders/{id}/cancel` accepts plus an optional
/// note; pops the [CancelOrderRequest] to send, or nothing.
class CancelOrderSheet extends StatefulWidget {
  const CancelOrderSheet({super.key, required this.orderId});

  final String orderId;

  @override
  State<CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<CancelOrderSheet> {
  CancelOrderReason _reason = CancelOrderReason.changedMind;
  final TextEditingController _note = TextEditingController();

  static const int _noteLines = 2;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(CancelOrderReason reason) => switch (reason) {
    CancelOrderReason.changedMind => 'orders.cancel_reason_changed_mind'.tr(),
    CancelOrderReason.orderedByMistake =>
      'orders.cancel_reason_ordered_by_mistake'.tr(),
    CancelOrderReason.tooSlow => 'orders.cancel_reason_too_slow'.tr(),
    CancelOrderReason.foundElsewhere =>
      'orders.cancel_reason_found_elsewhere'.tr(),
    CancelOrderReason.other => 'orders.cancel_reason_other'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text(
                'orders.cancel_title'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
            for (final reason in CancelOrderReason.values)
              OptionRow(
                key: ValueKey<CancelOrderReason>(reason),
                title: _label(reason),
                selected: reason == _reason,
                onTap: () => setState(() => _reason = reason),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: TextField(
                controller: _note,
                maxLength: CancelOrderRequest.maxNoteLength,
                maxLines: _noteLines,
                decoration: InputDecoration(
                  hintText: 'orders.cancel_note_hint'.tr(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: AppButton(
                label: 'orders.cancel_confirm'.tr(),
                color: AppColors.error,
                foreground: AppColors.white,
                onPressed: () => context.pop(
                  CancelOrderRequest(
                    orderId: widget.orderId,
                    reason: _reason,
                    note: _note.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
