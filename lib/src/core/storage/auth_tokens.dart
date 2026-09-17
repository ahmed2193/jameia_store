import 'package:equatable/equatable.dart';

import '../error/exceptions.dart';

/// The token pair the backend issues on OTP verification and on every refresh.
///
/// ```json
/// { "accessToken": "<JWT>", "refreshToken": "<opaque>",
///   "tokenType": "Bearer", "expiresIn": 900 }
/// ```
///
/// Access tokens live 15 minutes, refresh tokens 30 days; each refresh revokes
/// the previous refresh token, so ALWAYS persist the whole pair together.
///
/// Reference: https://docs.jm3eia.store/developers/auth.html
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = defaultExpiresInSeconds,
    this.tokenType = defaultTokenType,
  });

  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String expiresInKey = 'expiresIn';
  static const String tokenTypeKey = 'tokenType';

  /// Documented access-token TTL (15 min) when the payload omits it.
  static const int defaultExpiresInSeconds = 900;
  static const String defaultTokenType = 'Bearer';

  /// Throws [ParsingException] when either token is missing/empty.
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = json[accessTokenKey];
    final refresh = json[refreshTokenKey];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const ParsingException('Token pair missing from response');
    }
    final tokenType = json[tokenTypeKey];
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresIn:
          (json[expiresInKey] as num?)?.toInt() ?? defaultExpiresInSeconds,
      tokenType: tokenType is String && tokenType.isNotEmpty
          ? tokenType
          : defaultTokenType,
    );
  }

  final String accessToken;
  final String refreshToken;

  /// Access-token lifetime in seconds.
  final int expiresIn;
  final String tokenType;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn, tokenType];
}
