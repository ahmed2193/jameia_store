import 'package:equatable/equatable.dart';

import 'phone_number.dart';

/// The result of `POST /v1/auth/send-otp`: a code was sent to [phone].
/// [debugCode] is only present on non-production backends (the docs expose the
/// code so testers can skip the SMS); the OTP screen shows it as a hint.
///
/// Also owns the code rules (length range, normalization) so presentation
/// never re-implements them.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.phone,
    required this.message,
    this.debugCode,
  });

  /// Backend-validated code length (docs: 4–8 characters).
  static const int minCodeLength = 4;
  static const int maxCodeLength = 8;

  static final RegExp _nonDigits = RegExp(r'\D');

  final PhoneNumber phone;

  /// Localized confirmation from the backend.
  final String message;

  final String? debugCode;

  bool get hasDebugCode => debugCode != null && debugCode!.isNotEmpty;

  /// Digits only, capped at [maxCodeLength] — what typed/pasted input becomes.
  static String normalizeCode(String raw) {
    final digits = raw.replaceAll(_nonDigits, '');
    return digits.length > maxCodeLength
        ? digits.substring(0, maxCodeLength)
        : digits;
  }

  static bool isCodeComplete(String code) =>
      code.length >= minCodeLength && code.length <= maxCodeLength;

  @override
  List<Object?> get props => [phone, message, debugCode];
}
