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
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/orders_cubit.dart';
import 'order_actions.dart';
import 'order_status_chip.dart';

/// One order in the list: its status first (chip, plus a coloured edge down
/// the card), then the number and date, a two-line preview of the items, the
/// total, and the actions its status allows.
///
/// The list is not split by status any more, so the card is where a customer
/// reads whether this order is on its way, done or cancelled — hence the
/// status leads it instead of trailing the order number.
///
/// Tapping opens the tracking page and refreshes this row on the way back.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderEntity order;

  static const int _previewLines = 2;

  /// Width of the status-coloured edge.
  static const double _edge = AppSize.s4;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<OrdersCubit>();
    await context.push(Routes.orderTracking, extra: order.id);
    if (context.mounted) await cubit.refreshOrder(order.id);
  }

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final preview = order.lines.take(_previewLines).toList(growable: false);
    final rest = order.lines.length - preview.length;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The status, readable before a single word: a coloured edge down
            // the whole card, directional so it stays on the leading side.
            Container(
              width: _edge,
              color: OrderStatusPalette.foreground(order.status),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        OrderStatusChip(status: order.status),
                        const Spacer(),
                        Text(
                          Formatters.dateTime(lc, order.createdAt),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'orders.order_no'.tr(
                        namedArgs: {
                          'number': Formatters.isolate(order.orderNumber),
                        },
                      ),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    for (final line in preview)
                      Text(
                        '${line.quantity} × ${line.nameFor(lc)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    if (rest > 0)
                      Text(
                        'orders.more_items'.tr(namedArgs: {'count': '$rest'}),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s8),
                    Row(
                      children: [
                        Text(
                          'orders.item_count'.tr(
                            namedArgs: {'count': '${order.itemCount}'},
                          ),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Formatters.price(order.totalKd),
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    OrderActions(order: order),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
