import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/notifications_feed.dart';

enum NotificationsStatus { initial, loading, loaded, error }

/// Which cubit call produced [NotificationsState.failure] — the page shows a
/// full-screen error for [load], a snack bar for the rest.
enum NotificationsAction { load, refresh, loadMore, markRead, markAllRead }

/// Inbox screen state: the loaded pages ([feed]) plus the request flags.
class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.feed = NotificationsFeed.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
    this.failedAction,
    this.allMarkedRead = false,
  });

  final NotificationsStatus status;
  final NotificationsFeed feed;

  /// Next page request in flight (guards re-entry; the list shows a footer).
  final bool isLoadingMore;

  /// The last next-page request failed: the footer offers a retry instead of
  /// spinning. Reset when a page request starts or succeeds.
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Transient, set together with [failure].
  final NotificationsAction? failedAction;

  /// Transient one-shot: "mark all read" just succeeded (toast).
  final bool allMarkedRead;

  bool get isLoaded => status == NotificationsStatus.loaded;

  /// The load failed because nobody is signed in — show the sign-in prompt.
  bool get isSignedOut =>
      status == NotificationsStatus.error && failure is UnauthorizedFailure;

  NotificationsState copyWith({
    NotificationsStatus? status,
    NotificationsFeed? feed,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
    NotificationsAction? failedAction,
    bool allMarkedRead = false,
  }) => NotificationsState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
    failedAction: failedAction,
    allMarkedRead: allMarkedRead,
  );

  @override
  List<Object?> get props => [
    status,
    feed,
    isLoadingMore,
    loadMoreFailed,
    failure,
    failedAction,
    allMarkedRead,
  ];
}
