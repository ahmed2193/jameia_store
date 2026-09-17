# API integration — shared configuration

How every feature talks to the jm3eia backend. Backend reference:
https://docs.jm3eia.store/developers/ (Getting started, Conventions, Auth, Errors).

Everything in this document is already built into `core/`. A feature only writes a
remote datasource on `ApiConsumer` and never re-implements headers, auth, envelope
parsing or error mapping.

This file describes the shared **design**. The step-by-step **how-to** for agents lives in the
in-repo skills under `.claude/skills/`: `jameia-api-integration` (build recipe, layer
templates, patterns, backend contract + integration status, `scripts/openapi_route.js`),
`jameia-api-session`, `jameia-api-streaming`, `jameia-api-testing`, `jameia-api-verify`
(debug trace, bundled mock API `scripts/mock_api/server.js`, `scripts/vm_log_tail.dart`).

## 1. Environment

| Setting | Where | Value |
|---|---|---|
| API origin | `AppEnv.apiBaseUrl` | `--dart-define=API_BASE_URL=...`, default `https://api.jm3eia.store` |
| Version prefix | `AppEnv.apiVersion` | `/v1` (already inside every `EndPoints.*` path) |
| Timeouts | `AppConstants.connectTimeout / receiveTimeout / sendTimeout` | 20 s |
| Trace secrets | `AppEnv.apiLogSecrets` | `--dart-define=API_LOG_SECRETS=true` prints tokens in full in the debug trace (masked by default) |

Live OpenAPI spec: https://api.jm3eia.store/docs (JSON at `/docs/json`).

```sh
# Android emulator (host localhost is 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
# Physical device on the same Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
# Release
flutter build apk --dart-define=API_BASE_URL=https://api.jm3eia.com
```

The dev server is plain `http://`. That works for Dio without any native config:
Flutter's engine hard-codes a permissive network policy for `dart:io`
(`FlutterLoader.java` never sets a domain policy; `FlutterDartProject.mm` sets
`may_insecurely_connect_to_all_domains = true`), so `usesCleartextTraffic` and iOS ATS
do not apply to Dio / `http` / `cached_network_image`. Do NOT add
`NSAllowsArbitraryLoads` for the API. The debug-only `usesCleartextTraffic="true"` in
`android/app/src/debug/AndroidManifest.xml` is harmless and matters only for native
stacks (WebView, ExoPlayer, DownloadManager); if one of those ever needs `http://` in
debug, switch to a debug `network_security_config` (the manifest attribute is ignored
from targetSdk 38).

## 2. Request pipeline

```
datasource ──▶ ApiConsumer (DioConsumer)
                 │  options: buildApiBaseOptions()  (base URL, timeouts, JSON)
                 ├─ AuthInterceptor          Bearer <accessToken>; token about to expire → refresh FIRST;
                 │                           401 → refresh once → replay
                 ├─ AppHeadersInterceptor    Accept-Language; X-Cart-Token + X-Assistant-Guest while signed out
                 ├─ RateLimitRetryInterceptor 429 → wait Retry-After | 1s,2s,4s → replay (max 3)
                 └─ NetworkLogInterceptor    debug only; full request + response trace, secrets masked (§2.1)
               ◀── response.data → ApiEnvelope.tryParse → `results`  (or throw AppException)
```

Order is fixed in `config/di/service_locator.dart` (`_initNetwork`). Do not add
interceptors elsewhere.

### 2.1 Debug API trace

`NetworkLogInterceptor` prints every call through `dart:developer` `log` under the name
`api`. **Where to read it:** the IDE Debug Console (VS Code / Android Studio, launched with
the debugger) or DevTools → Logging — filter on `[api]`. `dart:developer` output does NOT
show in a plain `flutter run` terminal or in logcat; from a terminal, tail the VM Logging
stream with `dart run .claude/skills/jameia-api-verify/scripts/vm_log_tail.dart <vm-service-uri> 120 api,auth,sse`. It is installed LAST so the request block shows
the final headers, it is also attached to the bare refresh client, and it exists only in
`kDebugMode`.

