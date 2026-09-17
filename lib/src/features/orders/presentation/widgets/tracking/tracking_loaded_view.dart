import 'package:flutter/material.dart';

import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_address.dart';
import 'cancel_order_button.dart';
import 'delivery_address_card.dart';
import 'delivery_code_card.dart';
import 'help_refund_card.dart';
import 'map_hero.dart';
import 'on_time_promise_card.dart';
import 'order_summary_card.dart';
import 'progress_stepper.dart';
import 'refund_preference_card.dart';
import 'rider_bar.dart';
import 'status_header.dart';
import 'tracking_card_gap.dart';

class TrackingLoadedView extends StatelessWidget {
  const TrackingLoadedView({
    super.key,
    required this.order,
    required this.address,
  });

  final OrderEntity order;
  final OrderAddressEntity address;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Live-map placeholder with rider/shop/user markers + floating back button.
        SliverToBoxAdapter(child: MapHero(order: order)),
        SliverToBoxAdapter(
          child: ContentClamp(
            child: Column(
              children: [
                StatusHeader(order: order),
                const TrackingCardGap(),
                ProgressStepper(step: order.statusStep),
                // On-time delivery promise card (Jameia `onTimePromise*` family).
                const TrackingCardGap(),
                const OnTimePromiseCard(),
                if (order.rider != null) ...[
                  const TrackingCardGap(),
                  RiderBar(rider: order.rider!),
                ],
                // Contactless delivery-code entry — appears once the rider has
                // picked up the order (statusStep >= 3) and before delivery.
                if (order.statusStep >= 3 && order.statusStep < 5) ...[
                  const TrackingCardGap(),
                  DeliveryCodeCard(code: order.deliveryCode),
                ],
                const TrackingCardGap(),
                OrderSummaryCard(order: order),
                const TrackingCardGap(),
                // Refund-method preference (feature #6).
                const TrackingCardGap(),
                const RefundPreferenceCard(),
                const TrackingCardGap(),
                DeliveryAddressCard(address: address),
                const TrackingCardGap(),
                HelpRefundCard(order: order),
                if (order.isActive) ...[
                  const TrackingCardGap(),
                  CancelOrderButton(orderId: order.id),
                ],
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
