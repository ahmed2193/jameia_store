import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import '../../../../core/widgets/hero_money_text.dart';
import 'order_line_layout.dart';

/// One ordered line: the quantity (`2×`), the name and variant, and the line
/// total.
class OrderLineRow extends StatelessWidget {
  const OrderLineRow({super.key, required this.line});

  final OrderLineEntity line;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    return OrderLineLayout(
      quantity: line.quantity,
      name: line.nameFor(lc),
      subtitle: line.variantNameFor(lc),
      trailing: HeroMoneyText(
        kd: line.lineTotalKd,
        style: AppTextStyles.itemTitle,
      ),
    );
  }
}
