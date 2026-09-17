import '../../../../core/error/exceptions.dart';

/// One notification as the backend sends it (list item, `:id/read` reply and
/// SSE `notification` frame share the shape):
///
/// ```json
/// { "_id": "…", "type": "order.delivered", "status": "unread",
///   "title": { "en": "…", "ar": "…" }, "body": { "en": "…", "ar": "…" },
///   "data": { "orderId": "…", "orderNumber": "…", "ticketNumber": "…", "url": "…" },
///   "readAt": null, "createdAt": "2026-09-17T10:00:00.000Z", … }
/// ```
///
/// Tolerant of `_id` / `id`, a missing `data` object and title/body sent as
/// a plain string (already-resolved localization).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.createdAt,
    this.readAt,
    this.orderId,
    this.orderNumber,
    this.ticketNumber,
    this.url,
  });

  static const String idKey = '_id';
  static const String altIdKey = 'id';
  static const String typeKey = 'type';
  static const String statusKey = 'status';
  static const String titleKey = 'title';
  static const String bodyKey = 'body';
  static const String dataKey = 'data';
  static const String readAtKey = 'readAt';
  static const String createdAtKey = 'createdAt';
  static const String orderIdKey = 'orderId';
  static const String orderNumberKey = 'orderNumber';
  static const String ticketNumberKey = 'ticketNumber';
  static const String urlKey = 'url';
  static const String enKey = 'en';
  static const String arKey = 'ar';

  static const String statusRead = 'read';
  static const String statusUnread = 'unread';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final id = json[idKey] ?? json[altIdKey];
    if (id is! String || id.isEmpty) {
      throw const ParsingException('notification: missing id');
    }
    final type = json[typeKey];
    if (type is! String || type.isEmpty) {
      throw const ParsingException('notification: missing type');
    }
    final createdAtRaw = json[createdAtKey];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    if (createdAt == null) {
      throw const ParsingException('notification: bad createdAt');
    }

    final title = _Localized.of(json[titleKey]);
    final body = _Localized.of(json[bodyKey]);
    final data = json[dataKey];
    final payload = data is Map ? data.cast<String, dynamic>() : null;
    final status = json[statusKey];
    final readAt = json[readAtKey];

    return NotificationModel(
      id: id,
      type: type,
      status: status is String ? status : statusUnread,
      titleEn: title.en,
      titleAr: title.ar,
      bodyEn: body.en,
      bodyAr: body.ar,
      createdAt: createdAt,
      readAt: readAt is String ? readAt : null,
      orderId: _optionalString(payload?[orderIdKey]),
      orderNumber: _optionalString(payload?[orderNumberKey]),
      ticketNumber: _optionalString(payload?[ticketNumberKey]),
      url: _optionalString(payload?[urlKey]),
    );
  }

  final String id;
  final String type;

  /// `unread` | `read`.
  final String status;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final DateTime createdAt;
  final String? readAt;
  final String? orderId;
  final String? orderNumber;
  final String? ticketNumber;
  final String? url;

  bool get isRead => status == statusRead;

  /// Numbers (an order number may arrive as an int) are kept as text.
  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}

/// `{ en, ar }` object, or a plain string used for both.
class _Localized {
  const _Localized(this.en, this.ar);

  factory _Localized.of(Object? raw) {
    if (raw is Map) {
      final en = raw[NotificationModel.enKey];
      final ar = raw[NotificationModel.arKey];
      return _Localized(en is String ? en : '', ar is String ? ar : '');
    }
    if (raw is String) return _Localized(raw, raw);
    return const _Localized('', '');
  }

  final String en;
  final String ar;
}
