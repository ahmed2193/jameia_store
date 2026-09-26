import 'package:equatable/equatable.dart';

import 'assistant_conversation_entity.dart';

/// The history list as the cubit holds it: the pages loaded so far plus the
/// server's cursor. Sorted by `lastMessageAt`, newest first, as the backend
/// sends it. Every mutation returns a new feed.
class AssistantConversationsFeed extends Equatable {
  const AssistantConversationsFeed({
    this.items = const <AssistantConversationEntity>[],
    this.page = 0,
    this.hasMore = false,
    this.total = 0,
  });

  static const AssistantConversationsFeed empty = AssistantConversationsFeed();

  final List<AssistantConversationEntity> items;

  /// Last page loaded (1-based); `0` before the first load.
  final int page;
  final bool hasMore;
  final int total;

  bool get isEmpty => items.isEmpty;

  /// The newest thread, when it still takes messages ("Continue your last
  /// chat").
  AssistantConversationEntity? get resumable {
    if (items.isEmpty) return null;
    final latest = items.first;
    return latest.isActive ? latest : null;
  }

  /// Appends [next] (the following page), skipping ids already listed, and
  /// takes its cursor.
  AssistantConversationsFeed merge(AssistantConversationsFeed next) {
    final known = {for (final item in items) item.id};
    return AssistantConversationsFeed(
      items: [
        ...items,
        ...next.items.where((item) => !known.contains(item.id)),
      ],
      page: next.page,
      hasMore: next.hasMore,
      total: next.total,
    );
  }

  @override
  List<Object?> get props => [items, page, hasMore, total];
}
