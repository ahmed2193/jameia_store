import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hero_mart/src/core/network/locale_provider.dart';
import 'package:hero_mart/src/core/network/network_info.dart';
import 'package:hero_mart/src/core/network/session_expiry_notifier.dart';
import 'package:hero_mart/src/core/network/token_refresher.dart';
import 'package:hero_mart/src/core/storage/auth_tokens.dart';
import 'package:hero_mart/src/core/storage/session_store.dart';

/// Scripted transport: every request is recorded and answered by [handler]
/// (which receives the 0-based call index).
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options, int call)
  handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Snapshot: a replayed request reuses (and mutates) the same instance.
    requests.add(options.copyWith());
    return handler(options, requests.length - 1);
  }

  @override
  void close({bool force = false}) {}
}

/// A Hero envelope body with the given status.
ResponseBody envelope({
  required int status,
  required String statusMessage,
  Object? results,
  String? errorMessage,
  List<Object?> errorData = const [],
  Map<String, List<String>> headers = const {},
}) {
  final success = status < 400;
  return ResponseBody.fromString(
    jsonEncode(<String, Object?>{
      'success': success,
      'statusCode': status,
      'statusMessage': statusMessage,
      'results': success ? results : null,
      'error': success ? null : {'message': errorMessage, 'data': errorData},
    }),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

ResponseBody okBody(Object? results) =>
    envelope(status: 200, statusMessage: 'SUCCESS', results: results);

class InMemorySessionStore implements SessionStore {
  String? accessToken;
  String? refreshToken;
  DateTime? accessTokenExpiry;
  String? cartToken;
  String? assistantGuestKey;
  int clearTokensCalls = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> readAccessTokenExpiry() async => accessTokenExpiry;

  @override
  Future<bool> get isSignedIn async =>
      accessToken != null && accessToken!.isNotEmpty;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    accessToken = tokens.accessToken;
    refreshToken = tokens.refreshToken;
    accessTokenExpiry = DateTime.now().toUtc().add(
      Duration(seconds: tokens.expiresIn),
    );
  }

  @override
  Future<void> clearTokens() async {
    clearTokensCalls++;
    accessToken = null;
    refreshToken = null;
    accessTokenExpiry = null;
  }

  @override
  Future<String?> readCartToken() async => cartToken;

  @override
  Future<void> saveCartToken(String token) async => cartToken = token;

  @override
  Future<String> ensureAssistantGuestKey() async =>
      assistantGuestKey ??= 'a' * 32;

  @override
  Future<void> clearGuestSession() async {
    cartToken = null;
    assistantGuestKey = null;
  }

  @override
  Future<void> clearAll() async {
    await clearTokens();
    await clearGuestSession();
  }
}

class FakeTokenRefresher implements TokenRefresher {
  FakeTokenRefresher(this.onRefresh);

  final FutureOr<AuthTokens> Function(String refreshToken) onRefresh;
  int calls = 0;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    calls++;
    return onRefresh(refreshToken);
  }
}

class FakeLocaleProvider implements LocaleProvider {
  FakeLocaleProvider(this.languageCode);

  @override
  String languageCode;
}

class RecordingExpiryNotifier implements SessionExpiryNotifier {
  int expiredCalls = 0;

  @override
  Stream<void> get onSessionExpired => const Stream<void>.empty();

  @override
  void notifyExpired() => expiredCalls++;
}

/// A controllable reachability monitor: nothing probes the internet. [emit]
/// pushes a change; [checkNow] answers [checkResult] (and reports it).
class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({this.isReachable = true, this.checkResult = true});

  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  @override
  bool? isReachable;

  bool checkResult;
  int checkCalls = 0;
  int reachableReports = 0;
  int transportFailureReports = 0;
  bool paused = false;

  /// Whether anyone listens (the monitor would be running).
  bool get hasListener => _changes.hasListener;

  void emit(bool reachable) {
    isReachable = reachable;
    _changes.add(reachable);
  }

  @override
  Stream<bool> get onReachabilityChanged => _changes.stream;

  @override
  Future<bool> checkNow() async {
    checkCalls++;
    if (isReachable != checkResult) emit(checkResult);
    return checkResult;
  }

  @override
  void reportReachable() => reachableReports++;

  @override
  void reportTransportFailure() => transportFailureReports++;

  @override
  void pause() => paused = true;

  @override
  void resume() => paused = false;
}

/// Registers a [FakeNetworkInfo] in [locator] BEFORE `setupServiceLocator()`
/// (which then keeps it), so the real monitor never probes from a test.
FakeNetworkInfo registerFakeNetworkInfo([GetIt? locator]) {
  final getIt = locator ?? GetIt.instance;
  if (getIt.isRegistered<NetworkInfo>()) {
    return getIt<NetworkInfo>() as FakeNetworkInfo;
  }
  final fake = FakeNetworkInfo();
  getIt.registerSingleton<NetworkInfo>(fake);
  return fake;
}
