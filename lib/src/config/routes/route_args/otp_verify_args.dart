import 'package:flutter/foundation.dart';

import '../../../features/auth/domain/entities/phone_number.dart';

/// `extra` for [Routes.otpVerify]: the phone the code was sent to, plus the
/// code itself when a non-production backend echoed it.
@immutable
class OtpVerifyArgs {
  const OtpVerifyArgs({required this.phone, this.debugCode});

  final PhoneNumber phone;
  final String? debugCode;
}