```
--> #7 PATCH /v1/account/profile
    url: http://10.0.2.2:5055/v1/account/profile
    headers:
      Accept-Language: ar
      Authorization: Bearer acc_…3f9a
    body:
      { "language": "ar" }
<-- #7 200 PATCH /v1/account/profile (41ms) UPDATED
    body:
      { "success": true, "statusMessage": "UPDATED", "results": { … } }
xx  #8 401 GET /v1/account/me (12ms) TOKEN_EXPIRED
```

- Secrets are masked wherever they travel (header, query, body field, list item) when the key
  contains `authorization`, `token`, `secret`, `password`, `cookie` or `guest`: first + last 4
  characters, or `***` when shorter than 16. The `url:` line never carries the query string.
  `--dart-define=API_LOG_SECRETS=true` reveals them.
- Tracing can never break a request (formatting errors are swallowed), and a response whose
  `Content-Length` exceeds 256 KB is summarised instead of encoded.
- Bodies are pretty JSON capped at 4000 chars; streams (SSE) print `<stream>`; long lines wrap
  at 800 chars so logcat never drops a tail.
- The session story is logged under `auth` (`401 … → refreshing session`, `access token
  expiring → refreshing before …`, `refresh rejected → session expired`) and the live stream
  under `sse`.

## 3. Headers (automatic)

| Header | Source | When |
|---|---|---|
| `Content-Type: application/json`, `Accept: application/json` | `buildApiBaseOptions` | always |
| `Accept-Language: en\|ar` | `LocaleProvider` (reads `Intl.defaultLocale`, kept in sync by `LocalizationCubit`) | always |
| `Authorization: Bearer <accessToken>` | `SessionStore.readAccessToken()` | signed in |
| `X-Cart-Token` | `SessionStore.readCartToken()` | signed out and a cart token is known |
| `X-Assistant-Guest` | `SessionStore.ensureAssistantGuestKey()` (32-hex, generated once) | signed out |

A header passed explicitly to `ApiConsumer.get(..., headers: {...})` wins.

## 4. Envelope

Every non-streaming response:

```json
{ "success": true, "statusCode": 200, "statusMessage": "DATA_LOADED",
  "results": { ... }, "error": null }
```

`DioConsumer` returns **`results`** to the datasource. A 2xx body with
`success:false` throws exactly like a 4xx/5xx. Bodies that are not an envelope pass
through unchanged. The two `text/event-stream` routes (`EndPoints.streamingPaths`:
notifications SSE, assistant messages) are NOT supported by `ApiConsumer` — a datasource
opens them through `EventStreamClient.connect(path)` (`core/network/event_stream_client.dart`):
same Dio (auth, headers, trace), no receive timeout, WHATWG frame parsing into
`ServerSentEvent {event, data, id, json}`, and automatic reconnect with 1 s → 30 s backoff
(exponent clamped). It reconnects on a transport error, a mid-stream break, a 5xx, and on 90 s
of total silence (idle watchdog — heartbeat comments count as life; a half-open socket never
errors by itself). The backoff starts over only after a connection stayed up ≥ 30 s — bytes
alone do not reset it, so a proxy that accepts the stream and hangs up is never re-called
every second. Each drop is ONE `sse` log line with the connection's lifetime
(`dropped … after 60s (HttpException: Connection closed while receiving data) → reconnecting in 1s`);
a constant ~60 s lifetime means the reverse proxy cut an idle stream (`proxy_read_timeout`) —
the backend must heartbeat (`: ping` every ≤ 25 s) and disable proxy buffering on the route.
It only ends — with an error — on 401 (after the refresh), 403 or 404.
A repository exposes such a stream through `BaseRepositoryMixin.guardStream`, so listeners
receive `Failure`s, never exception types.

## 5. Errors

`ApiExceptionMapper` (transport + envelope → `AppException`) and
`BaseRepositoryMixin` (`AppException` → `Failure`) are the only two places that map.

