import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/network/event_stream_client.dart';
import 'package:jameia_mart/src/features/notifications/data/datasources/notifications_remote_data_source.dart';

import '../../core/network/network_test_fakes.dart';
import 'notifications_test_fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late FakeEventStreamClient events;
  late NotificationsRemoteDataSourceImpl dataSource;

  NotificationsRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    events = FakeEventStreamClient();
    final dio = Dio()..httpClientAdapter = adapter;
    return NotificationsRemoteDataSourceImpl(DioConsumer(dio), events);
  }

  RequestOptions request() => adapter.requests.single;

  tearDown(() => events.controller.close());

  group('getNotifications', () {
    test('GETs page + limit and parses the page', () async {
      dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(
            pageJson(
              items: [
                notificationJson(),
                notificationJson(id: 'n2'),
              ],
              page: 1,
              total: 25,
              hasMore: true,
              unreadCount: 4,
            ),
          ),
        ),
      );

      final page = await dataSource.getNotifications(page: 1, limit: 20);

      expect(request().path, EndPoints.notifications);
      expect(request().method, 'GET');
      expect(request().queryParameters, {'page': 1, 'limit': 20});
      expect(page.items.map((item) => item.id), ['n1', 'n2']);
      expect(page.hasMore, isTrue);
      expect(page.total, 25);
      expect(page.unreadCount, 4);
    });

    test('unreadOnly adds status=unread', () async {
      dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(pageJson(items: []))),
      );

      await dataSource.getNotifications(page: 2, limit: 10, unreadOnly: true);

      expect(request().queryParameters, {
        'page': 2,
        'limit': 10,
        'status': 'unread',
      });
    });

    test('a non-object payload throws ParsingException', () {
      dataSource = build(FakeHttpClientAdapter((_, _) => okBody([1, 2])));

      expect(
        () => dataSource.getNotifications(page: 1, limit: 20),
        throwsA(isA<ParsingException>()),
      );
    });

    test('a 401 envelope surfaces as UnauthorizedException (guest)', () {
      dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 401,
            statusMessage: 'AUTHENTICATION_REQUIRED',
            errorMessage: 'Sign in',
          ),
        ),
      );

      expect(
        () => dataSource.getNotifications(page: 1, limit: 20),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.code,
            'code',
            'AUTHENTICATION_REQUIRED',
          ),
        ),
      );
    });
  });

  test('markRead PATCHes /:id/read and parses the notification', () async {
    dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody(notificationJson(id: 'abc', status: 'read')),
      ),
    );

    final model = await dataSource.markRead('abc');

    expect(request().path, EndPoints.notificationRead('abc'));
    expect(request().method, 'PATCH');
    expect(model.id, 'abc');
    expect(model.isRead, isTrue);
  });

  test('markAllRead PATCHes read-all and returns updatedCount', () async {
    dataSource = build(
      FakeHttpClientAdapter((_, _) => okBody({'updatedCount': 6})),
    );

    final count = await dataSource.markAllRead();

    expect(request().path, EndPoints.notificationsReadAll);
    expect(request().method, 'PATCH');
    expect(count, 6);
  });

  test('markAllRead without updatedCount throws ParsingException', () {
    dataSource = build(FakeHttpClientAdapter((_, _) => okBody({})));

    expect(dataSource.markAllRead(), throwsA(isA<ParsingException>()));
  });

  test('registerPushToken POSTs { token, platform }', () async {
    dataSource = build(
      FakeHttpClientAdapter((_, _) => okBody({'message': 'ok'})),
    );

    await dataSource.registerPushToken(
      token: 'fcm-token-1234567890',
      platform: 'android',
    );

    expect(request().path, EndPoints.pushRegister);
    expect(request().method, 'POST');
    expect(Map<String, dynamic>.from(request().data as Map), {
      'token': 'fcm-token-1234567890',
      'platform': 'android',
    });
  });

  group('watchLive', () {
    test('connects to the SSE route and yields only well-formed notification frames', () async {
      dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));

      final received = <String>[];
      final subscription = dataSource.watchLive().listen(
        (model) => received.add(model.id),
      );
      events.controller
        ..add(
          ServerSentEvent(
            event: 'notification',
            data: jsonEncode(notificationJson(id: 'live-1')),
          ),
        )
        ..add(const ServerSentEvent(data: 'ping')) // default `message` event
        ..add(
          ServerSentEvent(
            event: 'other',
            data: jsonEncode(notificationJson(id: 'ignored')),
          ),
        )
        ..add(const ServerSentEvent(event: 'notification', data: 'not json'))
        ..add(
          ServerSentEvent(
            event: 'notification',
            data: jsonEncode(notificationJson(id: 'live-2')..remove('type')),
          ),
        )
        ..add(
          ServerSentEvent(
            event: 'notification',
            data: jsonEncode(notificationJson(id: 'live-3')),
          ),
        );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(events.paths, [EndPoints.notificationsSse]);
      expect(received, ['live-1', 'live-3']);
      expect(adapter.requests, isEmpty, reason: 'SSE never uses ApiConsumer');
    });

    test('a server rejection propagates as the stream error', () async {
      dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));

      final stream = dataSource.watchLive();
      final errors = <Object>[];
      final subscription = stream.listen((_) {}, onError: errors.add);
      events.controller.addError(const UnauthorizedException('Sign in'));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(errors.single, isA<UnauthorizedException>());
    });

    test(
      'every listener shares ONE connection; it reopens after all leave',
      () async {
        dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));
        final badge = <String>[];
        final inbox = <String>[];

        final first = dataSource.watchLive().listen((m) => badge.add(m.id));
        final second = dataSource.watchLive().listen((m) => inbox.add(m.id));
        events.controller.add(
          ServerSentEvent(
            event: 'notification',
            data: jsonEncode(notificationJson(id: 'shared')),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(events.paths, hasLength(1), reason: 'one upstream connection');
        expect(badge, ['shared']);
        expect(inbox, ['shared']);

        // The inbox closes; the badge keeps the same connection.
        await second.cancel();
        expect(events.paths, hasLength(1));

        // Everyone left → the next listener connects afresh.
        await first.cancel();
        final third = dataSource.watchLive().listen((_) {});
        await Future<void>.delayed(Duration.zero);
        expect(events.paths, hasLength(2));
        await third.cancel();
      },
    );
  });
}
