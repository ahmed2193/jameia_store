import 'package:dio/dio.dart';

import '../../storage/session_store.dart';
import '../api_headers.dart';
import '../locale_provider.dart';

/// Attaches the cross-cutting request headers every jm3eia call needs:
///
///   * `Accept-Language` — from [LocaleProvider] (backend localizes strings).
///   * `X-Cart-Token` + `X-Assistant-Guest` — ONLY while signed out. Signed-in
///     customers identify with the Bearer token (set by `AuthInterceptor`) and
///     the docs require the guest headers be dropped after login.
///
/// A header a caller set explicitly on the request is never overwritten.
class AppHeadersInterceptor extends Interceptor {
  AppHeadersInterceptor({required this._locale, required this._session});

  final LocaleProvider _locale;
  final SessionStore _session;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final headers = options.headers;
    headers.putIfAbsent(ApiHeaders.acceptLanguage, () => _locale.languageCode);

    if (!await _session.isSignedIn) {
      final cartToken = await _session.readCartToken();
      if (cartToken != null && cartToken.isNotEmpty) {
        headers.putIfAbsent(ApiHeaders.cartToken, () => cartToken);
      }
      final guestKey = await _session.ensureAssistantGuestKey();
      headers.putIfAbsent(ApiHeaders.assistantGuest, () => guestKey);
    }
    handler.next(options);
  }
}
