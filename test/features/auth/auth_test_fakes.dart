import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:jameia_mart/src/features/auth/domain/usecases/watch_session_expiry_usecase.dart';

const PhoneNumber kPhone = PhoneNumber.kuwait('12345678');
const AuthCustomerEntity kCustomer = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  nameEn: 'Ahmed',
  nameAr: 'أحمد',
);
const OtpChallenge kChallenge = OtpChallenge(
  phone: kPhone,
  message: 'Code sent',
  debugCode: '1234',
);

/// Hand-written fakes (no mocktail in this project): each returns its canned
/// [Either] and counts calls.
class FakeSendOtpUseCase implements SendOtpUseCase {
  FakeSendOtpUseCase(this.result);

  Either<Failure, OtpChallenge> result;
  final List<SendOtpParams> calls = [];

  @override
  Future<Either<Failure, OtpChallenge>> call(SendOtpParams params) async {
    calls.add(params);
    return result;
  }
}

class FakeVerifyOtpUseCase implements VerifyOtpUseCase {
  FakeVerifyOtpUseCase(this.result);

  Either<Failure, AuthCustomerEntity> result;
  final List<VerifyOtpParams> calls = [];

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(
    VerifyOtpParams params,
  ) async {
    calls.add(params);
    return result;
  }
}

class FakeLogoutUseCase implements LogoutUseCase {
  FakeLogoutUseCase([this.result = const Right(unit)]);

  Either<Failure, Unit> result;
  int calls = 0;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    calls++;
    return result;
  }
}

class FakeRestoreSessionUseCase implements RestoreSessionUseCase {
  FakeRestoreSessionUseCase(this.result);

  Either<Failure, AuthCustomerEntity?> result;

  @override
  Future<Either<Failure, AuthCustomerEntity?>> call(NoParams params) async =>
      result;
}

class FakeWatchSessionExpiryUseCase implements WatchSessionExpiryUseCase {
  final StreamController<void> controller = StreamController<void>.broadcast();

  void expire() => controller.add(null);

  @override
  Stream<void> call(NoParams params) => controller.stream;
}
