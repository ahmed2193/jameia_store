import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/thin_divider.dart';
import 'tracking_person_row.dart';

/// Who is handling the order, as the API names them: the picker once picking
/// started, the driver once the order left the store — each with a "Now" tag
/// while it is their turn. No call or chat buttons: the API gives no way to
/// reach them (help goes through "Get help"). Opens when the first name
/// arrives with a poll; not shown on a cancelled order.
class TrackingPeopleCard extends StatelessWidget {
  const TrackingPeopleCard({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final picker = order.picking?.pickerName ?? '';
    final driver = order.delivery?.driverName ?? '';
    final shown =
        order.status != OrderStatus.cancelled &&
        (picker.isNotEmpty || driver.isNotEmpty);
    return CollapseReveal(
      visible: shown,
      child: !shown
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s16,
                AppSpacing.gutter,
                0,
              ),
              child: HeroSurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (picker.isNotEmpty)
                      TrackingPersonRow(
                        name: picker,
                        roleKey: 'orders.person_picker',
                        roleIcon: HeroIcons.cart,
                        active: order.status == OrderStatus.picking,
                      ),
                    if (picker.isNotEmpty && driver.isNotEmpty)
                      const Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          vertical: AppSpacing.s12,
                        ),
                        child: ThinDivider(),
                      ),
                    if (driver.isNotEmpty)
                      TrackingPersonRow(
                        name: driver,
                        roleKey: 'orders.person_driver',
                        roleIcon: HeroIcons.delivery,
                        active: order.status == OrderStatus.outForDelivery,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
