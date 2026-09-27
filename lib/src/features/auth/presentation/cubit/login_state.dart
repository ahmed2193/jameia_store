import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/phone_number.dart';

enum LoginStatus { initial, sending, codeSent, error }

/// Login screen state: the typed phone, the send-OTP request status and the
/// store's welcome offer.
class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.phone = PhoneNumber.empty,
    this.challenge,
    this.failure,
    this.welcomeBonus = 0,
  });

  final LoginStatus status;
  final PhoneNumber phone;

  /// Set when [status] is [LoginStatus.codeSent]; the page navigates with it.
  /// Cleared when the phone changes so it never disagrees with [phone].
  final OtpChallenge? challenge;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Points a new account gets today (`store.loyalty`); 0 while unknown or
  /// when the store runs no welcome bonus — the card then promises nothing.
  final int welcomeBonus;

  bool get isSending => status == LoginStatus.sending;

  /// Gates the primary CTA.
  bool get canContinue => phone.isValid && !isSending;

  /// Inline validation line: shown once the user started typing.
  bool get showPhoneError => !phone.isEmpty && !phone.isValid;

  bool get hasWelcomeBonus => welcomeBonus > 0;

  LoginState copyWith({
    LoginStatus? status,
    PhoneNumber? phone,
    OtpChallenge? challenge,
    bool clearChallenge = false,
    Failure? failure,
    int? welcomeBonus,
  }) => LoginState(
    status: status ?? this.status,
    phone: phone ?? this.phone,
    challenge: clearChallenge ? null : (challenge ?? this.challenge),
    failure: failure,
    welcomeBonus: welcomeBonus ?? this.welcomeBonus,
  );

  @override
  List<Object?> get props => [status, phone, challenge, failure, welcomeBonus];
}
