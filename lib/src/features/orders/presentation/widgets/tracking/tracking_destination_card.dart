import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_section_header.dart';
import '../../../../../core/widgets/jameia_surface_card.dart';
import 'tracking_info_row.dart';

/// Where the order goes: the frozen delivery address, or the pickup branch —
/// a section ("Deliver to" / "Pick up from") over one icon row on a hairline
/// card. Takes no space when there is nothing to show.
class TrackingDestinationCard extends StatelessWidget {
  const TrackingDestinationCard({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    // One decision for the title, the lines and the icon: no address (a
    // pickup, or a delivery order without one) shows the branch.
    final address = order.isPickup ? null : order.address;
    final String title;
    final List<String> lines;
    if (address == null) {
      title = 'orders.pick_up_from'.tr();
      final branch = order.branch?.nameFor(lc) ?? '';
      lines = [if (branch.isNotEmpty) branch];
    } else {
      title = 'orders.deliver_to'.tr();
      lines = [
        if (address.label.isNotEmpty) address.label,
        if (address.summary.isNotEmpty) address.summary,
        // Isolated, or RTL bidi drops the '+' of +965… at the far end
        // of the line and the number reads back to front.
        if (address.phone.isNotEmpty) Formatters.isolate(address.phone),
      ];
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        JameiaSectionHeader(title: title, titleStyle: AppTextStyles.groupTitle),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: JameiaSurfaceCard(
            child: TrackingInfoRow(
              icon: address == null
                  ? Icons.storefront_outlined
                  : Icons.location_on_outlined,
              lines: lines,
            ),
          ),
        ),
      ],
    );
  }
}
