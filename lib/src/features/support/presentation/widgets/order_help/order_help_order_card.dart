import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_line_thumb.dart';
import '../../../../../core/widgets/hero_surface_card.dart';

/// Which order this is about, at the top of the help page: the first
/// item's photo, the order number, and when it was placed, how many items
/// and what it came to.
class OrderHelpOrderCard extends StatelessWidget {
  const OrderHelpOrderCard({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final first = order.lines.firstOrNull;
    final placed = Formatters.dateTime(lc, order.createdAt);
    final meta = [
      if (placed.isNotEmpty) placed,
      'support.help_item_count'.tr(namedArgs: {'count': '${order.itemCount}'}),
      Formatters.price(order.totalKd),
    ].join(Formatters.middot);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSurfaceCard(
        child: Row(
          children: [
            if (first != null) ...[
              HeroLineThumb(url: first.image, size: AppSize.s48),
              const SizedBox(width: AppSpacing.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'support.help_order_number'.tr(
                      namedArgs: {
                        'number': Formatters.isolate(order.orderNumber),
                      },
                    ),
                    style: AppTextStyles.itemTitleStrong,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(meta, style: AppTextStyles.meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
