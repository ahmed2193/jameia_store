import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/notifications_page_model.dart';

/// The inbox as last shown: its first page (all, or unread only — two
/// entries), per language. Customer-only — nothing is kept for a guest — and
/// wiped on sign-out. Parsed back with the DTO's own `fromJson`.
abstract class NotificationsCacheDataSource {
  /// `GET /v1/notifications` — the first page of [limit].
  CacheSlot<NotificationsPageModel>? firstPage({
    required int limit,
    required bool unreadOnly,
  });

  /// Forgets every saved first page: a read mark reached the server, so a
  /// copy must not be served as fresh with the old unread rows.
  Future<void> forgetPages();
}

class NotificationsCacheDataSourceImpl implements NotificationsCacheDataSource {
  const NotificationsCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;
  static const String _all = 'all';
  static const String _unread = 'unread';

  static const CacheNamespace pageNamespace = CacheNamespace(
    'notifications.page',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 30),
    maxAge: Duration(days: 14),
  );

  @override
  Future<void> forgetPages() => _slots.forget(pageNamespace);

  @override
  CacheSlot<NotificationsPageModel>? firstPage({
    required int limit,
    required bool unreadOnly,
  }) => _slots.of(
    pageNamespace,
    id: '${unreadOnly ? _unread : _all}|$limit',
    parse: (raw) => NotificationsPageModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.notifications),
      requestedPage: _firstPage,
    ),
  );
}
