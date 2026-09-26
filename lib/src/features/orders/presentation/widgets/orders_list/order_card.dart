import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/orders_cubit.dart';
import 'order_actions.dart';
import 'order_items_preview.dart';
import 'order_status_chip.dart';
import 'order_total_row.dart';

/// One order in the list, on a white hairline card: its status first (the
/// tag, plus a coloured edge down the card), then the number and date, a
/// two-line preview of the items, the item count against the total, and the
/// actions its status allows.
///
/// The list is not split by status any more, so this card is where a customer
/// reads whether an order is on its way, done or cancelled — hence the status
/// leads it instead of trailing the order number.
///
/// Tapping opens the tracking page and refreshes this row on the way back.
/// The card gives a little under the finger; when its actions change (a
/// cancel went through, the order was delivered) it eases to its new height.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderEntity order;

  /// Width of the status-coloured edge.
  static const double _edge = AppSize.s4;

  /// Press depth of a full-width card (a tile gives 0.97).
  static const double _pressedScale = 0.98;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<OrdersCubit>();
    await context.push(Routes.orderTracking, extra: order.id);
    if (context.mounted) await cubit.refreshOrder(order.id);
  }

  @override
  Widget build(BuildContext context) {
    final date = Formatters.dateTime(
      context.locale.languageCode,
      order.createdAt,
    );
    // Passive: the InkWell keeps the tap and the ripple; the press lets go
    // as soon as the finger starts scrolling the list.
    return PressScale(
      pressedScale: _pressedScale,
      child: Material(
        color: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.media)),
          side: BorderSide(color: AppColors.divider),
        ),
        // The card's one clip: nothing inside it clips again.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Container(
            // The status, readable before a single word: a coloured edge down
            // the leading side. A border, not a stretched child — inside a
            // sliver a stretching row has no height to stretch to.
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: OrderStatusPalette.foreground(order.status),
                  width: _edge,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OrderStatusChip(status: order.status),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: AppSize.s24,
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'orders.order_no'.tr(
                    namedArgs: {
                      'number': Formatters.isolate(order.orderNumber),
                    },
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.itemTitleStrong,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.meta,
                  ),
                ],
                const SizedBox(height: AppSpacing.s8),
                OrderItemsPreview(order: order),
                const SizedBox(height: AppSpacing.s12),
                OrderTotalRow(order: order),
                // Grows unclipped: the card's own clip already bounds it, so
                // no second clip layer is pushed while the actions open.
                AnimatedSize(
                  duration: MotionGuard.duration(context, AppMotion.medium),
                  curve: AppMotion.signature,
                  alignment: AlignmentDirectional.topCenter,
                  clipBehavior: Clip.none,
                  child: OrderActions(order: order),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
