import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/storage/auth_tokens.dart';
import 'package:jameia_mart/src/features/auth/data/datasources/auth_local_data_source.dart';

import '../../core/network/network_test_fakes.dart';

void main() {
  late InMemorySessionStore session;
  late RecordingExpiryNotifier expiry;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    session = InMemorySessionStore()
      ..cartToken = 'cart'
      ..assistantGuestKey = 'g' * 32;
    expiry = RecordingExpiryNotifier();
    dataSource = AuthLocalDataSourceImpl(session, expiry);
  });

  test('saveSession stores the pair AND drops the guest identities', () async {
    await dataSource.saveSession(
      const AuthTokens(accessToken: 'a', refreshToken: 'r'),
    );
    expect(session.accessToken, 'a');
    expect(session.refreshToken, 'r');
    expect(session.cartToken, isNull);
    expect(session.assistantGuestKey, isNull);
    expect(await dataSource.hasSession(), isTrue);
  });

  test('clearSession forgets the pair only', () async {
    await dataSource.saveSession(
      const AuthTokens(accessToken: 'a', refreshToken: 'r'),
    );
    await session.saveCartToken('cart2');
    await dataSource.clearSession();
    expect(await dataSource.hasSession(), isFalse);
    expect(session.cartToken, 'cart2');
  });

  test('onSessionExpired is the notifier stream', () {
    expect(dataSource.onSessionExpired, same(expiry.onSessionExpired));
  });
}
