import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notifications_feed.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/watch_live_notifications_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';
import 'notifications_state.dart';

/// Page-scoped inbox cubit: paged loading (the first page paints from the
/// device copy, offline too, then the server's), optimistic read marks and —
/// when the build has a live source (`AppEnv.liveNotifications`) — a live
/// (SSE) subscription that prepends new notifications while the page is
/// open. All list arithmetic lives in `NotificationsFeed`, the screen flow
/// in the loader mixins; this only sequences calls.
class NotificationsCubit extends Cubit<NotificationsState>
    with
        SafeCubitMixin<NotificationsState>,
        SnapshotLoaderMixin<NotificationsState>,
        ScreenLoaderMixin<NotificationsState>,
        PagedScreenMixin<NotificationsState> {
  NotificationsCubit({
    required this._watchFirstPage,
    required this._getNotifications,
    required this._markRead,
    required this._markAllRead,
    this._watchLive,
  }) : super(const NotificationsState());

  static const int pageSize = 20;
  static const String _logName = 'NotificationsCubit';

  final WatchNotificationsUseCase _watchFirstPage;
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final WatchLiveNotificationsUseCase? _watchLive;

  StreamSubscription<NotificationEntity>? _live;
  bool _markingAll = false;

  /// First load (or retry after an error): the loader only while nothing is
  /// on screen, then page 1 and — once the server answered — the live
  /// subscription.
  Future<void> load() {
    showLoading();
    return _readFirstPage(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's page 1 while the current list stays on
  /// screen.
  @override
  Future<void> refresh() => _readFirstPage(forceRefresh: true);

  Future<void> _readFirstPage({required bool forceRefresh}) =>
      readScreen<NotificationsFeed>(
        _watchFirstPage(
          WatchNotificationsParams(limit: pageSize, forceRefresh: forceRefresh),
        ),
        show: (state, snapshot) {
          // Live once the server answered, not on a copy shown offline (its
          // first push can only land after this page is on screen).
          if (!snapshot.isFromCache) _listenLive();
          return state.copyWith(feed: snapshot.data);
        },
      );

  /// Next page; a no-op while one is in flight, when the server has no more,
  /// and after a failed page unless [retry].
  @override
  Future<void> loadMore({bool retry = false}) =>
      loadNextPage<NotificationsFeed>(
        hasMore: state.feed.hasMore,
        retry: retry,
        fetch: () => _getNotifications(
          GetNotificationsParams(page: state.feed.page + 1, limit: pageSize),
        ),
        merge: (state, next) => state.copyWith(feed: state.feed.merge(next)),
      );

  /// Optimistic: the row flips to read at once and flips back if the server
  /// refuses. Already-read or unknown ids are ignored.
  Future<void> markRead(String id) async {
    final target = state.feed.byId(id);
    if (!state.isLoaded || target == null || target.isRead) return;
    safeEmit(state.copyWith(feed: state.feed.markRead(id)));
    final result = await _markRead(MarkNotificationReadParams(id: id));
    result.fold(
      // Rolled back like a read: offline it only nudges the banner.
      (failure) => safeEmit(
        state.copyWith(
          feed: state.feed.markUnread(id),
          load: state.load.noted(failure, on: FailedCall.read),
        ),
      ),
      (updated) => safeEmit(state.copyWith(feed: state.feed.replace(updated))),
    );
  }

  /// Marks everything read server-side, then locally (one tap at a time).
  Future<void> markAllRead() async {
    if (!state.isLoaded || !state.feed.hasUnread || _markingAll) return;
    _markingAll = true;
    final result = await _markAllRead(const NoParams());
    _markingAll = false;
    result.fold(
      noteFailure,
      (_) => safeEmit(
        state.copyWith(feed: state.feed.markAllRead(), allMarkedRead: true),
      ),
    );
  }

  void _listenLive() {
    final watchLive = _watchLive;
    if (_live != null || watchLive == null) return;
    _live = watchLive(const NoParams()).listen(
      (notification) =>
          safeEmit(state.copyWith(feed: state.feed.prepend(notification))),
      onError: (Object error) {
        // The server rejected the stream; the inbox stays usable without it.
        log('live stream ended', name: _logName, error: error);
        _live = null;
      },
      onDone: () => _live = null,
    );
  }

  @override
  Future<void> close() async {
    await _live?.cancel();
    _live = null;
    return super.close();
  }
}
