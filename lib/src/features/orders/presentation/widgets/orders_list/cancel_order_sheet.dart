import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/jameia_sheet_header.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/cancel_order_request.dart';
import 'cancel_order_note_field.dart';
import 'cancel_order_sheet_insets.dart';

/// The five reasons `POST /v1/orders/{id}/cancel` accepts plus an optional
/// note; pops the [CancelOrderRequest] to send, or nothing (✕ or a barrier
/// tap). The sheet scrolls, so the open keyboard never overflows it on a
/// small phone, and it stops short of the status bar however tall its
/// content grows. Open it with [show].
class CancelOrderSheet extends StatefulWidget {
  const CancelOrderSheet({super.key, required this.orderId});

  final String orderId;

  /// Opens the sheet for [orderId] on a white rounded sheet and resolves to
  /// the request to send, or null when the customer backed out. The sheet
  /// is built once: the modal route rebuilds its page on every frame of the
  /// keyboard animation, and handing back the same widget lets that skip it.
  static Future<CancelOrderRequest?> show(
    BuildContext context, {
    required String orderId,
  }) {
    final sheet = CancelOrderSheet(orderId: orderId);
    return showJameiaBottomSheet<CancelOrderRequest>(
      context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: JameiaSheetHeader.shape,
      builder: (_) => sheet,
    );
  }

  @override
  State<CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<CancelOrderSheet> {
  CancelOrderReason _reason = CancelOrderReason.changedMind;
  final TextEditingController _note = TextEditingController();

  /// Share of the screen the sheet may take, keyboard included (the same
  /// cap as the checkout sheets).
  static const double _maxHeightFactor = 0.85;

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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
      ),
      child: CancelOrderSheetInsets(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JameiaSheetHeader(title: 'orders.cancel_title'.tr()),
                for (final (index, reason)
                    in CancelOrderReason.values.indexed) ...[
                  if (index > 0) const ThinDivider(indent: AppSpacing.gutter),
                  OptionRow(
                    key: ValueKey<CancelOrderReason>(reason),
                    title: _label(reason),
                    selected: reason == _reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
                ],
                CancelOrderNoteField(controller: _note),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter,
                    AppSpacing.section,
                    AppSpacing.gutter,
                    AppSpacing.gutter,
                  ),
                  child: AppButton(
                    label: 'orders.cancel_confirm'.tr(),
                    color: AppColors.errorDeep,
                    foreground: AppColors.white,
                    height: AppSize.s52,
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
        ),
      ),
    );
  }
}
