import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/watch_live_notifications_usecase.dart';
import 'notifications_state.dart';

/// Page-scoped inbox cubit: paged loading, optimistic read marks and a live
/// (SSE) subscription that prepends new notifications while the page is open.
/// All list arithmetic lives in `NotificationsFeed`; this only sequences calls.
class NotificationsCubit extends Cubit<NotificationsState>
    with SafeCubitMixin<NotificationsState> {
  NotificationsCubit({
    required this._getNotifications,
    required this._markRead,
    required this._markAllRead,
    required this._watchLive,
  }) : super(const NotificationsState());

  static const int pageSize = 20;
  static const int _firstPage = 1;
  static const String _logName = 'NotificationsCubit';

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final WatchLiveNotificationsUseCase _watchLive;

  StreamSubscription<NotificationEntity>? _live;
  bool _markingAll = false;

  /// Bumped by every first-page load. A page request that was in flight when
  /// a newer first page started is stale: applying it would append page N+1
  /// onto a fresh page 1 (skipping the pages between) — so it is dropped.
  int _generation = 0;

  /// First load (or retry after an error): full-screen loader, then page 1
  /// and the live subscription.
  Future<void> load() async {
    safeEmit(state.copyWith(status: NotificationsStatus.loading));
    await _loadFirstPage(NotificationsAction.load);
  }

  /// Pull-to-refresh: page 1 again while the current list stays on screen.
  Future<void> refresh() => _loadFirstPage(NotificationsAction.refresh);

  Future<void> _loadFirstPage(NotificationsAction action) async {
    final generation = ++_generation;
    final result = await _getNotifications(
      const GetNotificationsParams(page: _firstPage, limit: pageSize),
    );
    if (generation != _generation) return; // superseded by a newer load
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          // A failed refresh keeps the list; a failed first load has none.
          status: state.isLoaded
              ? NotificationsStatus.loaded
              : NotificationsStatus.error,
          failure: failure,
          failedAction: action,
        ),
      ),
      (feed) {
        safeEmit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            feed: feed,
            isLoadingMore: false,
            loadMoreFailed: false,
          ),
        );
        _listenLive();
      },
    );
  }

  /// Next page; no-op while one is in flight or when the server has no more.
  Future<void> loadMore() async {
    if (!state.isLoaded || !state.feed.hasMore || state.isLoadingMore) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getNotifications(
      GetNotificationsParams(page: state.feed.page + 1, limit: pageSize),
    );
    if (generation != _generation) {
      // A refresh replaced the list meanwhile: this page no longer follows it.
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          failure: failure,
          failedAction: NotificationsAction.loadMore,
        ),
      ),
      (next) => safeEmit(
        state.copyWith(isLoadingMore: false, feed: state.feed.merge(next)),
      ),
    );
  }

  /// Optimistic: the row flips to read at once and flips back if the server
  /// refuses. Already-read or unknown ids are ignored.
  Future<void> markRead(String id) async {
    final target = state.feed.byId(id);
    if (!state.isLoaded || target == null || target.isRead) return;
    safeEmit(state.copyWith(feed: state.feed.markRead(id)));
    final result = await _markRead(MarkNotificationReadParams(id: id));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          feed: state.feed.markUnread(id),
          failure: failure,
          failedAction: NotificationsAction.markRead,
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
      (failure) => safeEmit(
        state.copyWith(
          failure: failure,
          failedAction: NotificationsAction.markAllRead,
        ),
      ),
      (_) => safeEmit(
        state.copyWith(feed: state.feed.markAllRead(), allMarkedRead: true),
      ),
    );
  }

  void _listenLive() {
    if (_live != null) return;
    _live = _watchLive(const NoParams()).listen(
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
