import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/hero_tag.dart';

/// The status tag of an order: green wash while it is on its way, grey once
/// delivered, red when cancelled or failed. With the list no longer split
/// into status tabs, this is what tells the customer where an order stands,
/// so it leads its card rather than trailing it. A status that moves while
/// the card is on screen (back from tracking, a cancel) cross-fades.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return FadeThroughSwitcher(
      stateKey: status,
      alignment: AlignmentDirectional.centerStart,
      child: HeroTag(
        label: status.labelKey.tr(),
        tone: switch (status.group) {
          OrderStatusGroup.inProgress => HeroTagTone.brandSoft,
          OrderStatusGroup.completed => HeroTagTone.neutral,
          OrderStatusGroup.cancelled => HeroTagTone.error,
        },
      ),
    );
  }
}
