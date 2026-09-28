import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/loyalty_program.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:hero_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:hero_mart/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:hero_mart/src/features/auth/domain/usecases/get_welcome_bonus_usecase.dart';

class _ProgramRepo implements AuthRepository {
  _ProgramRepo(this.result);

  final Either<Failure, LoyaltyProgram> result;

  @override
  Future<Either<Failure, LoyaltyProgram>> getLoyaltyProgram() async => result;

  @override
  Future<Either<Failure, OtpChallenge>> sendOtp(PhoneNumber phone) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AuthCustomerEntity>> verifyOtp({
    required PhoneNumber phone,
    required String code,
  }) => throw UnimplementedError();

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
  Future<Either<Failure, int>> bonusFrom(
    Either<Failure, LoyaltyProgram> program,
  ) => GetWelcomeBonusUseCase(_ProgramRepo(program))(const NoParams());

  test('the points of a running programme with a welcome bonus', () async {
    expect(
      await bonusFrom(
        const Right(LoyaltyProgram(enabled: true, welcomeBonusPoints: 100)),
      ),
      const Right<Failure, int>(100),
    );
  });

  test('0 when the programme is off: nothing is promised', () async {
    expect(
      await bonusFrom(const Right(LoyaltyProgram(welcomeBonusPoints: 100))),
      const Right<Failure, int>(0),
    );
  });

  test('a failed read stays a failure (the cubit keeps quiet)', () async {
    expect(
      await bonusFrom(const Left(NetworkFailure())),
      const Left<Failure, int>(NetworkFailure()),
    );
  });
}
