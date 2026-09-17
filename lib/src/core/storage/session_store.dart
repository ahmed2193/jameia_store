import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/exceptions.dart';
import 'auth_tokens.dart';

/// The device-side API session: the customer token pair plus the two guest
/// identities (`X-Cart-Token`, `X-Assistant-Guest`).
///
/// Backed by the platform keychain / keystore (docs: "Persist accessToken +
/// refreshToken in SecureStore") — NEVER by `LocalStorage` / shared_preferences,
/// which is plaintext on disk. Feature code reaches it only through a
/// datasource; the network interceptors read it on every request.
abstract class SessionStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  /// When the stored access token stops being accepted (UTC), computed from
  /// the pair's `expiresIn` at save time. `null` when signed out. The auth
  /// interceptor refreshes shortly BEFORE this instant instead of waiting for
  /// the 401.
  Future<DateTime?> readAccessTokenExpiry();

  /// `true` when an access token is stored (the request will carry a Bearer).
  Future<bool> get isSignedIn;

  /// Persist a freshly issued pair (login or refresh) — both tokens and the
  /// expiry together, never one without the others.
  Future<void> saveTokens(AuthTokens tokens);

  /// Forget the pair (logout / refresh rejected). Guest identities survive.
  Future<void> clearTokens();

  Future<String?> readCartToken();

  Future<void> saveCartToken(String token);

  /// The persisted 32-hex guest key, generated on first use.
  Future<String> ensureAssistantGuestKey();

  /// Drop the guest identities after they merged into the customer on login.
  Future<void> clearGuestSession();

  /// Tokens + guest identities — full reset.
  Future<void> clearAll();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage, {Random? random, this._now = DateTime.now})
    : _random = random ?? Random.secure();

  static const String _accessTokenKey = 'session.access_token';
  static const String _refreshTokenKey = 'session.refresh_token';
  static const String _expiresAtKey = 'session.access_expires_at';
  static const String _cartTokenKey = 'session.cart_token';
  static const String _assistantGuestKey = 'session.assistant_guest_key';

  /// 16 random bytes → 32 hex chars, the length the backend validates.
  static const int _guestKeyBytes = 16;
  static const int _guestKeyLength = _guestKeyBytes * 2;
  static const int _byteRange = 256;
  static const int _hexRadix = 16;

  final FlutterSecureStorage _storage;
  final Random _random;
  final DateTime Function() _now;

  // Interceptors read the access token (and, while signed out, the guest ids)
  // on EVERY request; memoize so the platform channel is hit once per process,
  // not once per call. Writers below invalidate the entries they change.
  String? _cachedAccessToken;
  bool _accessTokenLoaded = false;
  DateTime? _cachedExpiry;
  bool _expiryLoaded = false;

  // The very first reads happen in a burst (every screen fires at launch):
  // share ONE keychain round trip instead of one per concurrent request.
  Future<String?>? _accessTokenRead;
  Future<DateTime?>? _expiryRead;
  String? _cachedCartToken;
  bool _cartTokenLoaded = false;
  String? _cachedGuestKey;

  @override
  Future<String?> readAccessToken() {
    if (_accessTokenLoaded) return Future.value(_cachedAccessToken);
    return _accessTokenRead ??= _guard(() async {
      final token = await _storage.read(key: _accessTokenKey);
      // A write that landed while this read was in flight is newer.
      if (!_accessTokenLoaded) {
        _cachedAccessToken = token;
        _accessTokenLoaded = true;
      }
      return _cachedAccessToken;
    }).whenComplete(() => _accessTokenRead = null);
  }

  @override
  Future<String?> readRefreshToken() =>
      _guard(() => _storage.read(key: _refreshTokenKey));

  @override
  Future<DateTime?> readAccessTokenExpiry() {
    if (_expiryLoaded) return Future.value(_cachedExpiry);
    return _expiryRead ??= _guard(() async {
      final raw = await _storage.read(key: _expiresAtKey);
      if (!_expiryLoaded) {
        _cachedExpiry = raw == null ? null : DateTime.tryParse(raw)?.toUtc();
        _expiryLoaded = true;
      }
      return _cachedExpiry;
    }).whenComplete(() => _expiryRead = null);
  }

  @override
  Future<bool> get isSignedIn async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) => _guard(() async {
    final expiresAt = _now().toUtc().add(Duration(seconds: tokens.expiresIn));
    await Future.wait<void>([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String()),
    ]);
    _cachedAccessToken = tokens.accessToken;
    _accessTokenLoaded = true;
    _cachedExpiry = expiresAt;
    _expiryLoaded = true;
  });

  @override
  Future<void> clearTokens() => _guard(() async {
    await Future.wait<void>([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
    ]);
    _cachedAccessToken = null;
    _accessTokenLoaded = true;
    _cachedExpiry = null;
    _expiryLoaded = true;
  });

  @override
  Future<String?> readCartToken() => _guard(() async {
    if (_cartTokenLoaded) return _cachedCartToken;
    _cachedCartToken = await _storage.read(key: _cartTokenKey);
    _cartTokenLoaded = true;
    return _cachedCartToken;
  });

  @override
  Future<void> saveCartToken(String token) => _guard(() async {
    await _storage.write(key: _cartTokenKey, value: token);
    _cachedCartToken = token;
    _cartTokenLoaded = true;
  });

  @override
  Future<String> ensureAssistantGuestKey() => _guard(() async {
    final cached = _cachedGuestKey;
    if (cached != null) return cached;
    final existing = await _storage.read(key: _assistantGuestKey);
    if (existing != null && existing.length == _guestKeyLength) {
      return _cachedGuestKey = existing;
    }
    final generated = _randomHex();
    await _storage.write(key: _assistantGuestKey, value: generated);
    return _cachedGuestKey = generated;
  });

  @override
  Future<void> clearGuestSession() => _guard(() async {
    await Future.wait<void>([
      _storage.delete(key: _cartTokenKey),
      _storage.delete(key: _assistantGuestKey),
    ]);
    _cachedCartToken = null;
    _cartTokenLoaded = true;
    _cachedGuestKey = null;
  });

  @override
  Future<void> clearAll() async {
    await clearTokens();
    await clearGuestSession();
  }

  String _randomHex() => List<int>.generate(
    _guestKeyBytes,
    (_) => _random.nextInt(_byteRange),
  ).map((byte) => byte.toRadixString(_hexRadix).padLeft(2, '0')).join();

  /// Keystore / keychain failures surface as the data layer's [CacheException]
  /// so `BaseRepositoryMixin` maps them like any other local-storage error.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw CacheException('Secure storage failed: $error');
    }
  }
}
