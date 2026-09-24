import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/storage/auth_tokens.dart';
import 'package:jameia_mart/src/core/storage/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStore store;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureSessionStore(const FlutterSecureStorage(), random: Random(7));
  });

  test('starts signed out', () async {
    expect(await store.isSignedIn, isFalse);
    expect(await store.readAccessToken(), isNull);
    expect(await store.readRefreshToken(), isNull);
  });

  test('saveTokens persists the pair and clearTokens forgets it', () async {
    await store.saveTokens(
      const AuthTokens(accessToken: 'acc', refreshToken: 'ref'),
    );
    expect(await store.isSignedIn, isTrue);
    expect(await store.readAccessToken(), 'acc');
    expect(await store.readRefreshToken(), 'ref');

    await store.clearTokens();
    expect(await store.isSignedIn, isFalse);
    expect(await store.readRefreshToken(), isNull);
  });

  test('ensureAssistantGuestKey generates a stable 32-hex key', () async {
    final first = await store.ensureAssistantGuestKey();
    final second = await store.ensureAssistantGuestKey();

    expect(first, hasLength(32));
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(first), isTrue);
    expect(second, first);
  });

  test(
    'clearGuestSession drops the guest identities but keeps tokens',
    () async {
      await store.saveTokens(
        const AuthTokens(accessToken: 'acc', refreshToken: 'ref'),
      );
      await store.saveCartToken('cart');
      final guestKey = await store.ensureAssistantGuestKey();

      await store.clearGuestSession();

      expect(await store.readCartToken(), isNull);
      expect(await store.ensureAssistantGuestKey(), isNot(guestKey));
      expect(await store.readAccessToken(), 'acc');
    },
  );

  test('clearAll wipes everything', () async {
    await store.saveTokens(
      const AuthTokens(accessToken: 'acc', refreshToken: 'ref'),
    );
    await store.saveCartToken('cart');

    await store.clearAll();

    expect(await store.isSignedIn, isFalse);
    expect(await store.readCartToken(), isNull);
  });

  group('AuthTokens.fromJson', () {
    test('parses the documented payload', () {
      final tokens = AuthTokens.fromJson({
        'accessToken': 'jwt',
        'refreshToken': 'opaque',
        'tokenType': 'Bearer',
        'expiresIn': 900,
        'customer': {'id': 'x'},
      });
      expect(
        tokens,
        const AuthTokens(accessToken: 'jwt', refreshToken: 'opaque'),
      );
      expect(tokens.expiresIn, AuthTokens.defaultExpiresInSeconds);
    });

    test('throws ParsingException when a token is missing', () {
      expect(
        () => AuthTokens.fromJson({'accessToken': 'jwt'}),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => AuthTokens.fromJson({'accessToken': '', 'refreshToken': 'r'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('access token expiry', () {
    final fixedNow = DateTime.utc(2026, 9, 17, 12, 0, 0);

    test(
      'saveTokens records now + expiresIn; clearTokens forgets it',
      () async {
        final clocked = SecureSessionStore(
          const FlutterSecureStorage(),
          random: Random(7),
          now: () => fixedNow,
        );
        await clocked.saveTokens(
          const AuthTokens(
            accessToken: 'acc',
            refreshToken: 'ref',
            expiresIn: 900,
          ),
        );

        expect(
          await clocked.readAccessTokenExpiry(),
          fixedNow.add(const Duration(seconds: 900)),
        );
        // Persisted, not just memoized: a fresh store over the same keychain
        // reads it back (cold start).
        expect(
          await SecureSessionStore(const FlutterSecureStorage())
              .readAccessTokenExpiry(),
          fixedNow.add(const Duration(seconds: 900)),
        );

        await clocked.clearTokens();
        expect(await clocked.readAccessTokenExpiry(), isNull);
      },
    );

    test('no expiry when signed out', () async {
      expect(await store.readAccessTokenExpiry(), isNull);
    });
  });
}
