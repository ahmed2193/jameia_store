import 'package:equatable/equatable.dart';

import 'notification_entity.dart';

/// The inbox as the cubit holds it: the pages loaded so far plus the server's
/// pagination cursor and its GLOBAL unread counter (`unreadCount` counts every
/// unread notification, not only the loaded ones — so the helpers below move
/// it by deltas instead of recounting [items]).
///
/// Every mutation returns a new feed; the cubit only sequences calls.
class NotificationsFeed extends Equatable {
  const NotificationsFeed({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.total = 0,
    this.unreadCount = 0,
  });

  static const NotificationsFeed empty = NotificationsFeed();

  /// Newest first, as the backend sorts them.
  final List<NotificationEntity> items;

  /// Last page loaded (1-based); `0` before the first load.
  final int page;
  final bool hasMore;
  final int total;
  final int unreadCount;

  bool get isEmpty => items.isEmpty;
  bool get hasUnread => unreadCount > 0;

  NotificationEntity? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Appends [next] (the following page) below the loaded items, skipping ids
  /// already present (a live prepend can shift the server's pages), and takes
  /// the cursor + counters from [next] since they are the fresher truth.
  NotificationsFeed merge(NotificationsFeed next) {
    final known = items.map((item) => item.id).toSet();
    return NotificationsFeed(
      items: [
        ...items,
        ...next.items.where((item) => !known.contains(item.id)),
      ],
      page: next.page,
      hasMore: next.hasMore,
      total: next.total,
      unreadCount: next.unreadCount,
    );
  }

  /// A live notification: inserted on top, or replacing its earlier copy when
  /// the same id already arrived through a page load.
  NotificationsFeed prepend(NotificationEntity notification) {
    if (byId(notification.id) != null) return replace(notification);
    return _copy(
      items: [notification, ...items],
      total: total + 1,
      unreadCount: notification.isRead ? unreadCount : unreadCount + 1,
    );
  }

  /// Swaps the item with the same id (server-confirmed copy), moving the
  /// unread counter when its read status changed. Unknown ids are ignored.
  NotificationsFeed replace(NotificationEntity notification) {
    final current = byId(notification.id);
    if (current == null) return this;
    var unread = unreadCount;
    if (current.isUnread && notification.isRead) unread -= 1;
    if (current.isRead && notification.isUnread) unread += 1;
    return _copy(
      items: [
        for (final item in items)
          if (item.id == notification.id) notification else item,
      ],
      unreadCount: unread < 0 ? 0 : unread,
    );
  }

  /// Optimistic local read; no-op when unknown or already read.
  NotificationsFeed markRead(String id) {
    final current = byId(id);
    if (current == null || current.isRead) return this;
    return replace(current.copyWith(isRead: true));
  }

  /// Reverts [markRead] after the server refused it.
  NotificationsFeed markUnread(String id) {
    final current = byId(id);
    if (current == null || current.isUnread) return this;
    return replace(current.copyWith(isRead: false));
  }

  NotificationsFeed markAllRead() => _copy(
    items: [
      for (final item in items)
        if (item.isUnread) item.copyWith(isRead: true) else item,
    ],
    unreadCount: 0,
  );

  NotificationsFeed _copy({
    List<NotificationEntity>? items,
    int? total,
    int? unreadCount,
  }) => NotificationsFeed(
    items: items ?? this.items,
    page: page,
    hasMore: hasMore,
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  @override
  List<Object?> get props => [items, page, hasMore, total, unreadCount];
}
