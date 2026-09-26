import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import 'tracking_notice_card.dart';

/// What changed while the order was picked: unavailable lines and
/// substitutions. Opens (height + fade) when a poll brings the first change;
/// takes no space while nothing changed.
class TrackingPickingNotice extends StatelessWidget {
  const TrackingPickingNotice({super.key, this.picking});

  final OrderPickingEntity? picking;

  @override
  Widget build(BuildContext context) {
    final picking = this.picking;
    final changes = picking != null && picking.hasChanges ? picking : null;
    final lc = context.locale.languageCode;
    return CollapseReveal(
      visible: changes != null,
      child: changes == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                0,
              ),
              child: TrackingNoticeCard(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.warn,
                title: 'orders.picking_changes'.tr(),
                lines: [
                  if (changes.unavailableLineKeys.isNotEmpty)
                    'orders.unavailable_items'.tr(
                      namedArgs: {
                        'count': '${changes.unavailableLineKeys.length}',
                      },
                    ),
                  for (final row in changes.substitutions)
                    'orders.substituted_item'.tr(
                      namedArgs: {'name': row.productNameFor(lc)},
                    ),
                ],
              ),
            ),
    );
  }
}
