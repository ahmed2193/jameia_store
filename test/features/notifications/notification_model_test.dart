import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/features/notifications/data/mappers/notification_mapper.dart';
import 'package:jameia_mart/src/features/notifications/data/models/notification_model.dart';
import 'package:jameia_mart/src/features/notifications/data/models/notifications_page_model.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notification_entity.dart';

import 'notifications_test_fakes.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('parses the full backend shape', () {
      final model = NotificationModel.fromJson(
        notificationJson(
          data: {
            'orderId': 'o1',
            'orderNumber': 1001,
            'ticketNumber': 'T-7',
            'url': 'https://jm3eia.store/x',
          },
        ),
      );

      expect(model.id, 'n1');
      expect(model.type, 'order.delivered');
      expect(model.status, 'unread');
      expect(model.isRead, isFalse);
      expect(model.titleEn, 'Delivered');
      expect(model.titleAr, 'تم التوصيل');
      expect(model.bodyEn, 'Your order arrived');
      expect(model.bodyAr, 'وصل طلبك');
      expect(model.createdAt, kCreatedAt);
      expect(model.readAt, isNull);
      expect(model.orderId, 'o1');
      expect(model.orderNumber, '1001');
      expect(model.ticketNumber, 'T-7');
      expect(model.url, 'https://jm3eia.store/x');
    });

    test(
      'accepts `id` instead of `_id`, a missing `data` and string titles',
      () {
        final json = notificationJson(data: null)
          ..remove('_id')
          ..['id'] = 'n9'
          ..['title'] = 'Plain'
          ..['body'] = 'Text';

        final model = NotificationModel.fromJson(json);

        expect(model.id, 'n9');
        expect(model.titleEn, 'Plain');
        expect(model.titleAr, 'Plain');
        expect(model.bodyEn, 'Text');
        expect(model.orderId, isNull);
        expect(model.ticketNumber, isNull);
        expect(model.url, isNull);
      },
    );

    test('read status + readAt', () {
      final model = NotificationModel.fromJson(
        notificationJson(status: 'read'),
      );
      expect(model.isRead, isTrue);
      expect(model.readAt, kCreatedAtIso);
    });

    test('throws ParsingException without an id / type / valid createdAt', () {
      expect(
        () => NotificationModel.fromJson(notificationJson()..remove('_id')),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => NotificationModel.fromJson(notificationJson()..remove('type')),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => NotificationModel.fromJson(notificationJson(createdAt: 'soon')),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('NotificationsPageModel.fromJson', () {
    test('parses items, pagination and unreadCount', () {
      final model = NotificationsPageModel.fromJson(
        pageJson(
          items: [
            notificationJson(),
            notificationJson(id: 'n2'),
          ],
          page: 2,
          limit: 20,
          total: 41,
          hasMore: true,
          unreadCount: 7,
        ),
      );

      expect(model.items.map((item) => item.id), ['n1', 'n2']);
      expect(model.page, 2);
      expect(model.limit, 20);
      expect(model.total, 41);
      expect(model.hasMore, isTrue);
      expect(model.unreadCount, 7);
    });

    test('defaults when pagination / unreadCount are missing', () {
      final model = NotificationsPageModel.fromJson({
        'data': [notificationJson()],
      }, requestedPage: 3);

      expect(model.page, 3);
      expect(model.total, 1);
      expect(model.limit, 1);
      expect(model.hasMore, isFalse);
      expect(model.unreadCount, 0);
    });

    test('throws ParsingException when data is not a list', () {
      expect(
        () => NotificationsPageModel.fromJson({'data': 'nope'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('one malformed row is skipped, the rest of the page survives', () {
      final page = NotificationsPageModel.fromJson({
        'data': [
          'bad',
          notificationJson(id: 'broken')..remove('type'),
          notificationJson(id: 'good'),
        ],
        'unreadCount': 2,
      });

      expect(page.items.map((item) => item.id), ['good']);
      expect(page.unreadCount, 2);
    });
  });

  group('mappers', () {
    test('NotificationModel → NotificationEntity keeps every field', () {
      final entity = NotificationModel.fromJson(
        notificationJson(
          data: {'orderId': 'o1', 'orderNumber': 'JM-1', 'ticketNumber': 'T'},
        ),
      ).toEntity();

      expect(
        entity,
        NotificationEntity(
          id: 'n1',
          type: 'order.delivered',
          isRead: false,
          titleEn: 'Delivered',
          titleAr: 'تم التوصيل',
          bodyEn: 'Your order arrived',
          bodyAr: 'وصل طلبك',
          createdAt: kCreatedAt,
          orderId: 'o1',
          orderNumber: 'JM-1',
          ticketNumber: 'T',
        ),
      );
    });

    test('NotificationsPageModel → NotificationsFeed', () {
      final feed = NotificationsPageModel.fromJson(
        pageJson(
          items: [
            notificationJson(),
            notificationJson(id: 'n2', status: 'read'),
          ],
          page: 1,
          total: 30,
          hasMore: true,
          unreadCount: 12,
        ),
      ).toEntity();

      expect(feed.items.map((item) => item.id), ['n1', 'n2']);
      expect(feed.items.map((item) => item.isRead), [false, true]);
      expect(feed.page, 1);
      expect(feed.hasMore, isTrue);
      expect(feed.total, 30);
      expect(feed.unreadCount, 12);
    });
  });
}
