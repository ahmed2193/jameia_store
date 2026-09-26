import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../domain/entities/orders_feed.dart';
import '../../cubit/orders_cubit.dart';
import 'order_card.dart';
import 'orders_empty_view.dart';
import 'orders_load_more_row.dart';

/// Every order the customer has, newest first — running, done and cancelled
/// in one list, each row wearing its own status. Pull to refresh; the next
/// page starts when the end comes into reach.
///
/// The cards of the first screenful cascade in once, when the list first
/// shows; cards built later (scrolling, the next page, a refresh — also the
/// first order of a history that was empty) appear as they are. When the
/// feed changes only the cards whose order changed rebuild.
class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  /// How close to the end starts the next page.
  static const double _prefetch = AppSize.s200;
  static const String _sentinelKey = 'load-more';

  /// One card per order, handed back while its order is unchanged, so the
  /// framework skips it: the next page, one row refreshed from tracking or a
  /// cancel rebuilds only the card whose order really changed.
  final Map<String, OrderCard> _cards = <String, OrderCard>{};

  @override
  Widget build(BuildContext context) {
    // The whole feed, compared by value: a refresh (or a row refreshed from
    // tracking) that changed nothing rebuilds nothing below. It is also why
    // the id → index map below is only built when the feed really changed.
    final feed = context.select<OrdersCubit, OrdersFeed>(
      (cubit) => cubit.state.feed,
    );
    final orders = feed.orders;
    final hasMore = feed.hasMore;
    final indexById = <String, int>{
      for (var index = 0; index < orders.length; index++)
        orders[index].id: index,
    };
    _cards.removeWhere((id, _) => !indexById.containsKey(id));
    final cubit = context.read<OrdersCubit>();
    return ContentClamp(
      // Above the empty / list switch: the scope is open only in the frame
      // the list first shows, never again when orders arrive on a refresh.
      child: EntranceCascade(
        child: BrandedRefresh(
          onRefresh: cubit.refresh,
          child: orders.isEmpty
              ? const OrdersEmptyView()
              : NotificationListener<ScrollEndNotification>(
                  // Paging is an event (the customer reached the end), never
                  // a side effect of building a row.
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
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.gutter,
                      AppSpacing.s16,
                      AppSpacing.gutter,
                      AppSpacing.section,
                    ),
                    itemCount: orders.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s12),
                    // Rows and the sentinel keep their element when a new page
                    // shifts their index — without this the sentinel is
                    // rebuilt from scratch after every page and asks for the
                    // next one. The key sits on the outermost item widget.
                    findItemIndexCallback: (key) {
                      if (key is! ValueKey<String>) return null;
                      if (key.value == _sentinelKey) return orders.length;
                      return indexById[key.value];
                    },
                    itemBuilder: (_, index) {
                      if (index >= orders.length) {
                        return const OrdersLoadMoreRow(
                          key: ValueKey<String>(_sentinelKey),
                        );
                      }
                      final order = orders[index];
                      var card = _cards[order.id];
                      if (card == null || card.order != order) {
                        card = _cards[order.id] = OrderCard(order: order);
                      }
                      return EntranceCascadeItem(
                        key: ValueKey<String>(order.id),
                        index: index,
                        child: card,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
