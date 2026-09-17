import 'package:equatable/equatable.dart';

import '../../../../core/domain/localization/localized_pick.dart';

/// Coarse family of a notification, derived from the backend `type` prefix
/// (`order.delivered` → [order], `points.earned` → [points] …). Presentation
/// picks the icon / tint from this; the raw [NotificationEntity.type] stays
/// available for anything finer.
enum NotificationKind {
  order,
  points,
  wallet,
  coupon,
  offer,
  review,
  subscription,
  account,
  campaign,
  support,
  other;

  /// `order.out_for_delivery` → [order]; unknown prefixes → [other].
  static NotificationKind fromType(String type) {
    final separator = type.indexOf('.');
    final prefix = separator < 0 ? type : type.substring(0, separator);
    for (final kind in NotificationKind.values) {
      if (kind != other && kind.name == prefix) return kind;
    }
    return other;
  }
}

/// One inbox notification (`GET /v1/notifications` item / SSE frame).
///
/// Title and body arrive as `{ en, ar }`; both are kept raw and picked with
/// [titleFor] / [bodyFor] so a locale switch re-renders live. Deep-link
/// targets ([orderId], [ticketNumber], [url]) come from the backend `data`
/// object and are `null` when the notification has nowhere to go.
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.isRead,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.createdAt,
    this.orderId,
    this.orderNumber,
    this.ticketNumber,
    this.url,
  });

  final String id;

  /// Backend type, e.g. `order.delivered`, `support.replied`.
  final String type;
  final bool isRead;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final DateTime createdAt;
  final String? orderId;
  final String? orderNumber;
  final String? ticketNumber;
  final String? url;

  NotificationKind get kind => NotificationKind.fromType(type);

  bool get isUnread => !isRead;

  /// Opens order tracking when tapped.
  bool get hasOrder => orderId != null && orderId!.isNotEmpty;

  /// Opens customer service when tapped.
  bool get hasTicket => ticketNumber != null && ticketNumber!.isNotEmpty;

  String titleFor(String languageCode) =>
      pickLocalized(languageCode, en: titleEn, ar: titleAr);

  String bodyFor(String languageCode) =>
      pickLocalized(languageCode, en: bodyEn, ar: bodyAr);

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
    id: id,
    type: type,
    isRead: isRead ?? this.isRead,
    titleEn: titleEn,
    titleAr: titleAr,
    bodyEn: bodyEn,
    bodyAr: bodyAr,
    createdAt: createdAt,
    orderId: orderId,
    orderNumber: orderNumber,
    ticketNumber: ticketNumber,
    url: url,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    isRead,
    titleEn,
    titleAr,
    bodyEn,
    bodyAr,
    createdAt,
    orderId,
    orderNumber,
    ticketNumber,
    url,
  ];
}
