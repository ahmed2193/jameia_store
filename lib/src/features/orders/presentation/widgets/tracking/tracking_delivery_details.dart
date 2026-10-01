import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/address_label.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/address_label_icon.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_section_header.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/thin_divider.dart';
import 'tracking_info_row.dart';

/// "Delivery details" (or "Pickup details"): where the order goes as the
/// order froze it — the address (label, lines, phone) or the pickup branch
/// — how it was booked (as soon as possible, express, or the booked
/// window), and the customer's delivery instructions. One hairline card of
/// icon rows; a fact the order does not have takes no row.
class TrackingDeliveryDetails extends StatelessWidget {
  const TrackingDeliveryDetails({super.key, required this.order});

  final OrderEntity order;

  String _timing(String languageCode) {
    final slot = order.deliverySlot;
    if (slot != null) {
      final day = slot.day;
      return 'orders.slot_window'.tr(
        namedArgs: {
          'date': day == null ? slot.date : Formatters.date(languageCode, day),
          'start': Formatters.isolate(slot.start),
          'end': Formatters.isolate(slot.end),
        },
      );
    }
    if (order.isPickup) return '';
    return order.express
        ? 'orders.delivery_express'.tr()
        : 'orders.delivery_asap'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final address = order.isPickup ? null : order.address;
    final List<String> place;
    if (address == null) {
      final branch = order.branch?.nameFor(lc) ?? '';
      place = [if (branch.isNotEmpty) branch];
    } else {
      place = [
        if (address.label.isNotEmpty) address.label,
        if (address.summary.isNotEmpty) address.summary,
        // Isolated, or RTL bidi drops the '+' of +965… at the far end of
        // the line and the number reads back to front.
        if (address.phone.isNotEmpty) Formatters.isolate(address.phone),
      ];
    }
    final timing = _timing(lc);
    final notes = address?.notes ?? '';
    final rows = <Widget>[
      if (place.isNotEmpty)
        TrackingInfoRow(
          icon: HeroIcons.store,
          // The destination wears its tag's glyph (home, office …).
          leading: address == null
              ? null
              : AddressLabelIcon(
                  label: AddressLabel.fromWire(address.label),
                  size: AppSize.s24,
                ),
          lines: place,
        ),
      if (timing.isNotEmpty)
        TrackingInfoRow(
          leading: order.express && order.deliverySlot == null
              ? const HeroSvgGlyph.art(
                  HeroAssets.checkoutExpressBolt,
                  size: AppSize.s24,
                )
              : const HeroIcon(
                  HeroIcons.clock,
                  size: AppSize.s24,
                  color: AppColors.primaryText,
                ),
          lines: [
            timing,
            if (order.deliverySlot != null) 'orders.delivery_scheduled'.tr(),
          ],
        ),
      if (notes.isNotEmpty)
        TrackingInfoRow(
          icon: HeroIcons.megaphone,
          lines: [notes, 'orders.delivery_instructions'.tr()],
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSectionHeader(
          title:
              (order.isPickup
                      ? 'orders.pickup_details'
                      : 'orders.delivery_details')
                  .tr(),
          titleStyle: AppTextStyles.groupTitle,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: HeroSurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.s12,
                      ),
                      child: ThinDivider(),
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
