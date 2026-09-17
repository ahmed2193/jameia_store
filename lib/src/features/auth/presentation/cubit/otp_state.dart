import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/phone_number.dart';

enum OtpStatus { idle, verifying, verified, error }

/// OTP screen state: the typed code, the verify request status and the
/// resend cooldown.
class OtpState extends Equatable {
  const OtpState({
    required this.phone,
    this.status = OtpStatus.idle,
    this.code = '',
    this.debugCode,
    this.resendSecondsLeft = 0,
    this.isResending = false,
    this.customer,
    this.failure,
  });

  final PhoneNumber phone;
  final OtpStatus status;
  final String code;

  /// Non-production backends echo the code; shown as a tap-to-fill hint.
  final String? debugCode;

  final int resendSecondsLeft;
  final bool isResending;

  /// Set when [status] is [OtpStatus.verified].
  final AuthCustomerEntity? customer;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isVerifying => status == OtpStatus.verifying;
  bool get isCodeComplete => OtpChallenge.isCodeComplete(code);
  bool get canVerify => isCodeComplete && !isVerifying && !isResending;
  bool get isCooldownOver => resendSecondsLeft == 0;
  bool get canResend => isCooldownOver && !isResending && !isVerifying;
  bool get hasDebugCode => debugCode != null && debugCode!.isNotEmpty;

  OtpState copyWith({
    OtpStatus? status,
    String? code,
    String? debugCode,
    int? resendSecondsLeft,
    bool? isResending,
    AuthCustomerEntity? customer,
    Failure? failure,
  }) => OtpState(
    phone: phone,
    status: status ?? this.status,
    code: code ?? this.code,
    debugCode: debugCode ?? this.debugCode,
    resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
    isResending: isResending ?? this.isResending,
    customer: customer ?? this.customer,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    phone,
    status,
    code,
    debugCode,
    resendSecondsLeft,
    isResending,
    customer,
    failure,
  ];
}
