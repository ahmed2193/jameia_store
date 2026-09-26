import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/assistant_conversations_feed.dart';

enum AssistantHistoryStatus { initial, loading, loaded, error }

/// Which call produced [AssistantHistoryState.failure]: a full-screen error
/// for [load], a snack bar for the rest.
enum AssistantHistoryAction { load, refresh, loadMore }

/// Past conversations, newest first (mirrors `NotificationsState`).
class AssistantHistoryState extends Equatable {
  const AssistantHistoryState({
    this.status = AssistantHistoryStatus.initial,
    this.feed = AssistantConversationsFeed.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
    this.failedAction,
  });

  final AssistantHistoryStatus status;
  final AssistantConversationsFeed feed;

  /// Next page in flight (guards re-entry; the list shows a footer).
  final bool isLoadingMore;

  /// The last next-page request failed: the footer offers a retry.
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Transient, set together with [failure].
  final AssistantHistoryAction? failedAction;

  bool get isLoaded => status == AssistantHistoryStatus.loaded;

  /// The load failed because this customer must sign in first.
  bool get isSignedOut =>
      status == AssistantHistoryStatus.error && failure is UnauthorizedFailure;

  AssistantHistoryState copyWith({
    AssistantHistoryStatus? status,
    AssistantConversationsFeed? feed,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
    AssistantHistoryAction? failedAction,
  }) => AssistantHistoryState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
    failedAction: failedAction,
  );

  @override
  List<Object?> get props => [
    status,
    feed,
    isLoadingMore,
    loadMoreFailed,
    failure,
    failedAction,
  ];
}
