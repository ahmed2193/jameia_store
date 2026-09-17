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

  AuthSessionCubit build() => AuthSessionCubit(
    restoreSession: restoreSession,
    logout: logout,
    watchExpiry: watchExpiry,
  );

  const signedIn = AuthSessionState(
    status: AuthSessionStatus.signedIn,
    customer: kCustomer,
  );

  setUp(() {
    restoreSession = FakeRestoreSessionUseCase(const Right(kCustomer));
    logout = FakeLogoutUseCase();
    watchExpiry = FakeWatchSessionExpiryUseCase();
  });

  tearDown(() => watchExpiry.controller.close());

  group('restore', () {
    blocTest<AuthSessionCubit, AuthSessionState>(
      'signedIn with the customer the backend validated',
      build: build,
      act: (cubit) => cubit.restore(),
      expect: () => [signedIn],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'signedOut when nothing is stored',
      build: () {
        restoreSession.result = const Right(null);
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'offline keeps the stored session (signedIn, no customer yet)',
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
      'an unreadable keychain means signedOut (nothing to restore)',
      build: () {
        restoreSession.result = const Left(CacheFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'a rejected refresh means signedOut + expired',
      build: () {
        restoreSession.result = const Left(UnauthorizedFailure());
        return build();
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        const AuthSessionState(
          status: AuthSessionStatus.signedOut,
          expired: true,
        ),
      ],
    );
  });

  blocTest<AuthSessionCubit, AuthSessionState>(
    'signedIn stores the customer and clears a previous expiry',
    build: build,
    seed: () => const AuthSessionState(
      status: AuthSessionStatus.signedOut,
      expired: true,
    ),
    act: (cubit) => cubit.signedIn(kCustomer),
    expect: () => [signedIn],
  );

  group('signOut', () {
    blocTest<AuthSessionCubit, AuthSessionState>(
      'shows a loader, then signedOut without the customer',
      build: build,
      seed: () => signedIn,
      act: (cubit) => cubit.signOut(),
      expect: () => [
        signedIn.copyWith(isSigningOut: true),
        const AuthSessionState(status: AuthSessionStatus.signedOut),
      ],
      verify: (_) => expect(logout.calls, 1),
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'failure keeps the session and surfaces the failure',
      build: () {
        logout.result = const Left(CacheFailure('keychain'));
        return build();
      },
      seed: () => signedIn,
      act: (cubit) => cubit.signOut(),
      expect: () => [
        signedIn.copyWith(isSigningOut: true),
        signedIn.copyWith(failure: const CacheFailure('keychain')),
      ],
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'ignores re-entrant taps while one is in flight',
      build: build,
      seed: () => signedIn.copyWith(isSigningOut: true),
      act: (cubit) => cubit.signOut(),
      expect: () => <AuthSessionState>[],
      verify: (_) => expect(logout.calls, 0),
    );
  });

  blocTest<AuthSessionCubit, AuthSessionState>(
    'a session-expiry event flips to signedOut with expired = true',
    build: build,
    seed: () => signedIn,
    act: (_) => watchExpiry.expire(),
    expect: () => [
      const AuthSessionState(
        status: AuthSessionStatus.signedOut,
        expired: true,
      ),
    ],
  );

  group('updateCustomer', () {
    const edited = AuthCustomerEntity(
      id: '507f1f77bcf86cd799439011',
      phone: '+96512345678',
      nameEn: 'Ahmed Ali',
      nameAr: 'Ahmed Ali',
    );

    blocTest<AuthSessionCubit, AuthSessionState>(
      'replaces the customer snapshot after a profile edit',
      build: build,
      seed: () => signedIn,
      act: (cubit) => cubit.updateCustomer(edited),
      expect: () => [signedIn.copyWith(customer: edited)],
    );
  });
}
