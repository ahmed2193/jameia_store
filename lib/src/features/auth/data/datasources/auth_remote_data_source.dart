import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/data/models/customer_model.dart';
import '../models/auth_session_model.dart';
import '../models/otp_challenge_model.dart';

/// The jm3eia customer-auth endpoints. Receives the envelope's `results`
/// (already unwrapped by `DioConsumer`) and throws `AppException` only.
///
/// Reference: https://docs.jm3eia.store/developers/auth.html
abstract class AuthRemoteDataSource {
  /// `POST /v1/auth/send-otp { phone }` — [phone] in E.164 form.
  Future<OtpChallengeModel> sendOtp(String phone);

  /// `POST /v1/auth/verify-otp { phone, code }` → customer + token pair.
  Future<AuthSessionModel> verifyOtp({
    required String phone,
    required String code,
  });

  /// `POST /v1/auth/logout` (Bearer) — revokes the refresh token.
  Future<void> logout();

  /// `GET /v1/account/me` (Bearer) — validates the stored session at launch.
  Future<CustomerModel> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  // Request-body field names (docs: send-otp / verify-otp).
  static const String _phoneField = 'phone';
  static const String _codeField = 'code';

  @override
  Future<OtpChallengeModel> sendOtp(String phone) async {
    final results = await _api.post(
      EndPoints.authSendOtp,
      body: <String, Object?>{_phoneField: phone},
    );
    return OtpChallengeModel.fromJson(ApiPayload.asMap(results, 'send-otp'));
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final results = await _api.post(
      EndPoints.authVerifyOtp,
      body: <String, Object?>{_phoneField: phone, _codeField: code},
    );
    return AuthSessionModel.fromJson(ApiPayload.asMap(results, 'verify-otp'));
  }

  @override
  Future<void> logout() => _api.post(EndPoints.authLogout);

  @override
  Future<CustomerModel> me() async {
    final results = await _api.get(EndPoints.accountMe);
    return CustomerModel.fromJson(ApiPayload.asMap(results, 'account/me'));
  }
}
