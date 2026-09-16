import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common.dart';
import '../../cubit/orders_cubit.dart';

// ── Cancel-order bottom sheet ─────────────────────────────────────────────────

enum _CancelReason {
  mistake,
  tooSlow,
  cheaper,
  other;

  String get label => switch (this) {
    _CancelReason.mistake => 'orders.reason_mistake'.tr(),
    _CancelReason.tooSlow => 'orders.reason_too_slow'.tr(),
    _CancelReason.cheaper => 'orders.reason_cheaper'.tr(),
    _CancelReason.other => 'orders.reason_other'.tr(),
  };
}

class CancelOrderSheet extends StatefulWidget {
  const CancelOrderSheet({super.key, required this.orderId});

  final String orderId;

  @override
  State<CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<CancelOrderSheet> {
  _CancelReason? _selected;

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    // Dispatch the cancel through the list cubit (CancelOrderUseCase). Offline
    // this is an accepted no-op that reloads the list, then the sheet closes.
    context.read<OrdersCubit>().cancel(widget.orderId, reason: selected.label);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPad + AppSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
            child: Center(
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
          const SizedBox(height: AppSpacing.s16),
          // ── Title ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            child: Text(
              'orders.cancel_order'.tr(),
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            child: Text(
              'orders.select_a_reason'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          const ThinDivider(),
          // ── Radio list ──────────────────────────────────────────────────
          RadioGroup<_CancelReason>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final reason in _CancelReason.values)
                  InkWell(
                    onTap: () => setState(() => _selected = reason),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.pageMargin,
                        vertical: AppSpacing.s12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason.label,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                          Radio<_CancelReason>(
                            value: reason,
                            activeColor: AppColors.primaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s16),
          // ── Confirm button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            child: FilledButton(
              onPressed: _selected != null ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
                foregroundColor: AppColors.brandForeground,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r1),
                ),
              ),
              child: Text(
                'orders.confirm'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
