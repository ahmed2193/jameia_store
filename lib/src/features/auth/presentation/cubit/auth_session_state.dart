import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';

enum AuthSessionStatus { unknown, signedOut, signedIn }

/// App-global sign-in state. [customer] is the last known snapshot of the
/// signed-in customer: the device copy at launch until the backend answers,
/// then the server's record ([isVerified]). It is `null` while signed in
/// offline with nothing saved. [expired] is sticky until the next sign-in so
/// the root can route to login exactly once per expiry.
class AuthSessionState extends Equatable {
  const AuthSessionState({
    this.status = AuthSessionStatus.unknown,
    this.customer,
    this.isVerified = false,
    this.expired = false,
    this.isSigningOut = false,
    this.failure,
  });

  final AuthSessionStatus status;
  final AuthCustomerEntity? customer;

  /// The backend confirmed [customer] during this run (OTP verification,
  /// the launch `GET /v1/account/me`, or a profile reply). `false` while the
  /// device copy is all the app has.
  final bool isVerified;
  final bool expired;

  /// Sign-out request in flight (guards re-entry; UI shows a loader).
  final bool isSigningOut;

  /// Transient — cleared on every [copyWith]; the UI localizes it.
  final Failure? failure;

  bool get isSignedIn => status == AuthSessionStatus.signedIn;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    AuthCustomerEntity? customer,
    bool clearCustomer = false,
    bool? isVerified,
    bool? expired,
    bool? isSigningOut,
    Failure? failure,
  }) => AuthSessionState(
    status: status ?? this.status,
    customer: clearCustomer ? null : (customer ?? this.customer),
    isVerified: isVerified ?? this.isVerified,
    expired: expired ?? this.expired,
    isSigningOut: isSigningOut ?? this.isSigningOut,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    customer,
    isVerified,
    expired,
    isSigningOut,
    failure,
  ];
}
