import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/auth_tokens.dart';
import 'package:jameia_mart/src/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:jameia_mart/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:jameia_mart/src/core/data/models/customer_model.dart';
import 'package:jameia_mart/src/features/auth/data/models/auth_session_model.dart';
import 'package:jameia_mart/src/features/auth/data/models/otp_challenge_model.dart';
import 'package:jameia_mart/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';

import 'auth_test_fakes.dart';

const AuthTokens _tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

class _FakeRemote implements AuthRemoteDataSource {
  Object? sendError;
  Object? verifyError;
  Object? logoutError;
  final List<String> sentTo = [];
  final List<(String phone, String code)> verified = [];
  int logoutCalls = 0;

  @override
  Future<OtpChallengeModel> sendOtp(String phone) async {
    if (sendError != null) throw sendError!;
    sentTo.add(phone);
    return const OtpChallengeModel(message: 'sent', code: '1234');
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String phone,
    required String code,
  }) async {
    if (verifyError != null) throw verifyError!;
    verified.add((phone, code));
    return const AuthSessionModel(
      customer: CustomerModel(
        id: '507f1f77bcf86cd799439011',
        phone: '+96512345678',
        nameEn: 'Ahmed',
      ),
      tokens: _tokens,
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }

  Object? meError;
  int meCalls = 0;

  @override
  Future<CustomerModel> me() async {
    meCalls++;
    if (meError != null) throw meError!;
    return const CustomerModel(
      id: '507f1f77bcf86cd799439011',
      phone: '+96512345678',
      nameEn: 'Ahmed',
      nameAr: 'أحمد',
    );
  }
}

class _FakeLocal implements AuthLocalDataSource {
  AuthTokens? saved;
  int clearCalls = 0;
  bool stored = false;

  @override
  Future<void> saveSession(AuthTokens tokens) async => saved = tokens;

  @override
  Future<void> clearSession() async => clearCalls++;

  @override
  Future<bool> hasSession() async => stored;

  @override
  Stream<void> get onSessionExpired => const Stream<void>.empty();

  CustomerModel? customer;
  Object? customerError;
  final List<CustomerModel> savedCustomers = [];
  int clearCustomerCalls = 0;

  @override
  Future<CustomerModel?> readCustomer() async {
    if (customerError != null) throw customerError!;
    return customer;
  }

  @override
  Future<void> saveCustomer(CustomerModel customer) async {
    if (customerError != null) throw customerError!;
    savedCustomers.add(customer);
  }

