/// `results` of `POST /v1/auth/send-otp`:
/// `{ "message": "<localized>", "code": "1234" }` — `code` only on
/// non-production backends.
class OtpChallengeModel {
  const OtpChallengeModel({required this.message, this.code});

  static const String messageKey = 'message';
  static const String codeKey = 'code';

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) {
    final message = json[messageKey];
    final code = json[codeKey];
    return OtpChallengeModel(
      message: message is String ? message : '',
      code: code?.toString(),
    );
  }

  final String message;
  final String? code;
}
