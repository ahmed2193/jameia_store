import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/otp_challenge.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

class SendOtpParams extends Equatable {
  const SendOtpParams({required this.phone});

  final PhoneNumber phone;

  @override
  List<Object?> get props => [phone];
}

/// Request a one-time code for a phone number (login and resend).
class SendOtpUseCase implements UseCase<OtpChallenge, SendOtpParams> {
  const SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, OtpChallenge>> call(SendOtpParams params) =>
      _repository.sendOtp(params.phone);
}
