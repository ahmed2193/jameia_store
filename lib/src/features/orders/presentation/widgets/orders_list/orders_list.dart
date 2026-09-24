import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/empty_state_view.dart';
import '../../cubit/orders_cubit.dart';
import 'order_card.dart';
import 'orders_load_more_row.dart';

/// Every order the customer has, newest first — running, done and cancelled
/// in one list, each row wearing its own status. Pull to refresh; the next
/// page starts when the end comes into reach.
class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  /// How close to the end starts the next page.
  static const double _prefetch = AppSize.s200;
  static const String _sentinelKey = 'load-more';

  @override
  Widget build(BuildContext context) {
    final orders = context.select<OrdersCubit, List<OrderEntity>>(
      (cubit) => cubit.state.feed.orders,
    );
    final hasMore = context.select<OrdersCubit, bool>(
      (cubit) => cubit.state.feed.hasMore,
    );
    final indexById = <String, int>{
      for (var index = 0; index < orders.length; index++)
        orders[index].id: index,
    };
    final cubit = context.read<OrdersCubit>();
    return BrandedRefresh(
      onRefresh: cubit.refresh,
      child: orders.isEmpty
          ? ListView(
              children: [
                EmptyStateView(
                  message: 'orders.empty'.tr(),
                  icon: JameiaIcons.orders,
                ),
              ],
            )
          : NotificationListener<ScrollEndNotification>(
              // Paging is an event (the customer reached the end), never a
              // side effect of building a row.
              onNotification: (notification) {
                final metrics = notification.metrics;
                if (hasMore &&
                    metrics.axis == Axis.vertical &&
                    metrics.pixels >= metrics.maxScrollExtent - _prefetch) {
                  cubit.loadMore();
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s12),
                itemCount: orders.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                // Rows and the sentinel keep their element when a new page
                // shifts their index — without this the sentinel is rebuilt
                // from scratch after every page and asks for the next one.
                findItemIndexCallback: (key) {
                  if (key is! ValueKey<String>) return null;
                  if (key.value == _sentinelKey) return orders.length;
                  return indexById[key.value];
                },
                itemBuilder: (_, index) => index >= orders.length
                    ? const OrdersLoadMoreRow(
                        key: ValueKey<String>(_sentinelKey),
                      )
                    : OrderCard(
                        key: ValueKey<String>(orders[index].id),
                        order: orders[index],
                      ),
              ),
            ),
    );
  }
}
