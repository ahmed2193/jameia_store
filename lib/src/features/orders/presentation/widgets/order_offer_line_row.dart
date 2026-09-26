import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import 'order_line_layout.dart';

/// A free product an offer added: the quantity, the name and, under it, the
/// offer that gave it (brand deep green). No price. Same [OrderLineLayout]
/// as `OrderLineRow`, so the two read as one list.
class OrderOfferLineRow extends StatelessWidget {
  const OrderOfferLineRow({super.key, required this.line});

  final OrderOfferLineEntity line;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    return OrderLineLayout(
      quantity: line.quantity,
      name: line.nameFor(lc),
      subtitle: line.offerNameFor(lc),
      subtitleColor: AppColors.brandDeep,
    );
  }
}
