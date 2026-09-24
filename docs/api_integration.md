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
The notifications stream is **off by default** (`AppEnv.liveNotifications`,
`--dart-define=LIVE_NOTIFICATIONS=true` turns it on): the production proxy closes the idle
stream after ~60 s and sends no heartbeat, so it only ever reconnected. Without it the unread
badge loads on sign-in / launch restore and the inbox on open and pull-to-refresh.
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
  status, never on the message text. Open gap: `ApiStatus` lives in `core/network`, which
  domain and presentation may not import, so a cubit / use case cannot reference it yet
  (planned: move under `core/error/`, re-export from `failures.dart`); branch on the failure
  type / `statusCode` until then.
- **Show `failure.localizedMessage`** (`core/utils/failure_message.dart`): a backend failure
  keeps the server's localized `error.message`; transport failures carry English fallbacks,
  so the extension maps them to `core.*` i18n keys. API-backed states hold the `Failure`.
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
offline). The customer record itself has a device copy (`LocalStorage` key
`account.profile.v1`, the same JSON the backend sends): `AuthSessionCubit` is its only writer —
`restore()` shows it at once (only while tokens exist), then confirms it with `GET
/v1/account/me` (`AuthSessionState.isVerified`); every confirmed snapshot (sign-in, restore,
`updateCustomer`) is saved back and every sign-out / expiry wipes it. The account-language sync
and the profile page wait for a confirmed snapshot, so a stale copy never PATCHes anything and
the profile page skips `GET /v1/account/me` when the session already confirmed it this run.
The saved-address book is wiped (memory + device copy) by the app root on every
sign-out / expiry (`AddressBookCubit.stop()`), and the cart mirror is re-owned on every session change
(`CartCubit.onSignedIn(customerId)` / `onSignedOut()` from the app root: the local mirror is
dropped and the new owner’s server cart is pulled).

### 6.1 Features already on the API

