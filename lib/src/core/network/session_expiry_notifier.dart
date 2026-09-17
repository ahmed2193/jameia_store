import 'dart:async';

/// Broadcasts "the session is over" — fired by `AuthInterceptor` when a 401
/// could not be recovered by a token refresh (refresh token revoked/expired).
///
/// Invariant: by the time [notifyExpired] fires, the token pair has ALREADY
/// been cleared from `SessionStore`; listeners only update UI state.
///
/// The auth feature exposes this through a repository + `StreamUseCase` so an
/// app-global cubit can clear user state and route to `Routes.login`
/// (docs: "Failed refresh attempts should redirect users to login").
abstract class SessionExpiryNotifier {
  Stream<void> get onSessionExpired;

  void notifyExpired();
}

class SessionExpiryNotifierImpl implements SessionExpiryNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onSessionExpired => _controller.stream;

  @override
  void notifyExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
