import 'package:flutter/foundation.dart';

import '../../../features/auth/domain/entities/phone_number.dart';

/// `extra` for [Routes.otpVerify]: the phone the code was sent to, plus the
/// code itself when a non-production backend echoed it, and where to go once
/// signed in ([returnTo], carried over from the login's `LoginArgs`).
@immutable
class OtpVerifyArgs {
  const OtpVerifyArgs({required this.phone, this.debugCode, this.returnTo});

  final PhoneNumber phone;
  final String? debugCode;

  /// Opened on top of the shell after sign-in; `null` = the shell alone.
  final String? returnTo;
}
