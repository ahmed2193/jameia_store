import '../../../../core/network/session_expiry_notifier.dart';
import '../../../../core/storage/auth_tokens.dart';
import '../../../../core/storage/session_store.dart';

/// Device-side session state: the keychain-backed token pair plus the
/// "session expired" signal raised by the network layer.
abstract class AuthLocalDataSource {
  /// Persist a freshly issued pair and drop the guest identities (the backend
  /// merged the guest cart / assistant history into the customer on login).
  Future<void> saveSession(AuthTokens tokens);

  Future<void> clearSession();

  Future<bool> hasSession();

  Stream<void> get onSessionExpired;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._session, this._expiry);

  final SessionStore _session;
  final SessionExpiryNotifier _expiry;

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
}
