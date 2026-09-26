import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';

/// The first [_previewLines] lines of an order ("2 × Basmati rice"), then
/// "+n more" for the rest. Bounded on purpose: a card never lays out more
/// than [_previewLines] rows, however big the order.
class OrderItemsPreview extends StatelessWidget {
  const OrderItemsPreview({super.key, required this.order});

  final OrderEntity order;

  static const int _previewLines = 2;

  /// The meta size in ink: built once, not on every card build.
  static final TextStyle _lineStyle = AppTextStyles.meta.copyWith(
    color: AppColors.primaryText,
  );

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final preview = order.lines.take(_previewLines).toList(growable: false);
    final rest = order.lines.length - preview.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in preview)
          Text(
            '${line.quantity} × ${line.nameFor(lc)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _lineStyle,
          ),
        if (rest > 0)
          Text(
            'orders.more_items'.tr(namedArgs: {'count': '$rest'}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.meta,
          ),
      ],
    );
  }
}
