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
    this.codeFailure,
    this.rejections = 0,
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

  /// The backend refused the typed code ([OtpChallenge.isRefusedCode]).
  /// Unlike [failure] it outlives the countdown ticks: it stays under the
  /// digits until the code is edited or a new one is sent.
  final Failure? codeFailure;

  /// Refusals so far — a new value shakes the digits once more.
  final int rejections;

  bool get isVerifying => status == OtpStatus.verifying;
  bool get isVerified => status == OtpStatus.verified;

  /// The code cannot change: it is being checked or it was accepted.
  bool get isLocked => isVerifying || isVerified;
  bool get isCodeRejected => codeFailure != null;

  /// The error just emitted is the refusal of the code (shown under the
  /// digits), not a failed request (shown as a snack bar).
  bool get failureIsRefusal => failure != null && failure == codeFailure;
  bool get isCodeComplete => OtpChallenge.isCodeComplete(code);
  bool get canVerify => isCodeComplete && !isLocked && !isResending;
  bool get isCooldownOver => resendSecondsLeft == 0;
  bool get canResend => isCooldownOver && !isResending && !isLocked;
  bool get hasDebugCode => debugCode != null && debugCode!.isNotEmpty;

  /// Digit slots the input shows (rule in [OtpChallenge.slotCount]).
  int get slotCount => OtpChallenge.slotCount(
    knownCode: hasDebugCode ? debugCode : null,
    typedLength: code.length,
  );

  OtpState copyWith({
    OtpStatus? status,
    String? code,
    String? debugCode,
    int? resendSecondsLeft,
    bool? isResending,
    AuthCustomerEntity? customer,
    Failure? failure,
    Failure? codeFailure,
    bool clearCodeFailure = false,
    int? rejections,
  }) => OtpState(
    phone: phone,
    status: status ?? this.status,
    code: code ?? this.code,
    debugCode: debugCode ?? this.debugCode,
    resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
    isResending: isResending ?? this.isResending,
    customer: customer ?? this.customer,
    failure: failure,
    codeFailure: clearCodeFailure ? null : (codeFailure ?? this.codeFailure),
    rejections: rejections ?? this.rejections,
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
    codeFailure,
    rejections,
  ];
}
