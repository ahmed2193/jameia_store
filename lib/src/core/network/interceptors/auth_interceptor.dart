import 'dart:developer';

import 'package:dio/dio.dart';

import '../../error/exceptions.dart';
import '../../storage/session_store.dart';
import '../api_headers.dart';
import '../end_points.dart';
import '../session_expiry_notifier.dart';
import '../token_refresher.dart';

/// Bearer auth + the documented token lifecycle (access 15 min, refresh 30 d,
/// rotating pair):
///
///   1. `onRequest` — attach `Authorization: Bearer <accessToken>` when a
///      session exists. When the stored token is about to expire (its
///      `expiresIn` minus [expirySkew] has passed) refresh FIRST, so the
///      request goes out with a valid token instead of paying for a 401 round
///      trip. A refresh that cannot reach the server falls back to the current
///      token (the reactive path below then decides).
///   2. `onError` 401 — refresh ONCE via [TokenRefresher] (a bare client, so
///      no recursion), persist the rotated pair, replay the original request
///      through the full chain. The replay is flagged so a second 401 is
///      surfaced, never refreshed again.
///   3. Refresh rejected (400/401/403) → clear tokens + [SessionExpiryNotifier]
///      so the app routes to login. A network blip during refresh keeps the
///      session and surfaces that network error instead.
///
/// Concurrency: a plain [Interceptor] (NOT `QueuedInterceptor`, whose error
/// queue would deadlock on the replay's own 401) with a single-flight refresh
/// future — concurrent 401s / pre-flight checks await the same refresh, and a
/// request whose token was already rotated is replayed straight away.
///
/// Reference: https://docs.jm3eia.store/developers/auth.html
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._session,
    required this._refresher,
    required this._expiry,
    this._expirySkew = defaultExpirySkew,
    this._now = DateTime.now,
  });

  /// Refresh this long BEFORE the stored expiry so clock drift and request
  /// latency never let a token expire in flight.
  static const Duration defaultExpirySkew = Duration(seconds: 30);

  static const String _logName = 'auth';
  static const String _retriedKey = 'auth.retried';
  static const int _unauthorized = 401;
  static const Set<int> _refreshRejectedStatuses = {400, 401, 403};

  final Dio _dio;
  final SessionStore _session;
  final TokenRefresher _refresher;
  final SessionExpiryNotifier _expiry;
  final Duration _expirySkew;
  final DateTime Function() _now;

  /// The in-flight refresh, shared by every 401 that arrives while it runs.
  /// Resolves to the new access token, or `null` when the session is over.
  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var accessToken = await _session.readAccessToken();
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !EndPoints.authPaths.contains(options.path) &&
        await _isExpiring()) {
      accessToken = await _preflightRefresh(accessToken, options);
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers[ApiHeaders.authorization] =
          '${ApiHeaders.bearerPrefix}$accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != _unauthorized ||
        options.extra[_retriedKey] == true ||
        EndPoints.authPaths.contains(options.path)) {
      return handler.next(err);
    }

    log(
      '401 ${options.method} ${options.path} → refreshing session',
      name: _logName,
    );
    final String? freshToken;
    try {
      freshToken = await _freshTokenFor(_bearerOf(options));
    } on AppException catch (exception) {
      log('refresh failed: $exception', name: _logName);
      return handler.reject(_wrap(options, exception));
    }
    if (freshToken == null) return handler.next(err); // no session to recover

    log(
      'replaying ${options.method} ${options.path} with the rotated token',
      name: _logName,
    );
    options.extra[_retriedKey] = true;
    options.headers[ApiHeaders.authorization] =
        '${ApiHeaders.bearerPrefix}$freshToken';
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// `true` once the stored access token is within [expirySkew] of its expiry.
  Future<bool> _isExpiring() async {
    final expiresAt = await _session.readAccessTokenExpiry();
    if (expiresAt == null) return false;
    return !_now().toUtc().isBefore(expiresAt.subtract(_expirySkew));
  }

  /// Rotate the pair before sending. Returns the token to send: the fresh one,
  /// [current] when the refresh could not reach the server (the reactive path
  /// gets another try on the 401), or `null` when the refresh was rejected
  /// (session wiped — the request goes out anonymous and fails as 401).
  Future<String?> _preflightRefresh(
    String current,
    RequestOptions options,
  ) async {
    log(
      'access token expiring → refreshing before '
      '${options.method} ${options.path}',
      name: _logName,
    );
    try {
      return await _freshTokenFor(current);
    } on AppException catch (exception) {
      log(
        'pre-flight refresh failed ($exception); sending the current token',
        name: _logName,
      );
      return current;
    }
  }

  /// A token that differs from [failedToken]: the stored one when another
  /// request already rotated the pair, else the result of ONE shared refresh.
  /// `null` when signed out or the refresh was rejected.
  ///
  /// Single-flight for real: the in-flight future is joined / installed
  /// SYNCHRONOUSLY, with no `await` between the check and the assignment, so
  /// two callers can never both start a rotation (the second one would present
  /// an already-revoked refresh token and log the customer out).
  Future<String?> _freshTokenFor(String? failedToken) =>
      _refreshing ??= _rotate(failedToken)
          .whenComplete(() => _refreshing = null);

  Future<String?> _rotate(String? failedToken) async {
    // A rotation that finished just before this one started already stored a
    // newer token: use it instead of spending the (now revoked) refresh token.
    final current = await _session.readAccessToken();
    if (current != null && current.isNotEmpty && current != failedToken) {
      return current;
    }
    final refreshToken = await _session.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    return _refresh(refreshToken);
  }

  Future<String?> _refresh(String refreshToken) async {
    try {
      final tokens = await _refresher.refresh(refreshToken);
      await _session.saveTokens(tokens);
      log(
        'session refreshed (access token valid ${tokens.expiresIn}s)',
        name: _logName,
      );
      return tokens.accessToken;
    } on ServerException catch (exception) {
      if (!_refreshRejectedStatuses.contains(exception.statusCode)) rethrow;
      log(
        'refresh rejected (${exception.statusCode} ${exception.code}) '
        '→ session expired',
        name: _logName,
      );
      await _session.clearTokens();
      _expiry.notifyExpired();
      return null;
    }
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers[ApiHeaders.authorization];
    if (header is! String || !header.startsWith(ApiHeaders.bearerPrefix)) {
      return null;
    }
    return header.substring(ApiHeaders.bearerPrefix.length);
  }

  /// Carries an already-typed [AppException] through Dio so
  /// `ApiExceptionMapper.fromDio` returns it unchanged.
  static DioException _wrap(RequestOptions options, AppException cause) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: cause,
        message: cause.message,
      );
}