  @override
  Future<void> clearCustomer() async => clearCustomerCalls++;
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  });

  test('sendOtp sends the E.164 phone and maps to OtpChallenge', () async {
    final result = await repository.sendOtp(kPhone);

    expect(remote.sentTo, ['+96512345678']);
    expect(
      result,
      const Right<Failure, OtpChallenge>(
        OtpChallenge(phone: kPhone, message: 'sent', debugCode: '1234'),
      ),
    );
  });

  test('sendOtp maps a typed exception to its Failure', () async {
    remote.sendError = const RateLimitedException(
      'slow down',
      code: 'TOO_MANY_ATTEMPTS',
      retryAfter: Duration(seconds: 30),
    );

    final result = await repository.sendOtp(kPhone);

    expect(
      result,
      const Left<Failure, OtpChallenge>(
        RateLimitedFailure('slow down', retryAfter: Duration(seconds: 30)),
      ),
    );
  });

  test('verifyOtp stores the token pair and returns the customer', () async {
    final result = await repository.verifyOtp(phone: kPhone, code: '1234');

    expect(remote.verified, [('+96512345678', '1234')]);
    expect(local.saved, _tokens);
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (customer) => expect(
        customer,
        const AuthCustomerEntity(
          id: '507f1f77bcf86cd799439011',
          phone: '+96512345678',
          nameEn: 'Ahmed',
        ),
      ),
    );
  });

  test('verifyOtp failure stores nothing', () async {
    remote.verifyError = const BadRequestException(
      'Wrong code',
      code: 'INVALID_CREDENTIALS',
    );

    final result = await repository.verifyOtp(phone: kPhone, code: '0000');

    expect(local.saved, isNull);
    expect(
      result,
      const Left<Failure, Object>(
        ServerFailure(
          'Wrong code',
          statusCode: 400,
          code: 'INVALID_CREDENTIALS',
        ),
      ),
    );
  });

  test('logout revokes remotely and clears locally', () async {
    final result = await repository.logout();

    expect(remote.logoutCalls, 1);
    expect(local.clearCalls, 1);
    expect(result, const Right<Failure, Unit>(unit));
  });

  test(
    'logout still clears the local session when the server is unreachable',
    () async {
      remote.logoutError = const NoInternetConnectionException();

      final result = await repository.logout();

      expect(local.clearCalls, 1);
      expect(result, const Right<Failure, Unit>(unit));
    },
  );

  group('restoreSession', () {
    test(
      'no stored session → Right(null) without calling the backend',
      () async {
        expect(
          await repository.restoreSession(),
          const Right<Failure, Object?>(null),
        );
        expect(remote.meCalls, 0);
      },
    );

    test('stored session → validated customer', () async {
      local.stored = true;
      final result = await repository.restoreSession();
      expect(remote.meCalls, 1);
      expect(result, const Right<Failure, Object?>(kCustomer));
    });

    test(
      'refresh rejected (401) → UnauthorizedFailure and the session is wiped',
      () async {
        local.stored = true;
        remote.meError = const UnauthorizedException(
          'expired',
          code: 'TOKEN_EXPIRED',
        );
        final result = await repository.restoreSession();
        expect(
          result,
          const Left<Failure, Object?>(UnauthorizedFailure('expired')),
        );
        expect(local.clearCalls, 1);
      },
    );

    test('offline → NetworkFailure and the session is kept', () async {
      local.stored = true;
      remote.meError = const NoInternetConnectionException();
      final result = await repository.restoreSession();
      expect(
        result,
        const Left<Failure, Object?>(NetworkFailure('No internet connection')),
      );
      expect(local.clearCalls, 0);
    });
  });

  group('device copy of the customer', () {
    const saved = CustomerModel(
      id: '507f1f77bcf86cd799439011',
      phone: '+96512345678',
      nameEn: 'Ahmed',
      nameAr: 'أحمد',
    );

    test('no stored session → no copy, even when one is on disk', () async {
      local.customer = saved;
      expect(
        await repository.getCachedCustomer(),
        const Right<Failure, Object?>(null),
      );
    });

    test('a stored session → the saved customer as the entity', () async {
      local
        ..stored = true
        ..customer = saved;
      expect(
        await repository.getCachedCustomer(),
        const Right<Failure, Object?>(kCustomer),
      );
    });

    test('an unreadable copy → CacheFailure', () async {
      local
        ..stored = true
        ..customerError = const CacheException('corrupt');
      expect(
        await repository.getCachedCustomer(),
        const Left<Failure, Object?>(CacheFailure('corrupt')),
      );
    });

    test('save writes the API shape of the entity', () async {
      final result = await repository.saveCachedCustomer(kCustomer);

      expect(result, const Right<Failure, Unit>(unit));
      expect(local.savedCustomers.single.toJson(), saved.toJson());
    });

    test('a refused save → CacheFailure', () async {
      local.customerError = const CacheException('refused');
      expect(
        await repository.saveCachedCustomer(kCustomer),
        const Left<Failure, Unit>(CacheFailure('refused')),
      );
    });

    test('clear removes the copy', () async {
      expect(
        await repository.clearCachedCustomer(),
        const Right<Failure, Unit>(unit),
      );
      expect(local.clearCustomerCalls, 1);
    });
  });
}
