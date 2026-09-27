import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/notifications_feed.dart';

/// Inbox screen state: the loaded pages ([feed]) plus the request flags.
class NotificationsState extends Equatable
    implements ScreenLoadState<NotificationsState> {
  const NotificationsState({
    this.load = const ScreenLoad(),
    this.feed = NotificationsFeed.empty,
    this.allMarkedRead = false,
  });

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them.
  @override
  final ScreenLoad load;
  final NotificationsFeed feed;

  /// Transient one-shot: "mark all read" just succeeded (toast).
  final bool allMarkedRead;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  /// Next page request in flight (guards re-entry; the list shows a footer).
  bool get isLoadingMore => load.isLoadingMore;

  /// The last next-page request failed: the footer offers a retry instead of
  /// spinning (offline: it waits for the connection).
  bool get loadMoreFailed => load.nextPageFailed;

  /// The load failed because nobody is signed in — show the sign-in prompt.
  bool get isSignedOut => load.isSignedOut;

  /// The inbox holds the server's page, not the device copy: only then does
  /// its unread count speak for the server (the app-global badge takes it).
  bool get knowsServerCount => isLoaded && !freshness.fromCache;

  @override
  NotificationsState withLoad(ScreenLoad load) => copyWith(load: load);

  NotificationsState copyWith({
    ScreenLoad? load,
    NotificationsFeed? feed,
    bool allMarkedRead = false,
  }) => NotificationsState(
    load: load ?? this.load.settled(),
    feed: feed ?? this.feed,
    allMarkedRead: allMarkedRead,
  );

  @override
  List<Object?> get props => [load, feed, allMarkedRead];
}
