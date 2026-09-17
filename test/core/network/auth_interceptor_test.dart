import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/api_headers.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/network/interceptors/auth_interceptor.dart';
import 'package:jameia_mart/src/core/storage/auth_tokens.dart';

import 'network_test_fakes.dart';

void main() {
  late InMemorySessionStore session;
  late RecordingExpiryNotifier expiry;
  late FakeHttpClientAdapter adapter;

  const rotated = AuthTokens(
    accessToken: 'new-access',
    refreshToken: 'new-refresh',
  );

  DioConsumer build({
    required FakeHttpClientAdapter transport,
    required FakeTokenRefresher refresher,
  }) {
    adapter = transport;
    final dio = Dio()..httpClientAdapter = adapter;
    return DioConsumer(
      dio,
      interceptors: [
        AuthInterceptor(
          dio: dio,
          session: session,
          refresher: refresher,
          expiry: expiry,
        ),
      ],
    );
  }

  String? bearer(RequestOptions options) =>
      options.headers[ApiHeaders.authorization] as String?;

  ResponseBody unauthorized() => envelope(
    status: 401,
    statusMessage: 'TOKEN_EXPIRED',
    errorMessage: 'expired',
  );

  setUp(() {
    session = InMemorySessionStore()
      ..accessToken = 'old-access'
      ..refreshToken = 'old-refresh';
    expiry = RecordingExpiryNotifier();
  });

  test('attaches Bearer when signed in, nothing when signed out', () async {
    session.accessToken = null;
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => okBody(null)),
      refresher: FakeTokenRefresher((_) => rotated),
    );
    await consumer.get('/v1/home');
    expect(bearer(adapter.requests.single), isNull);

    session.accessToken = 'abc';
    await consumer.get('/v1/account/me');
    expect(bearer(adapter.requests.last), 'Bearer abc');
  });

  test('401 → refresh once → replay with the new token', () async {
    final refresher = FakeTokenRefresher((token) {
      expect(token, 'old-refresh');
      return rotated;
    });
    final consumer = build(
      transport: FakeHttpClientAdapter(
        (_, call) => call == 0 ? unauthorized() : okBody({'ok': true}),
      ),
      refresher: refresher,
    );

    final result = await consumer.get('/v1/account/me');

    expect(result, {'ok': true});
    expect(refresher.calls, 1);
    expect(adapter.requests, hasLength(2));
    expect(bearer(adapter.requests[0]), 'Bearer old-access');
    expect(bearer(adapter.requests[1]), 'Bearer new-access');
    expect(session.accessToken, 'new-access');
    expect(session.refreshToken, 'new-refresh');
    expect(expiry.expiredCalls, 0);
  });

  test('a 401 on the replayed request is NOT refreshed again', () async {
    final refresher = FakeTokenRefresher((_) => rotated);
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => unauthorized()),
      refresher: refresher,
    );

    await expectLater(
      () => consumer.get('/v1/account/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refresher.calls, 1);
    expect(adapter.requests, hasLength(2));
  });

  test('refresh rejected → tokens cleared + session expiry fired', () async {
    final refresher = FakeTokenRefresher(
      (_) =>
          throw const UnauthorizedException('revoked', code: 'INVALID_TOKEN'),
    );
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => unauthorized()),
      refresher: refresher,
    );

    await expectLater(
      () => consumer.get('/v1/account/me'),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.code,
          'code',
          'TOKEN_EXPIRED',
        ),
      ),
    );
    expect(session.clearTokensCalls, 1);
    expect(session.accessToken, isNull);
    expect(expiry.expiredCalls, 1);
    expect(adapter.requests, hasLength(1));
  });

  test('network failure during refresh keeps the session', () async {
    final refresher = FakeTokenRefresher(
      (_) => throw const NoInternetConnectionException(),
    );
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => unauthorized()),
      refresher: refresher,
    );

    await expectLater(
      () => consumer.get('/v1/account/me'),
      throwsA(isA<NoInternetConnectionException>()),
    );
    expect(session.clearTokensCalls, 0);
    expect(session.accessToken, 'old-access');
    expect(expiry.expiredCalls, 0);
  });

  test('guest 401 (no refresh token) is surfaced untouched', () async {
    session
      ..accessToken = null
      ..refreshToken = null;
    final refresher = FakeTokenRefresher((_) => rotated);
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => unauthorized()),
      refresher: refresher,
    );

    await expectLater(
      () => consumer.get('/v1/account/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refresher.calls, 0);
  });

  test('401 from an auth route never triggers a refresh', () async {
    final refresher = FakeTokenRefresher((_) => rotated);
    final consumer = build(
      transport: FakeHttpClientAdapter((_, _) => unauthorized()),
      refresher: refresher,
    );

    await expectLater(
      () => consumer.post(EndPoints.authLogout),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refresher.calls, 0);
  });

  test('concurrent 401s share one refresh', () async {
    final refresher = FakeTokenRefresher((_) => rotated);
    final consumer = build(
      transport: FakeHttpClientAdapter(
        (options, _) => bearer(options) == 'Bearer old-access'
            ? unauthorized()
            : okBody({'path': options.path}),
      ),
      refresher: refresher,
    );

    final results = await Future.wait([
      consumer.get('/v1/account/me'),
      consumer.get('/v1/orders'),
      consumer.get('/v1/notifications'),
    ]);

    expect(results.map((r) => (r as Map)['path']), [
      '/v1/account/me',
      '/v1/orders',
      '/v1/notifications',
    ]);
    expect(refresher.calls, 1);
  });

  test(
    'single-flight holds when the keychain reads are slow (async gaps)',
    () async {
      // A real keychain answers over a platform channel: every read is an async
      // gap in which another 401 can arrive. All of them must join ONE rotation
      // — a second one would present the already-revoked refresh token.
      final slow = _SlowSessionStore()
        ..accessToken = 'old-access'
        ..refreshToken = 'old-refresh';
      session = slow;
      final refresher = FakeTokenRefresher((token) async {
        expect(token, 'old-refresh', reason: 'never a revoked token');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return rotated;
      });
      final consumer = build(
        transport: FakeHttpClientAdapter(
          (options, _) => bearer(options) == 'Bearer old-access'
              ? unauthorized()
              : okBody({'path': options.path}),
        ),
        refresher: refresher,
      );

      final results = await Future.wait([
        consumer.get('/v1/account/me'),
        Future<void>.delayed(
          const Duration(milliseconds: 2),
        ).then((_) => consumer.get('/v1/orders')),
        Future<void>.delayed(
          const Duration(milliseconds: 4),
        ).then((_) => consumer.get('/v1/notifications')),
      ]);

      expect(results, hasLength(3));
      expect(refresher.calls, 1);
      expect(expiry.expiredCalls, 0);
      expect(slow.accessToken, 'new-access');
    },
  );

  group('pre-flight refresh (token about to expire)', () {
    test(
      'refreshes BEFORE the request when the token is inside the skew',
      () async {
        session.accessTokenExpiry = DateTime.now().toUtc().add(
          const Duration(seconds: 10),
        );
        final refresher = FakeTokenRefresher((_) => rotated);
        final consumer = build(
          transport: FakeHttpClientAdapter((_, _) => okBody({'ok': true})),
          refresher: refresher,
        );

        await consumer.get('/v1/account/me');

        expect(refresher.calls, 1);
        expect(adapter.requests, hasLength(1));
        expect(bearer(adapter.requests.single), 'Bearer new-access');
        expect(session.accessToken, 'new-access');
      },
    );

    test('a token far from expiry is sent as-is', () async {
      session.accessTokenExpiry = DateTime.now().toUtc().add(
        const Duration(minutes: 14),
      );
      final refresher = FakeTokenRefresher((_) => rotated);
      final consumer = build(
        transport: FakeHttpClientAdapter((_, _) => okBody(null)),
        refresher: refresher,
      );

      await consumer.get('/v1/account/me');

      expect(refresher.calls, 0);
      expect(bearer(adapter.requests.single), 'Bearer old-access');
    });

    test(
      'network failure during the pre-flight sends the current token',
      () async {
        session.accessTokenExpiry = DateTime.now().toUtc();
        final refresher = FakeTokenRefresher(
          (_) => throw const NoInternetConnectionException(),
        );
        final consumer = build(
          transport: FakeHttpClientAdapter((_, _) => okBody({'ok': true})),
          refresher: refresher,
        );

        final result = await consumer.get('/v1/account/me');

        expect(result, {'ok': true});
        expect(bearer(adapter.requests.single), 'Bearer old-access');
        expect(session.clearTokensCalls, 0);
      },
    );

    test(
      'pre-flight refresh rejected → session wiped, request goes anonymous',
      () async {
        session.accessTokenExpiry = DateTime.now().toUtc();
        final refresher = FakeTokenRefresher(
          (_) => throw const UnauthorizedException(
            'revoked',
            code: 'INVALID_TOKEN',
          ),
        );
        final consumer = build(
          transport: FakeHttpClientAdapter((_, _) => unauthorized()),
          refresher: refresher,
        );

        await expectLater(
          () => consumer.get('/v1/account/me'),
          throwsA(isA<UnauthorizedException>()),
        );
        expect(refresher.calls, 1);
        expect(expiry.expiredCalls, 1);
        expect(bearer(adapter.requests.single), isNull);
      },
    );

    test('auth routes never pre-flight', () async {
      session.accessTokenExpiry = DateTime.now().toUtc();
      final refresher = FakeTokenRefresher((_) => rotated);
      final consumer = build(
        transport: FakeHttpClientAdapter((_, _) => okBody(null)),
        refresher: refresher,
      );

      await consumer.post(EndPoints.authLogout);

      expect(refresher.calls, 0);
      expect(bearer(adapter.requests.single), 'Bearer old-access');
    });

    test('concurrent expiring requests share one pre-flight refresh', () async {
      session.accessTokenExpiry = DateTime.now().toUtc();
      final refresher = FakeTokenRefresher((_) => rotated);
      final consumer = build(
        transport: FakeHttpClientAdapter((_, _) => okBody(null)),
        refresher: refresher,
      );

      await Future.wait([
        consumer.get('/v1/account/me'),
        consumer.get('/v1/orders'),
        consumer.get('/v1/notifications'),
      ]);

      expect(refresher.calls, 1);
      expect(adapter.requests, hasLength(3));
      for (final request in adapter.requests) {
        expect(bearer(request), 'Bearer new-access');
      }
    });
  });
}

/// Every read crosses an async gap, like the platform-channel keychain.
class _SlowSessionStore extends InMemorySessionStore {
  static const Duration _gap = Duration(milliseconds: 1);

  @override
  Future<String?> readAccessToken() async {
    await Future<void>.delayed(_gap);
    return accessToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    await Future<void>.delayed(_gap);
    return refreshToken;
  }
}
