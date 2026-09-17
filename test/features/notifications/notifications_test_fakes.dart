import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/event_stream_client.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:jameia_mart/src/features/notifications/data/models/notification_model.dart';
import 'package:jameia_mart/src/features/notifications/data/models/notifications_page_model.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notification_entity.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notifications_feed.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/watch_live_notifications_usecase.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

final DateTime kCreatedAt = DateTime.utc(2026, 9, 17, 10, 30);
const String kCreatedAtIso = '2026-09-17T10:30:00.000Z';

NotificationEntity notification({
  String id = 'n1',
  String type = 'order.delivered',
  bool isRead = false,
  String? orderId,
  String? ticketNumber,
}) => NotificationEntity(
  id: id,
  type: type,
  isRead: isRead,
  titleEn: 'Title $id',
  titleAr: 'عنوان $id',
  bodyEn: 'Body $id',
  bodyAr: 'نص $id',
  createdAt: kCreatedAt,
  orderId: orderId,
  ticketNumber: ticketNumber,
);

NotificationsFeed feedOf(
  List<NotificationEntity> items, {
  int page = 1,
  bool hasMore = false,
  int? total,
  int? unreadCount,
}) => NotificationsFeed(
  items: items,
  page: page,
  hasMore: hasMore,
  total: total ?? items.length,
  unreadCount: unreadCount ?? items.where((item) => item.isUnread).length,
);

/// A backend notification object as `GET /v1/notifications` / SSE send it.
Map<String, dynamic> notificationJson({
  String id = 'n1',
  String type = 'order.delivered',
  String status = 'unread',
  Object? data = const {'orderId': 'o1', 'orderNumber': 'JM-1001'},
  String createdAt = kCreatedAtIso,
}) => <String, dynamic>{
  '_id': id,
  'recipientType': 'customer',
  'recipientId': 'c1',
  'type': type,
  'status': status,
  'title': {'en': 'Delivered', 'ar': 'تم التوصيل'},
  'body': {'en': 'Your order arrived', 'ar': 'وصل طلبك'},
  'data': ?data,
  'readAt': status == 'read' ? createdAt : null,
  'createdAt': createdAt,
  'updatedAt': createdAt,
};

Map<String, dynamic> pageJson({
  required List<Map<String, dynamic>> items,
  int page = 1,
  int limit = 20,
  int? total,
  bool hasMore = false,
  int unreadCount = 0,
}) => <String, dynamic>{
  'data': items,
  'pagination': {
    'total': total ?? items.length,
    'page': page,
    'limit': limit,
    'hasMore': hasMore,
  },
  'unreadCount': unreadCount,
};

NotificationModel notificationModel({String id = 'n1', bool isRead = false}) =>
    NotificationModel(
      id: id,
      type: 'order.delivered',
      status: isRead
          ? NotificationModel.statusRead
          : NotificationModel.statusUnread,
      titleEn: 'Title $id',
      titleAr: 'عنوان $id',
      bodyEn: 'Body $id',
      bodyAr: 'نص $id',
      createdAt: kCreatedAt,
    );

// ── Hand-written fakes (no mocktail in this project) ────────────────────────

class FakeGetNotificationsUseCase implements GetNotificationsUseCase {
  FakeGetNotificationsUseCase(this.result);

  Either<Failure, NotificationsFeed> result;

  /// Per-request answer (e.g. by page); falls back to [result].
  Either<Failure, NotificationsFeed> Function(GetNotificationsParams params)?
  handler;
  final List<GetNotificationsParams> calls = [];

  /// Per-page gates: a request for that page is held until its gate completes
  /// (lets a test interleave a refresh with a load-more).
  final Map<int, Completer<void>> gates = {};

  @override
  Future<Either<Failure, NotificationsFeed>> call(
    GetNotificationsParams params,
  ) async {
    calls.add(params);
    await gates[params.page]?.future;
    return handler?.call(params) ?? result;
  }
}

class FakeMarkNotificationReadUseCase implements MarkNotificationReadUseCase {
  FakeMarkNotificationReadUseCase(this.result);

  Either<Failure, NotificationEntity> result;
  final List<MarkNotificationReadParams> calls = [];

  @override
  Future<Either<Failure, NotificationEntity>> call(
    MarkNotificationReadParams params,
  ) async {
    calls.add(params);
    return result;
  }
}

class FakeMarkAllNotificationsReadUseCase
    implements MarkAllNotificationsReadUseCase {
  FakeMarkAllNotificationsReadUseCase([this.result = const Right(0)]);

  Either<Failure, int> result;
  int calls = 0;

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    calls++;
    return result;
  }
}

class FakeWatchLiveNotificationsUseCase
    implements WatchLiveNotificationsUseCase {
  final StreamController<NotificationEntity> controller =
      StreamController<NotificationEntity>.broadcast();
  int listens = 0;

  void emit(NotificationEntity notification) => controller.add(notification);

  /// The server rejected the stream: error, then done.
  Future<void> fail(Object error) async {
    controller.addError(error);
    await controller.close();
  }

  @override
  Stream<NotificationEntity> call(NoParams params) {
    listens++;
    return controller.stream;
  }
}

/// Scripted SSE transport for datasource tests.
class FakeEventStreamClient implements EventStreamClient {
  final StreamController<ServerSentEvent> controller =
      StreamController<ServerSentEvent>.broadcast();
  final List<String> paths = [];

  @override
  Stream<ServerSentEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    paths.add(path);
    return controller.stream;
  }
}

/// Scripted datasource for repository tests: throws [error] when set.
class FakeNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  Object? error;
  NotificationsPageModel page = NotificationsPageModel(
    items: [notificationModel()],
    total: 1,
    page: 1,
    limit: 20,
    hasMore: false,
    unreadCount: 1,
  );
  NotificationModel readReply = notificationModel(isRead: true);
  int updatedCount = 3;
  Stream<NotificationModel> live = const Stream.empty();
  final List<String> calls = [];

  @override
  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) async {
    calls.add('get:$page:$limit:$unreadOnly');
    if (error != null) throw error!;
    return this.page;
  }

  @override
  Future<NotificationModel> markRead(String id) async {
    calls.add('read:$id');
    if (error != null) throw error!;
    return readReply;
  }

  @override
  Future<int> markAllRead() async {
    calls.add('read-all');
    if (error != null) throw error!;
    return updatedCount;
  }

  @override
  Future<void> registerPushToken({
    required String token,
    required String platform,
  }) async {
    calls.add('push:$token:$platform');
    if (error != null) throw error!;
  }

  @override
  Stream<NotificationModel> watchLive() => live;
}
