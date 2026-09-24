import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:jameia_mart/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/verify_otp_usecase.dart';

import 'auth_test_fakes.dart';

class _RecordingRepo implements AuthRepository {
  String? code;

  @override
  Future<Either<Failure, AuthCustomerEntity>> verifyOtp({
    required PhoneNumber phone,
    required String code,
  }) async {
    this.code = code;
    return const Right(kCustomer);
  }

  @override
  Future<Either<Failure, OtpChallenge>> sendOtp(PhoneNumber phone) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AuthCustomerEntity?>> restoreSession() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() => throw UnimplementedError();

  @override
  Stream<void> watchSessionExpiry() => const Stream<void>.empty();

  @override
  Future<Either<Failure, AuthCustomerEntity?>> getCachedCustomer() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> saveCachedCustomer(
    AuthCustomerEntity customer,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> clearCachedCustomer() =>
      throw UnimplementedError();
}

void main() {
  test('normalizes the code before handing it to the repository', () async {
    final repo = _RecordingRepo();
    final result = await VerifyOtpUseCase(repo)(
      const VerifyOtpParams(phone: kPhone, code: ' 12-34 '),
    );
    expect(repo.code, '1234');
    expect(result, const Right<Failure, AuthCustomerEntity>(kCustomer));
  });
}
