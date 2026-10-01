import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/dot_sep.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_card_link.dart';
import 'assistant_thumbnail_strip.dart';

/// `order` / `order_status`: status chip, date, items and total, then
/// tracking (opened by the order's id, never its number).
class AssistantOrderCard extends StatelessWidget {
  const AssistantOrderCard({super.key, required this.block});

  final AssistantOrderBlock block;

  @override
  Widget build(BuildContext context) {
    final order = block.order;
    final title = block.isStatusUpdate || order.orderNumber.isEmpty
        ? 'assistant.order_status_title'.tr()
        : 'assistant.order_title'.tr(
            namedArgs: {'number': Formatters.isolate(order.orderNumber)},
          );
    final caption = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return AssistantCardFrame(
      title: title,
      icon: HeroIcons.receipt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wraps rather than overflows: a long status next to the date at
          // a large text size moves the date to its own line.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s4,
              children: [
                TagChip(
                  label: order.status.labelKey.tr(),
                  bg: OrderStatusPalette.background(order.status),
                  fg: OrderStatusPalette.foreground(order.status),
                ),
                if (order.createdAt != null)
                  Text(
                    Formatters.date(
                      context.locale.languageCode,
                      order.createdAt,
                    ),
                    style: caption,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (order.itemCount > 0) ...[
                Text('assistant.items'.plural(order.itemCount), style: caption),
                const DotSep(),
              ],
              PriceText(price: order.totalKd, size: AppSize.font14),
            ],
          ),
          if (order.thumbnails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            AssistantThumbnailStrip(urls: order.thumbnails),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AssistantCardLink(
              label: 'assistant.order_track'.tr(),
              onTap: () => context.push(Routes.orderTracking, extra: order.id),
            ),
          ),
        ],
      ),
    );
  }
}
