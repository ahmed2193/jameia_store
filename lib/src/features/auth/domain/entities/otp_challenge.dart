import 'package:equatable/equatable.dart';

import '../../../../core/domain/text/ascii_digits.dart';
import '../../../../core/error/failures.dart';
import 'phone_number.dart';

/// The result of `POST /v1/auth/send-otp`: a code was sent to [phone].
/// [debugCode] is only present on non-production backends (the docs expose the
/// code so testers can skip the SMS); the OTP screen shows it as a hint.
///
/// Also owns the code rules (length range, normalization, how many slots to
/// show, what a refused code looks like) so presentation never re-implements
/// them.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.phone,
    required this.message,
    this.debugCode,
  });

  /// Backend-validated code length (docs: 4–8 characters).
  static const int minCodeLength = 4;
  static const int maxCodeLength = 8;

  /// `statusMessage` codes that mean "this code is not the one we sent".
  /// Mirrors `ApiStatus.invalidCredentials` / `ApiStatus.validationError`
  /// (`core/network`, which the domain may not import — a test pins them).
  static const String invalidCredentialsStatus = 'INVALID_CREDENTIALS';
  static const String validationErrorStatus = 'VALIDATION_ERROR';

  final PhoneNumber phone;

  /// Localized confirmation from the backend.
  final String message;

  final String? debugCode;

  bool get hasDebugCode => debugCode != null && debugCode!.isNotEmpty;

  /// ASCII digits only (Arabic-Indic / Persian digits mapped first), capped
  /// at [maxCodeLength] — what typed / pasted / autofilled input becomes.
  static String normalizeCode(String raw) {
    final digits = asciiDigitsOnly(raw);
    return digits.length > maxCodeLength
        ? digits.substring(0, maxCodeLength)
        : digits;
  }

  static bool isCodeComplete(String code) =>
      code.length >= minCodeLength && code.length <= maxCodeLength;

  /// How many digit slots the code input shows: the length of the code the
  /// backend echoed when it did ([knownCode]), otherwise [minCodeLength],
  /// growing with what was typed up to [maxCodeLength].
  static int slotCount({String? knownCode, required int typedLength}) {
    final known = knownCode?.length ?? 0;
    final expected = isCodeComplete(knownCode ?? '') ? known : minCodeLength;
    return (typedLength > expected ? typedLength : expected).clamp(
      minCodeLength,
      maxCodeLength,
    );
  }

  /// A whole code arrived in one edit (paste, SMS autofill, the test-code
  /// hint) rather than digit by digit — the screen submits it by itself.
  static bool arrivedAtOnce({
    required String previous,
    required String current,
  }) =>
      current.length - previous.length >= minCodeLength &&
      isCodeComplete(current);

  /// The backend refused the code itself (wrong / expired / malformed), as
  /// opposed to the request failing. A 401 on `verify-otp` is never a session
  /// problem (auth routes are not refreshed), so it is a refused code too.
  static bool isRefusedCode(Failure failure) => switch (failure) {
    UnauthorizedFailure() => true,
    NotFoundFailure() => false,
    ServerFailure(:final code) =>
      code == invalidCredentialsStatus || code == validationErrorStatus,
    _ => false,
  };

  @override
  List<Object?> get props => [phone, message, debugCode];
}