| HTTP / Dio | Exception (data) | Failure (domain/UI) | Notes |
|---|---|---|---|
| 400 | `BadRequestException(code, details)` | `ServerFailure(statusCode: 400, code)` | `details` = `error.data` (field errors) |
| 401 | `UnauthorizedException` | `UnauthorizedFailure` | only after the automatic refresh failed / no session |
| 403 | `ForbiddenException` | `ForbiddenFailure` | |
| 404 | `NotFoundException` | `ServerFailure(statusCode: 404, code)` | |
| 409, 5xx, other | `ServerException(statusCode, code)` | `ServerFailure(statusCode, code)` | |
| 429 | `RateLimitedException(retryAfter)` | `RateLimitedFailure(retryAfter)` | after 3 backoff retries |
| timeout | `RequestTimeoutException` | `TimeoutFailure` | |
| no connection / bad cert | `NoInternetConnectionException` / `NetworkException` | `NetworkFailure` | |
| cancelled | `RequestCancelledException` | `NetworkFailure` | |
| bad JSON / shape | `ParsingException` | `ParsingFailure` | |
| keychain failure | `CacheException` | `CacheFailure` | |

Rules:

- **Branch on `code`** (`ApiStatus.outOfStock`, `ApiStatus.cartEmpty`, ...) or the
  status, never on the message text.
- **Show `failure.message`** for `ServerFailure`: it is the backend's localized
  `error.message`. Transport failures carry English fallbacks — map those to i18n keys.
- 401 on `EndPoints.authPaths` is never refreshed (login/OTP/refresh/logout).

## 6. Session and auth

`SessionStore` (`core/storage/session_store.dart`, keychain/keystore via
`flutter_secure_storage`) holds the token pair and the two guest identities. Feature
code touches it only from a datasource.

Flow the core already implements:

1. Verify-OTP datasource → `SessionStore.saveTokens(AuthTokens.fromJson(results))`,
   then `clearGuestSession()` (guest cart + assistant history merged server-side).
2. Every request → Bearer from the store (access token cached in memory). `saveTokens`
   also stores when the access token expires (`now + expiresIn`, 900 s today).
3. Token inside the last 30 s of its life → the interceptor refreshes BEFORE sending, so the
   request never pays for a 401 round trip. A refresh that cannot reach the server sends the
   current token anyway.
4. 401 → `TokenRefresher` posts `{ refreshToken }` to `/v1/auth/refresh` through a
   bare Dio (no auth interceptor) → new pair saved → original request replayed once.
   Pre-flight checks and concurrent 401s share ONE in-flight refresh (single-flight future)
   and reuse the rotated token.
5. Refresh answered 400/401/403 (`INVALID_TOKEN`) → `clearTokens()` + `SessionExpiryNotifier.notifyExpired()`.
   A network failure during refresh keeps the session and surfaces the network error.
6. Logout datasource → `POST /v1/auth/logout` then `clearTokens()`.

Feature side (done in `features/auth`): `AuthSessionCubit` is app-global
(`AppGlobalCubits.authSession()` → `restore()` validates a stored session against
`GET /v1/account/me`; offline keeps it, a rejected refresh ends it). `WatchSessionExpiryUseCase`
feeds it the notifier stream; the app root's `BlocListener` does
`appRouter.go(Routes.login, extra: true)` on expiry and the login page shows the notice.
Settings → log out calls `AuthSessionCubit.signOut()` (server revoke + local wipe, wipe even
offline). Not yet wired: clearing user-scoped state (cart, addresses) on sign-out.

### 6.1 Features already on the API

