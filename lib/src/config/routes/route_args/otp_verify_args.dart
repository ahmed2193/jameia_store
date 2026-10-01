import 'package:flutter/foundation.dart';

import '../../../features/auth/domain/entities/phone_number.dart';
import 'login_args.dart';

/// `extra` for [Routes.otpVerify]: the phone the code was sent to, plus the
/// code itself when a non-production backend echoed it, and the phone step's
/// [login] args — where the customer goes once signed in.
@immutable
class OtpVerifyArgs {
  const OtpVerifyArgs({
    required this.phone,
    this.debugCode,
    this.login = const LoginArgs(),
  });

  final PhoneNumber phone;
  final String? debugCode;

  /// Carried over from the phone step: the way back once signed in.
  final LoginArgs login;
}
