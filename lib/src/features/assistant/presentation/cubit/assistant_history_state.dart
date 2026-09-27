import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/assistant_conversations_feed.dart';

/// Past conversations, newest first (mirrors `NotificationsState`).
class AssistantHistoryState extends Equatable
    implements ScreenLoadState<AssistantHistoryState> {
  const AssistantHistoryState({
    this.load = const ScreenLoad(),
    this.feed = AssistantConversationsFeed.empty,
  });

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them (the sign-in prompt, "No connection" …).
  @override
  final ScreenLoad load;
  final AssistantConversationsFeed feed;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  /// Next page in flight (guards re-entry; the list shows a footer).
  bool get isLoadingMore => load.isLoadingMore;

  /// The last next-page request failed: the footer offers a retry
  /// (offline: it waits for the connection).
  bool get loadMoreFailed => load.nextPageFailed;

  /// The load failed because this customer must sign in first.
  bool get isSignedOut => load.isSignedOut;

  @override
  AssistantHistoryState withLoad(ScreenLoad load) => copyWith(load: load);

  AssistantHistoryState copyWith({
    ScreenLoad? load,
    AssistantConversationsFeed? feed,
  }) => AssistantHistoryState(
    load: load ?? this.load.settled(),
    feed: feed ?? this.feed,
  );

  @override
  List<Object?> get props => [load, feed];
}