| Feature | Routes | Entry points |
|---|---|---|
| auth | `send-otp`, `verify-otp`, `refresh`, `logout`, `account/me` (restore) | `LoginCubit`, `OtpCubit`, app-global `AuthSessionCubit` |
| account / profile | `GET /v1/account/me`, `PATCH /v1/account/profile` | `ProfileCubit` + `ProfileEditPage` (`Routes.profileEdit`); only the changed fields are sent (`ProfileUpdate.diff`); the Mine header + wallet read `AuthSessionCubit.customer` |
| language | `PATCH /v1/account/profile { language }` | `LocalizationCubit.syncToServer()` — fired (not awaited) after every switch and by the app root when a sign-in finds a different language on the account; signed-out is a no-op |
| notifications | `GET /v1/notifications`, `PATCH …/:id/read`, `PATCH …/read-all`, `GET …/sse`, `POST /v1/push/register` | `NotificationsCubit` + `NotificationsPage` (`Routes.notifications`), app-global `UnreadNotificationsCubit` (bell on Home, badge on Mine). ONE shared SSE connection per device. `RegisterPushTokenUseCase` is ready but has no caller until FCM / APNs is added |

The customer DTO is shared: `core/data/models/customer_model.dart` + `customer_mapper.dart` →
`AuthCustomerEntity` (money in fils: `walletFils`, `walletKd`).

## 7. Conventions to respect in models/mappers

- Money: `int` fils. 1.250 KWD = `1250`. Convert to KD only in the entity/formatter.
- Ids: 24-hex Mongo ids. Catalog reads use slugs (`EndPoints.product(slug)`).
- Pagination: query `page` (1-based) + `limit` (≤ 100) → `results.pagination`
  `{ total, page, limit, hasMore }` next to `results.data[]`.
- Localized public fields arrive already resolved for `Accept-Language`; admin-style
  objects arrive as `{ en, ar }` — keep both raw in the DTO, pick in the entity.
- Dates: ISO-8601 strings; slot dates `YYYY-MM-DD` in Asia/Kuwait.

## 8. Adding a remote datasource (checklist)

```dart
// features/orders/data/datasources/orders_remote_data_source.dart
abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders({required int page, required int limit});
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  const OrdersRemoteDataSourceImpl(this._api);
  final ApiConsumer _api;

  @override
  Future<List<OrderModel>> getOrders({required int page, required int limit}) async {
    final results = await _api.get(
      EndPoints.orders,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = ApiPayload.asMap(results, EndPoints.orders)['data'];
    if (data is! List) throw const ParsingException('orders: data missing');
    // Non-object rows are skipped here; to also survive a row whose FIELDS are
    // malformed, parse through a try-helper like NotificationsPageModel._tryParseItem.
    return [
      for (final raw in data)
        if (raw is Map) OrderModel.fromJson(raw.cast<String, dynamic>()),
    ];
  }
}
```

1. Path → `EndPoints` (add if missing).
2. DTO `fromJson` in `data/models/`; mapper extension in `data/mappers/`.
3. Datasource returns DTOs, throws `AppException` only (no `Either`, no Dio types). Guard the
   payload shape with `ApiPayload.asMap(results, route)` (`core/network/api_payload.dart`).
4. Repository impl: `with BaseRepositoryMixin`, every method `execute(() => ...)`.
5. Use case per operation → cubit → DI (`registerLazySingleton<Interface>`).
6. Tests: datasource with `FakeHttpClientAdapter` (`test/core/network/network_test_fakes.dart`),
   repository exception → failure mapping, cubit with `bloc_test`.

## 9. Test helpers

`test/core/network/network_test_fakes.dart`: `FakeHttpClientAdapter` (scripted
transport), `envelope(...)` / `okBody(...)` builders, `InMemorySessionStore`,
`FakeTokenRefresher`, `FakeLocaleProvider`, `RecordingExpiryNotifier`. Set
`InMemorySessionStore.accessTokenExpiry` to exercise the pre-flight refresh; pass a `sink` to
`NetworkLogInterceptor` to assert on the trace; `FakeEventStreamClient`
(`test/features/notifications/notifications_test_fakes.dart`) scripts SSE frames.
`SecureSessionStore` tests use `FlutterSecureStorage.setMockInitialValues({})`.
