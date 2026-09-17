import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';

enum AuthSessionStatus { unknown, signedOut, signedIn }

/// App-global sign-in state. [customer] is known once the backend validated
/// the session (OTP verification or launch-time restore) and `null` while
/// signed in offline. [expired] is sticky until the next sign-in so the root
/// can route to login exactly once per expiry.
class AuthSessionState extends Equatable {
  const AuthSessionState({
    this.status = AuthSessionStatus.unknown,
    this.customer,
    this.expired = false,
    this.isSigningOut = false,
    this.failure,
  });

  final AuthSessionStatus status;
  final AuthCustomerEntity? customer;
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
    bool? expired,
    bool? isSigningOut,
    Failure? failure,
  }) => AuthSessionState(
    status: status ?? this.status,
    customer: clearCustomer ? null : (customer ?? this.customer),
    expired: expired ?? this.expired,
    isSigningOut: isSigningOut ?? this.isSigningOut,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, customer, expired, isSigningOut, failure];
}
