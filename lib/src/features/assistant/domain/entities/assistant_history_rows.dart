import 'package:equatable/equatable.dart';

import 'assistant_conversation_entity.dart';

/// When a conversation last moved, relative to today.
enum AssistantHistoryBucket { today, yesterday, thisWeek, earlier }

/// One row of the history list: a date header or a conversation.
sealed class AssistantHistoryRow extends Equatable {
  const AssistantHistoryRow();
}

final class AssistantHistoryHeaderRow extends AssistantHistoryRow {
  const AssistantHistoryHeaderRow(this.bucket);

  final AssistantHistoryBucket bucket;

  @override
  List<Object?> get props => [bucket];
}

final class AssistantHistoryConversationRow extends AssistantHistoryRow {
  const AssistantHistoryConversationRow(this.conversation);

  final AssistantConversationEntity conversation;

  @override
  List<Object?> get props => [conversation];
}

/// Groups conversations (newest first, as the server sends them) under date
/// headers: a header before the first conversation of each bucket.
abstract final class AssistantHistoryRows {
  static const int _daysInWeek = 7;

  static List<AssistantHistoryRow> of(
    List<AssistantConversationEntity> conversations,
    DateTime now,
  ) {
    final rows = <AssistantHistoryRow>[];
    AssistantHistoryBucket? current;
    for (final conversation in conversations) {
      final bucket = bucketOf(
        conversation.lastMessageAt ?? conversation.createdAt,
        now,
      );
      if (bucket != current) {
        rows.add(AssistantHistoryHeaderRow(bucket));
        current = bucket;
      }
      rows.add(AssistantHistoryConversationRow(conversation));
    }
    return rows;
  }

  /// Calendar days in the device's time zone; an unknown time is "earlier".
  static AssistantHistoryBucket bucketOf(DateTime? at, DateTime now) {
    if (at == null) return AssistantHistoryBucket.earlier;
    final local = at.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo <= 0) return AssistantHistoryBucket.today;
    if (daysAgo == 1) return AssistantHistoryBucket.yesterday;
    if (daysAgo < _daysInWeek) return AssistantHistoryBucket.thisWeek;
    return AssistantHistoryBucket.earlier;
  }
}
