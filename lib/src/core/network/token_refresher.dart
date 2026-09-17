import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import '../storage/auth_tokens.dart';
import 'api_envelope.dart';
import 'api_exception_mapper.dart';
import 'end_points.dart';

/// Rotates the token pair. Throws an `AppException` when the backend rejects
/// the refresh token or the call cannot reach the server.
abstract class TokenRefresher {
  Future<AuthTokens> refresh(String refreshToken);
}

/// `POST /v1/auth/refresh { refreshToken }` through a BARE Dio client (no
/// interceptors) so a refresh can never trigger another refresh.
///
/// Reference: https://docs.jm3eia.store/developers/auth.html
class ApiTokenRefresher implements TokenRefresher {
  ApiTokenRefresher(this._bareClient);

  final Dio _bareClient;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final response = await _bareClient.post<dynamic>(
        EndPoints.authRefresh,
        data: <String, Object?>{AuthTokens.refreshTokenKey: refreshToken},
      );
      final envelope = ApiEnvelope.tryParse(response.data);
      if (envelope == null) {
        throw const ParsingException('Malformed refresh response');
      }
      if (!envelope.success) throw ApiExceptionMapper.fromEnvelope(envelope);
      final results = envelope.results;
      if (results is! Map) {
        throw const ParsingException('Refresh response has no token pair');
      }
      return AuthTokens.fromJson(results.cast<String, dynamic>());
    } on DioException catch (exception) {
      throw ApiExceptionMapper.fromDio(exception);
    }
  }
}
