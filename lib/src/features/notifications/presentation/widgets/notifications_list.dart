import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../domain/entities/notifications_feed.dart';
import '../cubit/notifications_cubit.dart';
import 'notification_tile.dart';
import 'notifications_load_more_row.dart';

/// The loaded pages as a pull-to-refresh list; the last slot is the
/// load-more sentinel while the server has more.
class NotificationsList extends StatelessWidget {
  const NotificationsList({super.key, required this.feed});

  final NotificationsFeed feed;

  @override
  Widget build(BuildContext context) {
    final items = feed.items;
    final count = items.length + (feed.hasMore ? 1 : 0);
    // Rows are keyed by notification id so a live prepend (which shifts every
    // index) keeps each row element instead of rebuilding them all.
    final indexById = <String, int>{
      for (var index = 0; index < items.length; index++) items[index].id: index,
    };
    return BrandedRefresh(
      onRefresh: () => context.read<NotificationsCubit>().refresh(),
      child: ContentClamp(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
          ),
          itemCount: count,
          findChildIndexCallback: (key) =>
              key is ValueKey<String> ? indexById[key.value] : null,
          // `ListView.builder` already gives every child a RepaintBoundary.
          itemBuilder: (_, index) {
            if (index == items.length) return const NotificationsLoadMoreRow();
            final item = items[index];
            return Column(
              key: ValueKey<String>(item.id),
              mainAxisSize: MainAxisSize.min,
              children: [
                NotificationTile(notification: item),
                const ThinDivider(indent: AppSpacing.s16),
              ],
            );
          },
        ),
      ),
    );
  }
}
