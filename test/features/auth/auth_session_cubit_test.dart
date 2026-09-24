import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_state.dart';

import 'auth_test_fakes.dart';

void main() {
  late FakeRestoreSessionUseCase restoreSession;
  late FakeLogoutUseCase logout;
  late FakeWatchSessionExpiryUseCase watchExpiry;
  late FakeGetCachedCustomerUseCase getCached;
  late FakeSaveCachedCustomerUseCase saveCached;
  late FakeClearCachedCustomerUseCase clearCached;

  AuthSessionCubit build() => AuthSessionCubit(
    restoreSession: restoreSession,
    logout: logout,
    watchExpiry: watchExpiry,
    getCachedCustomer: getCached,
    saveCachedCustomer: saveCached,
    clearCachedCustomer: clearCached,
  );

  /// The backend's record of the customer.
  const verified = AuthSessionState(
    status: AuthSessionStatus.signedIn,
    customer: kCustomer,
    isVerified: true,
  );

  /// The device copy, before the backend answered.
  const fromDevice = AuthSessionState(
    status: AuthSessionStatus.signedIn,
    customer: kCustomer,
  );

  const edited = AuthCustomerEntity(
    id: '507f1f77bcf86cd799439011',
    phone: '+96512345678',
    nameEn: 'Ahmed Ali',
    nameAr: 'Ahmed Ali',
  );

  setUp(() {
    restoreSession = FakeRestoreSessionUseCase(const Right(kCustomer));
    logout = FakeLogoutUseCase();
    watchExpiry = FakeWatchSessionExpiryUseCase();
    getCached = FakeGetCachedCustomerUseCase();
    saveCached = FakeSaveCachedCustomerUseCase();
    clearCached = FakeClearCachedCustomerUseCase();
  });

  tearDown(() => watchExpiry.controller.close());

  group('restore', () {
    blocTest<AuthSessionCubit, AuthSessionState>(
      'nothing on the device: signedIn with the validated customer, saved',
      build: build,
      act: (cubit) => cubit.restore(),
      expect: () => [verified],
      verify: (_) {
        expect(saveCached.saved, [kCustomer]);
        expect(clearCached.calls, 0);
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'shows the device copy at once, then the backend record (saved)',
      build: () {
        getCached.result = const Right(kCustomer);
        restoreSession.result = const Right(edited);
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        fromDevice,
        const AuthSessionState(
          status: AuthSessionStatus.signedIn,
          customer: edited,
          isVerified: true,
        ),
      ],
      verify: (_) => expect(saveCached.saved, [edited]),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a backend record equal to the device copy is not written again',
      build: () {
        getCached.result = const Right(kCustomer);
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [fromDevice, verified],
      verify: (_) => expect(saveCached.saved, isEmpty),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'offline keeps the device copy on screen, unverified',
      build: () {
        getCached.result = const Right(kCustomer);
        restoreSession.result = const Left(NetworkFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [fromDevice],
      verify: (_) {
        expect(saveCached.saved, isEmpty);
        expect(clearCached.calls, 0);
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'offline with nothing saved keeps the session (signedIn, no customer)',
      build: () {
        restoreSession.result = const Left(NetworkFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(status: AuthSessionStatus.signedIn),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'an unreadable device copy is skipped, the restore goes on',
      build: () {
        getCached.result = const Left(CacheFailure('corrupt'));
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [verified],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'signedOut when nothing is stored, and the device copy is wiped',
      build: () {
        restoreSession.result = const Right(null);
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
      verify: (_) => expect(clearCached.calls, 1),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'an unreadable keychain means signedOut (nothing to restore)',
      build: () {
        restoreSession.result = const Left(CacheFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
      verify: (_) => expect(clearCached.calls, 1),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a rejected refresh drops the device copy: signedOut + expired',
      build: () {
        getCached.result = const Right(kCustomer);
        restoreSession.result = const Left(UnauthorizedFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        fromDevice,
        const AuthSessionState(
          status: AuthSessionStatus.signedOut,
          expired: true,
        ),
      ],
      verify: (_) => expect(clearCached.calls, 1),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'an OTP sign-in that lands while the restore is in flight wins',
      build: () {
        restoreSession.gate = Completer<void>();
        return build();
      },
      act: (cubit) async {
        final restoring = cubit.restore();
        await Future<void>.delayed(Duration.zero);
        cubit.signedIn(edited);
        restoreSession.gate!.complete();
        await restoring;
      },
      expect: () => [
        const AuthSessionState(
          status: AuthSessionStatus.signedIn,
          customer: edited,
          isVerified: true,
        ),
      ],
      verify: (_) => expect(saveCached.saved, [edited]),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a sign-out while the restore is in flight is not undone by it',
      build: () {
        getCached.result = const Right(kCustomer);
        restoreSession.gate = Completer<void>();
        return build();
      },
      act: (cubit) async {
        final restoring = cubit.restore();
        await Future<void>.delayed(Duration.zero);
        await cubit.signOut();
        restoreSession.gate!.complete();
        await restoring;
      },
      expect: () => [
        fromDevice,
        fromDevice.copyWith(isSigningOut: true),
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
      verify: (_) {
        expect(saveCached.saved, isEmpty);
        expect(clearCached.calls, 1);
      },
    );
  });

  blocTest<AuthSessionCubit, AuthSessionState>(
    'signedIn stores the customer, clears a previous expiry and saves it',
    build: build,
    seed: () => const AuthSessionState(
      status: AuthSessionStatus.signedOut,
      expired: true,
    ),
    act: (cubit) => cubit.signedIn(kCustomer),
    expect: () => [verified],
    verify: (_) => expect(saveCached.saved, [kCustomer]),
  );

  group('signOut', () {
    blocTest<AuthSessionCubit, AuthSessionState>(
      'shows a loader, then signedOut without the customer; copy wiped',
      build: build,
      seed: () => verified,
      act: (cubit) => cubit.signOut(),
      expect: () => [
        verified.copyWith(isSigningOut: true),
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
      verify: (_) {
        expect(logout.calls, 1);
        expect(clearCached.calls, 1);
      },
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'failure keeps the session and its copy, and surfaces the failure',
      build: () {
        logout.result = const Left(CacheFailure('keychain'));
        return build();
      },
      seed: () => verified,
      act: (cubit) => cubit.signOut(),
      expect: () => [
        verified.copyWith(isSigningOut: true),
        verified.copyWith(failure: const CacheFailure('keychain')),
      ],
      verify: (_) => expect(clearCached.calls, 0),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'ignores re-entrant taps while one is in flight',
      build: build,
      seed: () => verified.copyWith(isSigningOut: true),
      act: (cubit) => cubit.signOut(),
      expect: () => <AuthSessionState>[],
      verify: (_) => expect(logout.calls, 0),
    );
  });

  blocTest<AuthSessionCubit, AuthSessionState>(
    'a session-expiry event flips to signedOut + expired and wipes the copy',
    build: build,
    seed: () => verified,
    act: (_) => watchExpiry.expire(),
    expect: () => [
      const AuthSessionState(
        status: AuthSessionStatus.signedOut,
        expired: true,
      ),
    ],
    verify: (_) => expect(clearCached.calls, 1),
  );

  group('updateCustomer', () {
    blocTest<AuthSessionCubit, AuthSessionState>(
      'replaces the snapshot after a profile edit and saves it',
      build: build,
      seed: () => verified,
      act: (cubit) => cubit.updateCustomer(edited),
      expect: () => [verified.copyWith(customer: edited)],
      verify: (_) => expect(saveCached.saved, [edited]),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a server reply confirms the device copy',
      build: build,
      seed: () => fromDevice,
      act: (cubit) => cubit.updateCustomer(edited),
      expect: () => [verified.copyWith(customer: edited)],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a reply that lands after sign-out is dropped (never cached)',
      build: build,
      seed: () => const AuthSessionState(status: AuthSessionStatus.signedOut),
      act: (cubit) => cubit.updateCustomer(edited),
      expect: () => <AuthSessionState>[],
      verify: (_) => expect(saveCached.saved, isEmpty),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      "another customer's record is dropped",
      build: build,
      seed: () => verified,
      act: (cubit) => cubit.updateCustomer(
        const AuthCustomerEntity(id: 'someone-else', phone: '+96599999999'),
      ),
      expect: () => <AuthSessionState>[],
      verify: (_) => expect(saveCached.saved, isEmpty),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a save that failed is tried again with the next snapshot',
      build: () {
        saveCached.result = const Left(CacheFailure('disk full'));
        return build();
      },
      seed: () => verified,
      act: (cubit) async {
        cubit.updateCustomer(edited);
        await Future<void>.delayed(Duration.zero);
        cubit.updateCustomer(edited);
      },
      verify: (_) => expect(saveCached.saved, [edited, edited]),
    );
  });
}
