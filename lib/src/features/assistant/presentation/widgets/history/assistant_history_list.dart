import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../domain/entities/assistant_conversations_feed.dart';
import '../../../domain/entities/assistant_history_rows.dart';
import '../../cubit/assistant_history_cubit.dart';
import 'assistant_history_header.dart';
import 'assistant_history_load_more_row.dart';
import 'assistant_history_tile.dart';

/// The conversations, newest first, under "Today / Yesterday / This week /
/// Earlier" headers; pull to refresh, the next page loads at the end.
class AssistantHistoryList extends StatelessWidget {
  const AssistantHistoryList({super.key, required this.feed});

  final AssistantConversationsFeed feed;

  @override
  Widget build(BuildContext context) {
    final rows = AssistantHistoryRows.of(feed.items, DateTime.now());
    final count = rows.length + (feed.hasMore ? 1 : 0);
    return BrandedRefresh(
      onRefresh: () => context.read<AssistantHistoryCubit>().refresh(),
      child: ContentClamp(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
          ),
          itemCount: count,
          itemBuilder: (_, index) {
            if (index == rows.length) {
              return const AssistantHistoryLoadMoreRow();
            }
            return switch (rows[index]) {
              AssistantHistoryHeaderRow(:final bucket) =>
                AssistantHistoryHeader(bucket: bucket),
              AssistantHistoryConversationRow(:final conversation) =>
                AssistantHistoryTile(
                  key: ValueKey<String>(conversation.id),
                  conversation: conversation,
                ),
            };
          },
        ),
      ),
    );
  }
}
