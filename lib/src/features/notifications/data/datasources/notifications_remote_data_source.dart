import 'dart:async';
import 'dart:developer';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/network/event_stream_client.dart';
import '../models/notification_model.dart';
import '../models/notifications_page_model.dart';

/// The jm3eia customer notification routes. Request/response calls receive
/// the envelope's `results` (unwrapped by `DioConsumer`); the SSE route goes
/// through [EventStreamClient]. Throws `AppException` only.
///
/// Reference: https://docs.jm3eia.store/developers/ (Notifications, Push).
abstract class NotificationsRemoteDataSource {
  /// `GET /v1/notifications?page&limit[&status=unread]`.
  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int limit,
    bool unreadOnly = false,
  });

  /// `PATCH /v1/notifications/:id/read` → the updated notification.
  Future<NotificationModel> markRead(String id);

  /// `PATCH /v1/notifications/read-all` → `updatedCount`.
  Future<int> markAllRead();

  /// `POST /v1/push/register { token, platform }`.
  Future<void> registerPushToken({
    required String token,
    required String platform,
  });

  /// `GET /v1/notifications/sse` — only `event: notification` frames whose
  /// data is a well-formed notification; anything else (heartbeats, other
  /// event names, malformed payloads) is dropped without ending the stream.
  ///
  /// ONE connection per device: every listener (the app-global badge, the
  /// open inbox) shares it. It opens with the first listener and closes when
  /// the last one cancels.
  Stream<NotificationModel> watchLive();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this._api, this._events);

  final ApiConsumer _api;
  final EventStreamClient _events;

  /// The shared live feed while at least one listener is attached.
  StreamController<NotificationModel>? _live;

  static const String _logName = 'NotificationsRemoteDataSource';

  // Query / body field names (docs: notifications, push).
  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String statusField = 'status';
  static const String tokenField = 'token';
  static const String platformField = 'platform';
  static const String updatedCountField = 'updatedCount';

  /// SSE event name carrying a notification payload.
  static const String notificationEvent = 'notification';

  @override
  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) async {
    final results = await _api.get(
      EndPoints.notifications,
      queryParameters: <String, dynamic>{
        pageField: page,
        limitField: limit,
        if (unreadOnly) statusField: NotificationModel.statusUnread,
      },
    );
    return NotificationsPageModel.fromJson(
      ApiPayload.asMap(results, 'notifications'),
      requestedPage: page,
    );
  }

  @override
  Future<NotificationModel> markRead(String id) async {
    final results = await _api.patch(EndPoints.notificationRead(id));
    return NotificationModel.fromJson(
      ApiPayload.asMap(results, 'notifications/read'),
    );
  }

  @override
  Future<int> markAllRead() async {
    final results = await _api.patch(EndPoints.notificationsReadAll);
    final count = ApiPayload.asMap(
      results,
      'notifications/read-all',
    )[updatedCountField];
    return switch (count) {
      int() => count,
      num() => count.toInt(),
      _ => throw const ParsingException('read-all: updatedCount missing'),
    };
  }

  @override
  Future<void> registerPushToken({
    required String token,
    required String platform,
  }) => _api.post(
    EndPoints.pushRegister,
    body: <String, Object?>{tokenField: token, platformField: platform},
  );

  @override
  Stream<NotificationModel> watchLive() => (_live ??= _openShared()).stream;

  /// A broadcast controller over ONE upstream connection. It forgets itself
  /// when the last listener leaves or the server ends the stream, so the next
  /// [watchLive] reconnects from scratch.
  StreamController<NotificationModel> _openShared() {
    late final StreamController<NotificationModel> controller;
    StreamSubscription<NotificationModel>? upstream;

    void release() {
      if (identical(_live, controller)) _live = null;
    }

    controller = StreamController<NotificationModel>.broadcast(
      onListen: () => upstream = _events
          .connect(EndPoints.notificationsSse)
          .where((frame) => frame.event == notificationEvent)
          .expand(_parseFrame)
          .listen(
            controller.add,
            onError: (Object error, StackTrace stackTrace) {
              release();
              controller
                ..addError(error, stackTrace)
                ..close();
            },
            onDone: () {
              release();
              controller.close();
            },
          ),
      onCancel: () {
        release();
        controller.close();
        unawaited(upstream?.cancel());
      },
    );
    return controller;
  }

  /// Zero or one model per frame — a bad payload is logged and skipped so one
  /// malformed push never tears the live connection down.
  static Iterable<NotificationModel> _parseFrame(ServerSentEvent frame) {
    final json = frame.json;
    if (json == null) return const [];
    try {
      return [NotificationModel.fromJson(json)];
    } on AppException catch (error) {
      log('dropped live frame: $error', name: _logName);
      return const [];
    }
  }
}
