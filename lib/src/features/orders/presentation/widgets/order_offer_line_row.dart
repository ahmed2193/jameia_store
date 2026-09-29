import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import 'order_line_layout.dart';

/// A free product an offer added: the photo (when [showThumb]), the
/// quantity, the name and, under it, the offer that gave it (brand deep
/// green), with "Free" where a paid line has its price. Same
/// [OrderLineLayout] as `OrderLineRow`, so the two read as one list.
class OrderOfferLineRow extends StatelessWidget {
  const OrderOfferLineRow({
    super.key,
    required this.line,
    this.showThumb = false,
  });

  final OrderOfferLineEntity line;
  final bool showThumb;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    return OrderLineLayout(
      quantity: line.quantity,
      name: line.nameFor(lc),
      subtitle: line.offerNameFor(lc),
      subtitleColor: AppColors.brandDeep,
      thumbUrl: showThumb ? line.image : null,
      trailing: Text(
        'orders.free'.tr(),
        style: AppTextStyles.label.copyWith(color: AppColors.brandDeep),
      ),
    );
  }
}
