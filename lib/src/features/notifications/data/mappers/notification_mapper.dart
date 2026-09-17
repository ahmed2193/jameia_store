import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notifications_feed.dart';
import '../models/notification_model.dart';
import '../models/notifications_page_model.dart';

extension NotificationMapper on NotificationModel {
  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    type: type,
    isRead: isRead,
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
}

extension NotificationListMapper on List<NotificationModel> {
  List<NotificationEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

extension NotificationsPageMapper on NotificationsPageModel {
  NotificationsFeed toEntity() => NotificationsFeed(
    items: items.toEntities(),
    page: page,
    hasMore: hasMore,
    total: total,
    unreadCount: unreadCount,
  );
}
