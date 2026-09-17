import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/watch_session_expiry_usecase.dart';
import 'auth_session_state.dart';

/// App-global session cubit (provided above `MaterialApp.router`):
///
///   * [restore] at launch — validates a stored session against the backend;
///   * [signedIn] after OTP verification;
///   * [signOut] from settings — revokes server-side, wipes locally;
///   * listens for the network layer's "refresh failed" signal (tokens are
///     already wiped when it fires) and flips to signed-out with
///     [AuthSessionState.expired] so the root can route to login.
class AuthSessionCubit extends Cubit<AuthSessionState>
    with SafeCubitMixin<AuthSessionState> {
  AuthSessionCubit({
    required this._restoreSession,
    required this._logout,
    required WatchSessionExpiryUseCase watchExpiry,
  }) : super(const AuthSessionState()) {
    _expirySubscription = watchExpiry(const NoParams())
        .listen((_) => _expire());
  }

  final RestoreSessionUseCase _restoreSession;
  final LogoutUseCase _logout;
  late final StreamSubscription<void> _expirySubscription;

  /// Signed in when a session is stored and the backend accepts it (or cannot
  /// be reached — offline keeps the session); signed out when nothing is
  /// stored, the refresh was rejected, or the keychain is unreadable.
  Future<void> restore() async {
    final result = await _restoreSession(const NoParams());
    result.fold(
      (failure) => switch (failure) {
        UnauthorizedFailure() => _expire(),
        // Backend unreachable or failing: the stored session stays valid.
        NetworkFailure() || TimeoutFailure() || ServerFailure() => safeEmit(
          state.copyWith(status: AuthSessionStatus.signedIn),
        ),
        _ => safeEmit(
          state.copyWith(
            status: AuthSessionStatus.signedOut,
            clearCustomer: true,
          ),
        ),
      },
      (customer) => safeEmit(
        state.copyWith(
          status: customer == null
              ? AuthSessionStatus.signedOut
              : AuthSessionStatus.signedIn,
          customer: customer,
          clearCustomer: customer == null,
        ),
      ),
    );
  }

  void signedIn(AuthCustomerEntity customer) => safeEmit(
    state.copyWith(
      status: AuthSessionStatus.signedIn,
      customer: customer,
      expired: false,
    ),
  );

  /// The profile was edited (`PATCH /v1/account/profile`): keep the global
  /// snapshot in step so every greeting / header shows the new values.
  void updateCustomer(AuthCustomerEntity customer) =>
      safeEmit(state.copyWith(customer: customer));

  Future<void> signOut() async {
    if (state.isSigningOut) return;
    safeEmit(state.copyWith(isSigningOut: true));
    final result = await _logout(const NoParams());
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(isSigningOut: false, failure: failure)),
      (_) => safeEmit(
        state.copyWith(
          status: AuthSessionStatus.signedOut,
          clearCustomer: true,
          expired: false,
          isSigningOut: false,
        ),
      ),
    );
  }

  void _expire() => safeEmit(
    state.copyWith(
      status: AuthSessionStatus.signedOut,
      clearCustomer: true,
      expired: true,
    ),
  );

  @override
  Future<void> close() async {
    await _expirySubscription.cancel();
    return super.close();
  }
}
