import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/watch_live_notifications_usecase.dart';
import 'unread_notifications_state.dart';

/// App-global unread badge (provided above `MaterialApp.router`):
///
///   * [start] once signed in — probes the unread counter with a one-item
///     page, then listens to the live stream (+1 per unread notification)
///     when the build has one;
///   * [stop] on sign-out — drops the stream and resets to zero;
///   * [set] from the inbox page, which knows the fresher count.
///
/// A guest is a normal case, not an error: the probe answers
/// `UnauthorizedFailure`, the badge stays at 0 and no stream is opened, so
/// nothing throws or retries in a loop.
///
/// Without a live source (`watchLive: null`, the default build — see
/// `AppEnv.liveNotifications`) the badge is the probe's count, refreshed by
/// the inbox through [set]; no stream is ever opened.
class UnreadNotificationsCubit extends Cubit<UnreadNotificationsState>
    with SafeCubitMixin<UnreadNotificationsState> {
  UnreadNotificationsCubit({required this._getNotifications, this._watchLive})
    : super(const UnreadNotificationsState());

  /// The smallest page that still carries `unreadCount`.
  static const int probeLimit = 1;
  static const int _firstPage = 1;
  static const String _logName = 'UnreadNotificationsCubit';

  final GetNotificationsUseCase _getNotifications;
  final WatchLiveNotificationsUseCase? _watchLive;

  StreamSubscription<NotificationEntity>? _live;
  bool _starting = false;

  /// Invalidated by [stop] so a probe still in flight cannot resume a
  /// session that ended meanwhile.
  int _generation = 0;

  Future<void> start() async {
    if (_starting || _live != null) return;
    _starting = true;
    final generation = _generation;
    final result = await _getNotifications(
      const GetNotificationsParams(page: _firstPage, limit: probeLimit),
    );
    if (isClosed || generation != _generation) return;
    _starting = false;
    final listen = result.fold(
      (failure) {
        log('unread probe failed', name: _logName, error: failure);
        return failure is! UnauthorizedFailure;
      },
      (feed) {
        safeEmit(state.copyWith(unreadCount: feed.unreadCount));
        return true;
      },
    );
    if (listen) _listenLive();
  }

  void stop() {
    _generation++;
    _starting = false;
    _cancelLive();
    // Bloc always delivers a cubit's FIRST emit, even when equal — skip the
    // no-op so a guest sign-out never rebuilds the badge for nothing.
    if (state != const UnreadNotificationsState()) {
      safeEmit(const UnreadNotificationsState());
    }
  }

  /// The inbox page reports the count it just loaded / changed.
  void set(int count) =>
      safeEmit(state.copyWith(unreadCount: count < 0 ? 0 : count));

  void _listenLive() {
    final watchLive = _watchLive;
    if (watchLive == null) return;
    _live = watchLive(const NoParams()).listen(
      (notification) => safeEmit(
        state.copyWith(
          unreadCount: notification.isRead
              ? state.unreadCount
              : state.unreadCount + 1,
          isLive: true,
        ),
      ),
      onError: (Object error) {
        log('live stream ended', name: _logName, error: error);
        _live = null;
        safeEmit(state.copyWith(isLive: false));
      },
      onDone: () {
        _live = null;
        safeEmit(state.copyWith(isLive: false));
      },
    );
    safeEmit(state.copyWith(isLive: true));
  }

  void _cancelLive() {
    unawaited(_live?.cancel());
    _live = null;
  }

  @override
  Future<void> close() async {
    await _live?.cancel();
    _live = null;
    return super.close();
  }
}