| Feature | Routes | Entry points |
|---|---|---|
| auth | `send-otp`, `verify-otp`, `refresh`, `logout`, `account/me` (restore) | `LoginCubit`, `OtpCubit`, app-global `AuthSessionCubit` |
| account / profile | `GET /v1/account/me`, `PATCH /v1/account/profile` | `ProfileCubit` + `ProfileEditPage` (`Routes.profileEdit`): name, email, and the optional "About you" details — date of birth (calendar sheet, 1900…today, clearable), gender (male / female / prefer not to say) and household size (1–20 stepper). Only the changed fields are sent (`ProfileUpdate.diff`; a removed value goes out as `null`). The sign-up placeholder name (= the phone) is never offered as the name: the page and the Mine header ask to "Complete your profile" instead. The profile-bonus hint comes from `store.loyalty.profileBonusPoints` (`GET /v1/init`), and a save that completes the details and credits points toasts the points earned. The Mine header (name, PRO pill) + wallet read `AuthSessionCubit.customer` |
| account / wallet | `GET /v1/account/wallet?page&limit` | `LedgerCubit<WalletEntryEntity>` + `WalletPage` (`Routes.wallet`; Mine → wallet stat or the Wallet cell): balance (fils) + signed transactions (refund, checkout, cashback, admin adjustment, promo; unknown kinds → "other"), paginated, stale page dropped after a refresh |
| account / loyalty | `GET /v1/account/loyalty?page&limit`, `GET /v1/init` → `store.loyalty` | `LedgerCubit<LoyaltyEntryEntity>` + `LoyaltyProgramCubit` + `LoyaltyPage` (`Routes.loyalty`; Mine → Loyalty points): points balance and what it is worth, the programme rules (earn rate, point value, redemption minimum, expiry) and the history (earn, redeem, expire, welcome / profile bonus, refund restore, admin adjustment; earned lines show their expiry). The programme is read once per run and shared (`LoyaltyRemoteDataSourceImpl`) |
| language | `PATCH /v1/account/profile { language }` | `LocalizationCubit.syncToServer()` — fired (not awaited) after every switch and by the app root when a sign-in finds a different language on the account; signed-out is a no-op |
| notifications | `GET /v1/notifications`, `PATCH …/:id/read`, `PATCH …/read-all`, `GET …/sse`, `POST /v1/push/register` | `NotificationsCubit` + `NotificationsPage` (`Routes.notifications`), app-global `UnreadNotificationsCubit` (bell on Home, badge on Mine). ONE shared SSE connection per device — only when built with `--dart-define=LIVE_NOTIFICATIONS=true` (default off, see §4). `RegisterPushTokenUseCase` is ready but has no caller until FCM / APNs is added |
| addresses | `GET /v1/account/addresses`, `POST /v1/account/addresses`, `PATCH /v1/account/addresses/:addressId`, `DELETE /v1/account/addresses/:addressId` | app-global `AddressBookCubit`: the app root calls `start(customerId:)` on sign-in / launch restore and whenever the customer id changes (device copy shown at once, then `GET` → saved back to `LocalStorage` key `account.addresses.v2` as `{ownerId, addresses: [API rows]}`; a copy saved for another customer is never shown, and a different customer starts the book over) and `stop()` on sign-out / expiry (memory + device copy wiped, plus the retired `account.addresses.v1` / offline `jameia.addressbook.v1` books). Address ids must be ObjectIds before they go into a path. `AddressListPage` (`Routes.addressList`) reads it; `AddressEditCubit` + `AddressEditPage` (`Routes.addressEdit`, extra = `JameiaAddressEntity`) POST a new address or PATCH only the changed fields (`AddressUpdate.diff`), and the page hands the reply to `AddressBookCubit.applySaved`. Delete waits for the server (404 = already gone). Checkout reads the book for the delivery address (`POST /v1/delivery/select-address`); Home still reads the offline `JameiaRepository.defaultAddress` |
| catalogue (shared reads) | `GET /v1/products`, `GET /v1/categories`, `GET /v1/brands` | `core/data/datasources/catalog_remote_data_source.dart` — one datasource for shop, search, the home rails and the PDP rails. The category tree is one small page every catalogue screen reads, so it is kept per request language for `CatalogRemoteDataSourceImpl.categoryTreeTtl` (5 min); a pull-to-refresh passes `refresh: true`. Entities: `CatalogProductEntity` / `CatalogCategoryEntity` + `CatalogCategoryTree` / `BrandEntity`, query object `CatalogProductQuery` |
| home | `GET /v1/home`, `GET /v1/init` | `HomeCubit` loads both in one emit; sealed `HomeSectionEntity` subtypes render the rails, promo cards, strips and banners in the order the backend sends them; `HomeBootstrap` carries the store settings + popups |
| shop — catalogue browse | `GET /v1/categories`, `GET /v1/products` | `CategoryBrowseCubit` (rows) + `ProductListingCubit` (grid). `CategoriesPage` (`Routes.shop` / `Routes.categories`): top-level categories as the app bar tab row, the open tab’s children as a circle rail, their children as chips; the deepest pick scopes `categorySlug` (a parent includes its descendants) and the first tab is picked on open, so the first product page is fetched once for the right category. `CategoryPage` (`Routes.category`) is the same rows under one category, its own products loaded in parallel with the tree. `ProductListingPage` (brand / collection / offers / search results) and `BrandsPage` share the grid, sort and server-side filters |
| product_details | `GET /v1/products/:slug`, `GET /v1/products/:slug/reviews` | `ProductDetailCubit` + `ProductReviewsCubit`; the `ProductDetail` entity owns the buying rules (variant needed, unit price, compare-at, line total, Pro hint) |
| search | `GET /v1/products?search=`, `GET /v1/categories`, `GET /v1/brands` | `SearchCubit` (debounced suggestions, min 2 characters, stale replies dropped); recents live in `LocalStorage`; committing a search opens `ProductListingPage` with `CatalogProductQuery(search:)` |
| marketing | `GET /v1/offers`, `GET /v1/pages/:slug` | `OffersPage`; `ContentPage` renders a backend content page (an unknown slug answers `400`, not `404`) |
| recipes | `GET /v1/recipes`, `GET /v1/recipes/:slug` | `RecipesCubit` + `RecipeDetailPage`; the ingredients are real products, so the page can add them all to the cart |
| store_mode — Jm3eia Pro | `GET /v1/subscription-plans`, `GET /v1/account/subscription`, `POST /v1/account/subscription`, `POST /v1/account/subscription/cancel` | `ProMembershipCubit`; subscribing waits for the server and then refreshes the customer snapshot (`AuthSessionCubit.restore()`), because `isPro` drives every Pro price in the app |
| cart | `GET /v1/cart`, `POST /v1/cart/items`, `PATCH /v1/cart/items/:key`, `DELETE /v1/cart/items/:key`, `DELETE /v1/cart`, `POST` / `DELETE /v1/cart/coupon`, `POST` / `DELETE /v1/cart/loyalty`, `POST /v1/cart/express` | app-global `CartCubit` over an **offline-first mirror**: every tap edits the local projection and emits at once, then the repository coalesces the pending deltas per line (debounce `CartRepositoryImpl.defaultFlushDelay` = 400 ms), sends **one** request at a time (new lines batched into `POST /v1/cart/items`, existing lines as absolute `PATCH` / `DELETE`), rebases whatever was tapped while the request was in flight, drops stale replies by generation, retries transport failures after `defaultRetryDelay` = 5 s and persists the mirror + queue to `LocalStorage` (`cart.mirror.v1`) so a cold start renders instantly and replays when online. The guest cart lives on the `X-Cart-Token` the server issues; the app root re-owns the mirror on sign-in / sign-out and refetches on a locale change |
| checkout | `GET /v1/delivery/branches`, `GET /v1/delivery/slots`, `POST /v1/delivery/select-branch`, `POST /v1/delivery/select-address`, `POST /v1/orders` | `CheckoutCubit` + `CheckoutPage` (`Routes.checkout`, no extra). The branch list is read once per language (`DeliveryRemoteDataSourceImpl.branchesTtl` = 5 min), so a language switch shows the names in the new language. Mode = delivery to a saved address or pickup from a branch; timing = ASAP / express (surcharge from the cart) / a scheduled slot from `GET /v1/delivery/slots`; payment `cod` or `wallet` only; notes ≤ `CheckoutDraft.maxNotesLength` (256). Each selection is a server call that returns the re-priced cart, so fees stay the server’s; a stale selection reply is dropped by generation. `POST /v1/orders` sends only `paymentMethod`, `notes` and the chosen `deliverySlot` — everything else is the server cart. One in-flight placement (`isPlacing`); on success the cart mirror is cleared, a wallet order refreshes the customer snapshot and the page does `pushReplacement(Routes.orderTracking, extra: order.id)` |
| orders | `GET /v1/orders`, `GET /v1/orders/:id`, `POST /v1/orders/:id/cancel`, `POST /v1/reviews` | `OrdersCubit` + `OrdersPage` (`Routes.orders`, tabs are status groups computed in `OrdersFeed`; the next page follows the scroll — never a build pass — and a tab still showing nothing pulls up to `OrdersList._autoFillPages` pages before it waits for a tap, because the API pages one flat list and cannot filter by status), `OrderTrackingCubit` + `OrderTrackingPage` (`Routes.orderTracking`, extra = order id; polls `GET /v1/orders/:id` every `OrderTrackingCubit.pollInterval` = 30 s only while the route is on top (`routeObserver`), the app is resumed and the status is not terminal), cancel with one of the five API reasons + an optional note (`CancelOrderRequest`), reorder through the cart’s batched `POST /v1/cart/items`, and `OrderReviewCubit` → `POST /v1/reviews` per product (1–5 stars, title ≤ 120, body ≤ 2000, delivered orders only). The invoice page renders the order’s own totals |

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

Code for every layer (page DTO that keeps `pagination`, key constants, a malformed row
skipped, mapper, datasource, repository, use case, state, cubit, DI, page):
`.claude/skills/jameia-api-integration/references/layer-templates.md`. The shipped model to
read next to it is `features/notifications/` (`notifications_remote_data_source.dart`,
`notifications_page_model.dart`). Moving a legacy offline feature:
`references/migrating-offline-feature.md`.

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
