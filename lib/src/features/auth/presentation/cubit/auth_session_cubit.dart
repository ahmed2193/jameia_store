import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/clear_cached_customer_usecase.dart';
import '../../domain/usecases/get_cached_customer_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/save_cached_customer_usecase.dart';
import '../../domain/usecases/watch_session_expiry_usecase.dart';
import 'auth_session_state.dart';

/// App-global session cubit (provided above `MaterialApp.router`):
///
///   * [restore] at launch — shows the customer saved on the device at once,
///     then validates the stored session against the backend;
///   * [signedIn] after OTP verification;
///   * [updateCustomer] when a reply carries a fresher customer record;
///   * [signOut] from settings — revokes server-side, wipes locally;
///   * listens for the network layer's "refresh failed" signal (tokens are
///     already wiped when it fires) and flips to signed-out with
///     [AuthSessionState.expired] so the root can route to login.
///
/// It is the only owner of the device copy of the customer: every snapshot
/// of a signed-in session is saved, and the copy is removed whenever the
/// session ends, so it is never shown to a signed-out app or kept after
/// sign-out.
class AuthSessionCubit extends Cubit<AuthSessionState>
    with SafeCubitMixin<AuthSessionState> {
  AuthSessionCubit({
    required this._restoreSession,
    required this._logout,
    required WatchSessionExpiryUseCase watchExpiry,
    required this._getCachedCustomer,
    required this._saveCachedCustomer,
    required this._clearCachedCustomer,
  }) : super(const AuthSessionState()) {
    _expirySubscription = watchExpiry(const NoParams())
        .listen((_) => _expire());
  }

  static const String _logName = 'AuthSessionCubit';

  final RestoreSessionUseCase _restoreSession;
  final LogoutUseCase _logout;
  final GetCachedCustomerUseCase _getCachedCustomer;
  final SaveCachedCustomerUseCase _saveCachedCustomer;
  final ClearCachedCustomerUseCase _clearCachedCustomer;
  late final StreamSubscription<void> _expirySubscription;

  /// Bumped whenever the session changes hands (sign-in, sign-out, expiry):
  /// a restore still in flight gives way to it.
  int _session = 0;

  /// What the device copy holds (skips rewriting an identical customer).
  AuthCustomerEntity? _saved;

  /// Signed in when a session is stored and the backend accepts it (or cannot
  /// be reached — offline keeps the session); signed out when nothing is
  /// stored, the refresh was rejected, or the keychain is unreadable. The
  /// saved customer is on screen while the backend is asked.
  Future<void> restore() async {
    final session = _session;
    final cached = await _getCachedCustomer(const NoParams());
    if (session != _session) return;
    final copy = cached.fold((failure) {
      log('device copy unreadable', name: _logName, error: failure);
      return null;
    }, (customer) => customer);
    if (copy != null) {
      _saved = copy;
      safeEmit(
        state.copyWith(status: AuthSessionStatus.signedIn, customer: copy),
      );
    }
    final result = await _restoreSession(const NoParams());
    if (session != _session) return;
    result.fold(
      (failure) => switch (failure) {
        UnauthorizedFailure() => _expire(),
        // Backend unreachable or failing: the stored session stays valid,
        // and so does the customer on screen.
        NetworkFailure() || TimeoutFailure() || ServerFailure() => safeEmit(
          state.copyWith(status: AuthSessionStatus.signedIn),
        ),
        _ => _end(),
      },
      (customer) => customer == null ? _end() : _confirm(customer),
    );
  }

  void signedIn(AuthCustomerEntity customer) {
    _session++;
    safeEmit(
      state.copyWith(
        status: AuthSessionStatus.signedIn,
        customer: customer,
        isVerified: true,
        expired: false,
      ),
    );
    _persist(customer);
  }

  /// A reply carried the customer record (`PATCH /v1/account/profile`, …):
  /// keep the global snapshot and the device copy in step so every greeting /
  /// header shows the new values. A reply that lands after sign-out, or one
  /// for another customer, is dropped.
  void updateCustomer(AuthCustomerEntity customer) {
    if (!state.isSignedIn) return;
    final current = state.customer;
    if (current != null && current.id != customer.id) return;
    _confirm(customer);
  }

  Future<void> signOut() async {
    if (state.isSigningOut) return;
    safeEmit(state.copyWith(isSigningOut: true));
    final result = await _logout(const NoParams());
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(isSigningOut: false, failure: failure)),
      (_) => _end(expired: false, isSigningOut: false),
    );
  }

  /// The backend's record of the signed-in customer.
  void _confirm(AuthCustomerEntity customer) {
    safeEmit(
      state.copyWith(
        status: AuthSessionStatus.signedIn,
        customer: customer,
        isVerified: true,
      ),
    );
    _persist(customer);
  }

  void _expire() => _end(expired: true);

  void _end({bool? expired, bool? isSigningOut}) {
    _session++;
    safeEmit(
      state.copyWith(
        status: AuthSessionStatus.signedOut,
        clearCustomer: true,
        isVerified: false,
        expired: expired,
        isSigningOut: isSigningOut,
      ),
    );
    _forget();
  }

  /// Writes [customer] unless the device already holds exactly that. The
  /// storage write starts synchronously, so a [_forget] that follows always
  /// clears after it.
  void _persist(AuthCustomerEntity customer) {
    if (customer == _saved) return;
    _saved = customer;
    unawaited(_write(customer));
  }

  Future<void> _write(AuthCustomerEntity customer) async {
    final result = await _saveCachedCustomer(
      SaveCachedCustomerParams(customer),
    );
    result.fold((failure) {
      // Not on disk after all: the next snapshot writes again.
      if (identical(_saved, customer)) _saved = null;
      log('device copy not saved', name: _logName, error: failure);
    }, (_) {});
  }

  void _forget() {
    _saved = null;
    unawaited(_clearDeviceCopy());
  }

  Future<void> _clearDeviceCopy() async {
    final result = await _clearCachedCustomer(const NoParams());
    result.fold(
      (failure) =>
          log('device copy not cleared', name: _logName, error: failure),
      (_) {},
    );
  }

  @override
  Future<void> close() async {
    await _expirySubscription.cancel();
    return super.close();
  }
}
