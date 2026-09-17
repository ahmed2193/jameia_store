import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notification_entity.dart';
import 'package:jameia_mart/src/features/notifications/domain/entities/notifications_feed.dart';

import 'notifications_test_fakes.dart';

void main() {
  group('NotificationKind', () {
    test('groups backend types by prefix', () {
      expect(
        NotificationKind.fromType('order.out_for_delivery'),
        NotificationKind.order,
      );
      expect(
        NotificationKind.fromType('points.expiring'),
        NotificationKind.points,
      );
      expect(
        NotificationKind.fromType('wallet.credited'),
        NotificationKind.wallet,
      );
      expect(
        NotificationKind.fromType('coupon.received'),
        NotificationKind.coupon,
      );
      expect(
        NotificationKind.fromType('offer.expiring'),
        NotificationKind.offer,
      );
      expect(
        NotificationKind.fromType('review.requested'),
        NotificationKind.review,
      );
      expect(
        NotificationKind.fromType('subscription.expired'),
        NotificationKind.subscription,
      );
      expect(
        NotificationKind.fromType('account.welcome'),
        NotificationKind.account,
      );
      expect(
        NotificationKind.fromType('campaign.message'),
        NotificationKind.campaign,
      );
      expect(
        NotificationKind.fromType('support.replied'),
        NotificationKind.support,
      );
      expect(
        NotificationKind.fromType('something.new'),
        NotificationKind.other,
      );
      expect(NotificationKind.fromType('other.x'), NotificationKind.other);
      expect(NotificationKind.fromType(''), NotificationKind.other);
    });
  });

  group('NotificationEntity', () {
    test('picks the localized title / body and exposes deep-link flags', () {
      final entity = notification(orderId: 'o1');
      expect(entity.titleFor('en'), 'Title n1');
      expect(entity.titleFor('ar'), 'عنوان n1');
      expect(entity.bodyFor('ar_KW'), 'نص n1');
      expect(entity.kind, NotificationKind.order);
      expect(entity.hasOrder, isTrue);
      expect(entity.hasTicket, isFalse);
      expect(entity.isUnread, isTrue);
    });

    test('copyWith flips only the read flag', () {
      final read = notification().copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, 'n1');
      expect(read.createdAt, kCreatedAt);
    });
  });

  group('NotificationsFeed', () {
    final n1 = notification(id: 'n1');
    final n2 = notification(id: 'n2', isRead: true);
    final n3 = notification(id: 'n3');

    test('merge appends the next page, skips duplicates, takes its cursor', () {
      final first = feedOf(
        [n1, n2],
        page: 1,
        hasMore: true,
        total: 3,
        unreadCount: 2,
      );
      final second = feedOf(
        [n2, n3],
        page: 2,
        hasMore: false,
        total: 3,
        unreadCount: 1,
      );

      final merged = first.merge(second);

      expect(merged.items, [n1, n2, n3]);
      expect(merged.page, 2);
      expect(merged.hasMore, isFalse);
      expect(merged.total, 3);
      expect(merged.unreadCount, 1);
    });

    test('prepend inserts on top and counts an unread one', () {
      final feed = feedOf([n2], total: 5, unreadCount: 1).prepend(n1);
      expect(feed.items, [n1, n2]);
      expect(feed.total, 6);
      expect(feed.unreadCount, 2);
    });

    test('prepend of a known id replaces it instead of duplicating', () {
      final feed = feedOf(
        [n1, n2],
        total: 2,
        unreadCount: 1,
      ).prepend(n1.copyWith(isRead: true));
      expect(feed.items.map((item) => item.id), ['n1', 'n2']);
      expect(feed.items.first.isRead, isTrue);
      expect(feed.total, 2);
      expect(feed.unreadCount, 0);
    });

    test('markRead / markUnread move the global counter by one', () {
      final feed = feedOf([n1, n2], unreadCount: 4);
      final read = feed.markRead('n1');
      expect(read.byId('n1')!.isRead, isTrue);
      expect(read.unreadCount, 3);
      expect(read.markRead('n1'), read, reason: 'already read: no-op');
      expect(read.markRead('missing'), read);

      final reverted = read.markUnread('n1');
      expect(reverted.byId('n1')!.isRead, isFalse);
      expect(reverted.unreadCount, 4);
    });

    test('unread counter never goes below zero', () {
      expect(feedOf([n1], unreadCount: 0).markRead('n1').unreadCount, 0);
    });

    test('replace swaps the server copy and keeps the rest', () {
      final feed = feedOf([
        n1,
        n2,
      ], unreadCount: 1).replace(n1.copyWith(isRead: true));
      expect(feed.items, [n1.copyWith(isRead: true), n2]);
      expect(feed.unreadCount, 0);
      expect(feed.replace(n3), feed, reason: 'unknown id ignored');
    });

    test('markAllRead flips every item and zeroes the counter', () {
      final feed = feedOf([n1, n2, n3], unreadCount: 9).markAllRead();
      expect(feed.items.every((item) => item.isRead), isTrue);
      expect(feed.unreadCount, 0);
      expect(feed.hasUnread, isFalse);
    });

    test('empty feed facts', () {
      expect(NotificationsFeed.empty.isEmpty, isTrue);
      expect(NotificationsFeed.empty.page, 0);
      expect(NotificationsFeed.empty.hasMore, isFalse);
      expect(NotificationsFeed.empty.byId('n1'), isNull);
    });
  });
}
