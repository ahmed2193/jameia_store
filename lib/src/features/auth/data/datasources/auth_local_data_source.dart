import 'dart:convert';

import '../../../../core/data/models/customer_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/session_expiry_notifier.dart';
import '../../../../core/storage/auth_tokens.dart';
import '../../../../core/storage/cache_owner.dart';
import '../../../../core/storage/json_cache_store.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/session_store.dart';

/// Device-side session state: the keychain-backed token pair, the "session
/// expired" signal raised by the network layer, and the device copy of the
/// signed-in customer (the `GET /v1/account/me` row as JSON under one
/// `LocalStorage` key), which lets a launch show the profile before the
/// network answers and keeps it on screen offline. The copy is wiped when
/// the session ends.
abstract class AuthLocalDataSource {
  /// Persist a freshly issued pair and drop the guest identities (the backend
  /// merged the guest cart / assistant history into the customer on login).
  Future<void> saveSession(AuthTokens tokens);

  Future<void> clearSession();

  Future<bool> hasSession();

  Stream<void> get onSessionExpired;

  /// The saved customer; `null` when none is saved.
  Future<CustomerModel?> readCustomer();

  Future<void> saveCustomer(CustomerModel customer);

  Future<void> clearCustomer();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(
    this._session,
    this._expiry,
    this._storage, {
    required this._cacheOwner,
    required this._responseCache,
  });

  /// Bump the version when the stored shape changes.
  static const String customerKey = 'account.profile.v1';

  final SessionStore _session;
  final SessionExpiryNotifier _expiry;
  final LocalStorage _storage;

  /// Whose private responses the on-device cache may hold: kept in step
  /// with this device copy (read / saved → that customer; cleared → guest).
  final CacheOwner _cacheOwner;

  /// The cached API responses; the customer's are wiped with this copy.
  final JsonCacheStore _responseCache;

  @override
  Future<void> saveSession(AuthTokens tokens) => Future.wait<void>([
    _session.saveTokens(tokens),
    _session.clearGuestSession(),
  ]);

  @override
  Future<void> clearSession() => _session.clearTokens();

  @override
  Future<bool> hasSession() => _session.isSignedIn;

  @override
  Stream<void> get onSessionExpired => _expiry.onSessionExpired;

  @override
  Future<CustomerModel?> readCustomer() async {
    final raw = _storage.getString(customerKey);
    if (raw == null) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException catch (error) {
      throw CacheException('profile cache unreadable: ${error.message}');
    }
    if (json is! Map<String, dynamic>) {
      throw const CacheException('profile cache: not an object');
    }
    final CustomerModel customer;
    try {
      customer = CustomerModel.fromJson(json);
    } on ParsingException catch (error) {
      throw CacheException(error.message);
    }
    _cacheOwner.signedIn(customer.id);
    return customer;
  }

  /// The storage write starts synchronously, so a [clearCustomer] issued
  /// right after always lands after it.
  @override
  Future<void> saveCustomer(CustomerModel customer) {
    _cacheOwner.signedIn(customer.id);
    return _guard(
      () => _storage.setString(customerKey, jsonEncode(customer.toJson())),
    );
  }

  /// The session ended (sign-out, expiry, a launch that found it gone): the
  /// copy goes, and so does every cached response of the customer. The owner
  /// flips first, so a reply still in flight is not saved for them.
  @override
  Future<void> clearCustomer() async {
    _cacheOwner.signedOut();
    await Future.wait<void>([
      _guard(() => _storage.remove(customerKey)),
      _responseCache.removeOwnedEntries(),
    ]);
  }

  /// A failed or refused write surfaces as the data layer's [CacheException].
  static Future<void> _guard(Future<bool> Function() write) async {
    final bool written;
    try {
      written = await write();
    } on Exception catch (error) {
      throw CacheException('profile cache write failed: $error');
    }
    if (!written) throw const CacheException('profile cache write refused');
  }
}
