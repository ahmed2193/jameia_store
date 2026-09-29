import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import 'tracking_notice_card.dart';

/// Who cancelled, why (the API's reason) and the note they left. Opens (height + fade) when a poll
/// or a cancel brings the cancellation; takes no space without one.
class TrackingCancellationNotice extends StatelessWidget {
  const TrackingCancellationNotice({super.key, this.cancellation});

  final OrderCancellationEntity? cancellation;

  @override
  Widget build(BuildContext context) {
    final cancellation = this.cancellation;
    final reasonKey = cancellation?.reason.labelKey;
    return CollapseReveal(
      visible: cancellation != null,
      child: cancellation == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s16,
                AppSpacing.gutter,
                0,
              ),
              child: TrackingNoticeCard(
                icon: Icons.cancel_outlined,
                iconColor: AppColors.error,
                title: cancellation.byCustomer
                    ? 'orders.cancelled_by_you'.tr()
                    : 'orders.cancelled_by_store'.tr(),
                titleColor: AppColors.errorDeep,
                lines: [
                  if (reasonKey != null)
                    'orders.cancellation_reason'.tr(
                      namedArgs: {'reason': reasonKey.tr()},
                    ),
                  if (cancellation.note.isNotEmpty)
                    'orders.cancellation_note'.tr(
                      namedArgs: {'note': cancellation.note},
                    ),
                ],
              ),
            ),
    );
  }
}
