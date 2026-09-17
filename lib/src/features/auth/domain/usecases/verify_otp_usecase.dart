import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../entities/otp_challenge.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams extends Equatable {
  const VerifyOtpParams({required this.phone, required this.code});

  final PhoneNumber phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

/// Exchange the typed code for a signed-in session.
class VerifyOtpUseCase implements UseCase<AuthCustomerEntity, VerifyOtpParams> {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(VerifyOtpParams params) =>
      _repository.verifyOtp(
        phone: params.phone,
        code: OtpChallenge.normalizeCode(params.code),
      );
}
