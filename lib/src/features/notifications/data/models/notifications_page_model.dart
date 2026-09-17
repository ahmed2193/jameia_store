import 'dart:developer';

import '../../../../core/error/exceptions.dart';
import 'notification_model.dart';

/// `results` of `GET /v1/notifications`:
/// `{ data: [Notification], pagination: { total, page, limit, hasMore }, unreadCount }`.
class NotificationsPageModel {
  const NotificationsPageModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.unreadCount,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String limitKey = 'limit';
  static const String hasMoreKey = 'hasMore';
  static const String unreadCountKey = 'unreadCount';

  /// [requestedPage] fills in when the backend omits `pagination`.
  factory NotificationsPageModel.fromJson(
    Map<String, dynamic> json, {
    int requestedPage = 1,
  }) {
    final data = json[dataKey];
    if (data is! List) {
      throw const ParsingException('notifications: data missing');
    }
    // One malformed row must not blank the whole inbox (nor the badge probe):
    // skip it, exactly like the live stream drops a bad frame.
    final items = <NotificationModel>[
      for (final raw in data) ...?_tryParseItem(raw),
    ];

    final paginationRaw = json[paginationKey];
    final pagination = paginationRaw is Map
        ? paginationRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final hasMore = pagination[hasMoreKey];

    return NotificationsPageModel(
      items: items,
      total: _int(pagination[totalKey]) ?? items.length,
      page: _int(pagination[pageKey]) ?? requestedPage,
      limit: _int(pagination[limitKey]) ?? items.length,
      hasMore: hasMore is bool && hasMore,
      unreadCount: _int(json[unreadCountKey]) ?? 0,
    );
  }

  final List<NotificationModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int unreadCount;

  static List<NotificationModel>? _tryParseItem(Object? raw) {
    if (raw is! Map) return null;
    try {
      return [NotificationModel.fromJson(raw.cast<String, dynamic>())];
    } on AppException catch (error) {
      log('dropped inbox item: $error', name: 'NotificationsPageModel');
      return null;
    }
  }

  static int? _int(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };
}
