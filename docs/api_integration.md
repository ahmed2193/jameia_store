# API integration — shared configuration

How every feature talks to the Hero backend. Backend reference:
https://docs.jm3eia.store/developers/ (Getting started, Conventions, Auth, Errors).

Everything in this document is already built into `core/`. A feature only writes a
remote datasource on `ApiConsumer` and never re-implements headers, auth, envelope
parsing or error mapping.

This file describes the shared **design**. The step-by-step **how-to** for agents lives in the
in-repo skills under `.claude/skills/`: `hero-api-integration` (build recipe, layer
templates, patterns, backend contract + integration status, `scripts/openapi_route.js`),
`hero-api-session`, `hero-api-streaming`, `hero-api-testing`, `hero-api-verify`
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
                 ├─ ReachabilitySignalInterceptor any HTTP response → reachable; a transport failure
                 │                           → NetworkInfo re-checks at once (a 5xx is never "offline", §10.1)
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
stream with `dart run .claude/skills/hero-api-verify/scripts/vm_log_tail.dart <vm-service-uri> 120 api,auth,sse`. It is installed LAST so the request block shows
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
| account / loyalty | `GET /v1/account/loyalty?page&limit`, `GET /v1/init` → `store.loyalty` | `LedgerCubit<LoyaltyEntryEntity>` + `LoyaltyProgramCubit` + `LoyaltyPage` (`Routes.loyalty`; Mine → Loyalty points): points balance and what it is worth, the programme rules (earn rate, point value, redemption minimum, expiry) and the history (earn, redeem, expire, welcome / profile bonus, refund restore, admin adjustment; earned lines show their expiry). The programme is read once per run and shared (`LoyaltyRemoteDataSourceImpl`). `LoyaltyRewardsCubit` + `LoyaltyRewardsPage` (`Routes.loyaltyRewards`; Loyalty page, Pro paywall): the API has no rewards catalogue, so the reward tiers are an app choice (`LoyaltyRewards.from`: `minRedeemPoints` × 1 / 2 / 5 / 10, each worth `redemptionPerPoint` fils per point); a ready tier is redeemed on the current basket through the app-global `CartCubit.applyLoyalty` (`POST /v1/cart/loyalty`) |
| language | `PATCH /v1/account/profile { language }` | `LocalizationCubit.syncToServer()` — fired (not awaited) after every switch and by the app root when a sign-in finds a different language on the account; signed-out is a no-op |
| notifications | `GET /v1/notifications`, `PATCH …/:id/read`, `PATCH …/read-all`, `GET …/sse`, `POST /v1/push/register` | `NotificationsCubit` + `NotificationsPage` (`Routes.notifications`), app-global `UnreadNotificationsCubit` (bell on Home, badge on Mine). ONE shared SSE connection per device — only when built with `--dart-define=LIVE_NOTIFICATIONS=true` (default off, see §4). `RegisterPushTokenUseCase` is ready but has no caller until FCM / APNs is added |
| addresses | `GET /v1/account/addresses`, `POST /v1/account/addresses`, `PATCH /v1/account/addresses/:addressId`, `DELETE /v1/account/addresses/:addressId` | app-global `AddressBookCubit`: the app root calls `start(customerId:)` on sign-in / launch restore and whenever the customer id changes (device copy shown at once, then `GET` → saved back to `LocalStorage` key `account.addresses.v2` as `{ownerId, addresses: [API rows]}`; a copy saved for another customer is never shown, and a different customer starts the book over) and `stop()` on sign-out / expiry (memory + device copy wiped, plus the retired `account.addresses.v1` / offline `jameia.addressbook.v1` books). Address ids must be ObjectIds before they go into a path. `AddressListPage` (`Routes.addressList`) reads it; `AddressEditCubit` + `AddressEditPage` (`Routes.addressEdit`, extra = `HeroAddressEntity`) POST a new address or PATCH only the changed fields (`AddressUpdate.diff`), and the page hands the reply to `AddressBookCubit.applySaved`. Delete waits for the server (404 = already gone). Checkout reads the book for the delivery address (`POST /v1/delivery/select-address`); Home still reads the offline `HeroRepository.defaultAddress` |
| catalogue (shared reads) | `GET /v1/products`, `GET /v1/categories`, `GET /v1/brands` | `core/data/datasources/catalog_remote_data_source.dart` — one datasource for shop, search, the home rails and the PDP rails. The category tree is one small page every catalogue screen reads, so it is kept per request language for `CatalogRemoteDataSourceImpl.categoryTreeTtl` (5 min); a pull-to-refresh passes `refresh: true`. Entities: `CatalogProductEntity` / `CatalogCategoryEntity` + `CatalogCategoryTree` / `BrandEntity`, query object `CatalogProductQuery` |
| home | `GET /v1/home`, `GET /v1/init` | `HomeCubit` loads both in one emit; sealed `HomeSectionEntity` subtypes render the rails, promo cards, strips and banners in the order the backend sends them; `HomeBootstrap` carries the store settings + popups |
| shop — catalogue browse | `GET /v1/categories`, `GET /v1/products` | `CategoryBrowseCubit` (rows) + `ProductListingCubit` (grid). `CategoriesPage` (`Routes.shop` / `Routes.categories`): top-level categories as the app bar tab row, the open tab’s children as a circle rail, their children as chips; the deepest pick scopes `categorySlug` (a parent includes its descendants) and the first tab is picked on open, so the first product page is fetched once for the right category. `CategoryPage` (`Routes.category`) is the same rows under one category, its own products loaded in parallel with the tree. `ProductListingPage` (brand / collection / offers / search results) and `BrandsPage` share the grid, sort and server-side filters |
| product_details | `GET /v1/products/:slug`, `GET /v1/products/:slug/reviews`, `GET /v1/offers` | `ProductDetailCubit` + `ProductReviewsCubit`; the `ProductDetail` entity owns the buying rules (variant needed, unit price, compare-at, line total, Pro hint). The buy bar's deal tag is the first live offer whose trigger counts this product (`item_quantity` on its id, `category_quantity` on its category or parent — `GetProductOfferUseCase`); the offers come from the shared `CatalogRemoteDataSource.getOffers()`, cached per language like the category tree. A failed offers read just shows no tag |
| search | `GET /v1/products?search=`, `GET /v1/categories`, `GET /v1/brands` | `SearchCubit` (debounced suggestions, min 2 characters, stale replies dropped); recents live in `LocalStorage`; committing a search opens `ProductListingPage` with `CatalogProductQuery(search:)` |
| marketing | `GET /v1/offers`, `GET /v1/pages/:slug` | `OffersPage`; `ContentPage` renders a backend content page (an unknown slug answers `400`, not `404`) |
| recipes | `GET /v1/recipes`, `GET /v1/recipes/:slug` | `RecipesCubit` + `RecipeDetailPage`; the ingredients are real products, so the page can add them all to the cart |
| store_mode — Hero Pro | `GET /v1/subscription-plans`, `GET /v1/account/subscription`, `POST /v1/account/subscription`, `POST /v1/account/subscription/cancel`, `GET /v1/brands` (paywall logo rows) | `ProMembershipCubit` (programme + subscription + the plan picked in the tabs; opens on the current plan, else the best value per month = the web "Save N%" rule in `ProProgram`) + `ProBrandsCubit` (secondary, silent on failure). A subscription is a member while it has benefits: `active`, or `cancelAtPeriodEnd` while the period runs (the docs send that as `cancelled`), never `expired` (`ProSubscription.hasBenefits`). Subscribing waits for the server and then refreshes the customer snapshot (`AuthSessionCubit.restore()`), because `isPro` drives every Pro price in the app. The API has no free trial, promo code or family plan |
| cart | `GET /v1/cart`, `POST /v1/cart/items`, `PATCH /v1/cart/items/:key`, `DELETE /v1/cart/items/:key`, `DELETE /v1/cart`, `POST` / `DELETE /v1/cart/coupon`, `POST` / `DELETE /v1/cart/loyalty`, `POST /v1/cart/express` | app-global `CartCubit` over an **offline-first mirror**: every tap edits the local projection and emits at once, then the repository coalesces the pending deltas per line (debounce `CartRepositoryImpl.defaultFlushDelay` = 400 ms), sends **one** request at a time (new lines batched into `POST /v1/cart/items`, existing lines as absolute `PATCH` / `DELETE`), rebases whatever was tapped while the request was in flight, drops stale replies by generation, retries transport failures after `defaultRetryDelay` = 5 s and persists the mirror + queue to `LocalStorage` (`cart.mirror.v1`) so a cold start renders instantly and replays when online. The guest cart lives on the `X-Cart-Token` the server issues; the app root re-owns the mirror on sign-in / sign-out and refetches on a locale change. The deals strip and the "Buy more, save more" sheet read the cart's own `appliedOffers` / `offerProgress` (`CartOffersView`); the sheet's products come from `GET /v1/categories` + `GET /v1/products` (the offer's category resolved to a slug, else on-sale items; in stock, sorted by discount — `GetDealProductsUseCase`). Verified live: a reached offer moves from `offerProgress` to `appliedOffers`, an applied free delivery reports `discount: 0`, an empty cart reports `freeDelivery: true`, and every body-less `DELETE` (`cart`, `cart/items/:key`, `cart/coupon`, `cart/loyalty`) answers `500` when it carries `Content-Type: application/json` with no body — `DioConsumer` sends `ApiPayload.emptyBody` (`{}`), which the server accepts (`200`) |
| checkout | `GET /v1/delivery/branches`, `GET /v1/delivery/slots`, `POST /v1/delivery/select-branch`, `POST /v1/delivery/select-address`, `POST /v1/orders` | `CheckoutCubit` + `CheckoutPage` (`Routes.checkout`, no extra). The branch list is read once per language (`DeliveryRemoteDataSourceImpl.branchesTtl` = 5 min), so a language switch shows the names in the new language. Mode = delivery to a saved address or pickup from a branch; timing = ASAP / express (surcharge from the cart) / a scheduled slot from `GET /v1/delivery/slots`; payment `cod` or `wallet` only; notes ≤ `CheckoutDraft.maxNotesLength` (256). Each selection is a server call that returns the re-priced cart, so fees stay the server’s; a stale selection reply is dropped by generation. `POST /v1/orders` sends only `paymentMethod`, `notes` and the chosen `deliverySlot` — everything else is the server cart. One in-flight placement (`isPlacing`); on success the cart mirror is cleared, a wallet order refreshes the customer snapshot and the page does `pushReplacement(Routes.orderTracking, extra: order.id)` |
| checkout — Hero-style page + vouchers (2026-09-26) | `GET /v1/init` → `store.*`, `GET /v1/offers`, `GET /v1/products?inStock&onSale&sort` (rail), `GET /v1/delivery/slots` (after a delivery selection), `POST` / `DELETE /v1/cart/coupon`, `POST` / `DELETE /v1/cart/loyalty`, `POST /v1/cart/express` | Same `CheckoutCubit`, plus `CheckoutRailCubit` and `CheckoutOffersCubit` (page-scoped; `CheckoutPage` and the new `CheckoutVouchersPage`, `Routes.checkoutVouchers`, extra = the serving `branchId`). **Store rules:** `GetStoreRulesUseCase` reads `GET /v1/init` into `CheckoutStoreRules` (store name, `codEnabled`, `defaultMethod`, the loyalty programme through the core `LoyaltyProgramModel`, the Pro free-delivery perk, maintenance) — store fields only, never `user.*`; cached per language for 5 min; a failure falls back to the defaults (COD on). **Offers:** `GET /v1/offers` (the shared catalogue datasource’s per-language cache) enriches the cart’s `appliedOffers` / `offerProgress` with minimum, cap, `stackable`, `endsAt` and the new `branchIds`; the unlock tag, the free-delivery gap and the vouchers page’s locked list keep only stackable, branch-eligible offers. **Rail** ("Deals you might have missed"): `GET /v1/products` with `inStock`, `onSale`, `sort=discount_desc`, `limit=20` through the core `CatalogRemoteDataSource`; in-cart ids (taken at open), zero-price variant rows, out-of-stock rows and duplicates dropped, capped at 10; settled before the content shows (≤ `CheckoutRailCubit.settleLimit` = 1.2 s, a later reply is dropped). **Slots:** `GET /v1/delivery/slots` answers 400 `VALIDATION_ERROR` until the cart has a delivery selection (live), so they load after each `select-address` (never on start, never for pickup), non-fatal; a booked window the new address lost resets to ASAP with a notice. **Coupon, points, express** go through the cart routes (`CartCubit.applyCoupon` / `applyLoyalty(points)` with `LoyaltyProgram.pointsToRedeem` / `setExpress`); a refused express restores the previous timing and slot. The vouchers page: code entry (`POST /v1/cart/coupon`, inline error), the applied coupon (remove), applied offers and "add more to unlock" progress — no Apply on offers, no coupon list. A 401 on select / place shows the signed-out state (its button does `go(Routes.login)`). After every order `AuthSessionCubit.restore()` re-reads wallet and points |
| orders | `GET /v1/orders`, `GET /v1/orders/:id`, `POST /v1/orders/:id/cancel`, `POST /v1/reviews` | `OrdersCubit` + `OrdersPage` (`Routes.orders`, tabs are status groups computed in `OrdersFeed`; the next page follows the scroll — never a build pass — and a tab still showing nothing pulls up to `OrdersList._autoFillPages` pages before it waits for a tap, because the API pages one flat list and cannot filter by status), `OrderTrackingCubit` + `OrderTrackingPage` (`Routes.orderTracking`, extra = order id; polls `GET /v1/orders/:id` every `OrderTrackingCubit.pollInterval` = 30 s only while the route is on top (`routeObserver`), the app is resumed and the status is not terminal), cancel with one of the five API reasons + an optional note (`CancelOrderRequest`), reorder through the cart’s batched `POST /v1/cart/items`, and `OrderReviewCubit` → `POST /v1/reviews` per product (1–5 stars, title ≤ 120, body ≤ 2000, delivered orders only). The invoice page renders the order’s own totals |
| assistant | `GET /v1/assistant/conversations`, `GET /v1/assistant/conversations/:id`, `POST /v1/assistant/messages` (`text/event-stream`), `POST /v1/assistant/actions/:actionId/confirm`, `POST /v1/assistant/conversations/:id/handoff`, `POST /v1/assistant/messages/:id/feedback`, `GET /v1/init` → `store.assistant` + `featureFlags.assistant` | `AssistantChatCubit` + `AssistantChatPage` (`Routes.assistant`, extra = optional `AssistantChatArgs`; home header disc, Mine row), `AssistantHistoryCubit` + `AssistantHistoryPage` (`Routes.assistantHistory`, pops the picked id), app-global `AssistantAvailabilityCubit`. The reply streams through `EventStreamClient.send` (one-shot `POST`, never replayed): frames `message_start` → `user_message` → tool / block / text deltas → `message_end` | `error`; text deltas are coalesced every 50 ms, only whole words are drawn, adjacent product rails merge. A `cart_action` is a PROPOSAL: nothing changes until the customer confirms it (one request per id, 404 → expired; success refetches the cart mirror). Guests chat with `X-Assistant-Guest` (merged into the customer on sign-in); a 401 shows the sign-in prompt, never a pre-check. Never call `handoff` on the live host (it opens a real ticket) — use the mock. Voice messages never reach the API as audio (there is no audio route): `AssistantVoiceCubit` turns speech into text on the device (`speech_to_text`) and the words go out as a normal `POST /v1/assistant/messages` |

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
`.claude/skills/hero-api-integration/references/layer-templates.md`. The shipped model to
read next to it is `features/notifications/` (`notifications_remote_data_source.dart`,
`notifications_page_model.dart`). Moving a legacy offline feature:
`references/migrating-offline-feature.md`.

1. Path → `EndPoints` (add if missing).
2. DTO `fromJson` in `data/models/`; mapper extension in `data/mappers/`.
3. Datasource returns DTOs, throws `AppException` only (no `Either`, no Dio types). Guard the
   payload shape with `ApiPayload.asMap(results, route)` (`core/network/api_payload.dart`).
4. Repository impl: `with BaseRepositoryMixin`, every method `execute(() => ...)`. A read the
   screen should paint offline adds a namespace in a `*_cache_data_source.dart` (§10.2), returns
   `RemotePayload(model, raw)` from the remote datasource, mixes in `CachedRepositoryMixin` and
   returns `cachedRead(...)`; a watch use case feeds a cubit `with SnapshotLoaderMixin` (§10.4).
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

Offline & cache: `FakeNetworkInfo` + `registerFakeNetworkInfo()` (same file; register it BEFORE
`setupServiceLocator()` so the real monitor never probes from a test), `InMemoryJsonCacheStore` +
`testNamespace` (`test/core/storage/cache_test_fakes.dart`; `FileJsonCacheStore` is tested on a temp
dir only), `networkRead(future, saved:)` + `savedSnapshotAt` / `networkSnapshotAt`
(`test/core/data/snapshot_test_fakes.dart`: a fake watch use case in one line — an `async*` body,
because `asyncExpand` never completes under a widget test's fake clock),
`FakeCatalogRemoteDataSource` (`test/core/data/catalog_test_fakes.dart`),
`FakeConnectivityRepository` + `buildConnectivityCubit`
(`test/features/connectivity/connectivity_test_fakes.dart`). An offline widget test wraps the page
in `ConnectivityScope(isOffline: true, reconnectEpoch: 0, onNudge: …, onCheckNow: …)`.

## 10. Offline & caching

The app keeps what each screen last showed and paints it at once — at the next launch and while
offline — then revalidates. Contract: CLAUDE.md §3 ("Connectivity", "Offline cache") and §3.2
item 4. Design and acceptance criteria: `docs/prompts/offline_connectivity_prompt.md`.

### 10.1 Connection state

- **One monitor:** `NetworkInfoImpl` (`core/network/network_info.dart`). Probe = `HEAD <API base>/`
  (any HTTP status proves the backend is reachable; it answers `404`, 0 bytes, ~0.3 s) plus one
  neutral fallback, `https://one.one.one.one` (HTTPS: a captive portal cannot answer for it; a
  backend outage never reads as "offline"), `AppConstants.connectivityProbeTimeout` (5 s) each.
- **Schedule:** every `connectivityPoll` (3 s) while unreachable, every `connectivityPollOnline`
  (30 s) while reachable; nothing in the background (paused when the app is hidden / paused, one
  probe on resume) or while nobody listens. Far under the 300 / 60 s rate limit.
- **Signals from real traffic:** `ReachabilitySignalInterceptor` — any HTTP response marks the
  backend reachable at once; a transport failure (no route, timeout) asks for a probe now. It never
  flips the state by itself. A 4xx / 5xx is a server answer: the screen shows its error, never the
  offline UI.
- **State:** `ConnectivityCubit` (`features/connectivity`, app-global): status `unknown` / `online` /
  `offline` (offline only after `offlineDebounce`, 1.5 s, of unreachability AND a confirming live
  check at its end — one slow probe, like the first one while the app starts, never shows the
  banner); banner mode
  `hidden` / `offline` / `reconnecting` (a tap asked for a check) / `backOnline` (held
  `backOnlineHold`, 2 s). Each return bumps `reconnectEpoch`. The banner
  (`ConnectivityBannerHost`, over the navigator) never shows for `unknown` or on the splash.
  Screens and core widgets read `ConnectivityScope`, never the cubit.

### 10.2 What is cached

Only read routes; only page 1 of a paginated list; the envelope's `results` exactly as sent.
Every key carries the language (names arrive resolved by `Accept-Language`, which the server does
not list in `Vary`) and the owner.

| Namespace | Route | Scope | Key id | Fresh (no request on open) | Max age (never shown after) | Max entries |
|---|---|---|---|---|---|---|
| `home.feed` | `GET /v1/home` | owner | — | 60 s | 7 d | 4 |
| `home.init` | `GET /v1/init` (home bootstrap) | owner | — | 60 s | 7 d | 4 |
| `catalog.categories` | `GET /v1/categories` | public | — | 5 min | 7 d | 4 |
| `catalog.brands` | `GET /v1/brands` page 1 | public | limit | 60 s | 7 d | 4 |
| `catalog.products` | `GET /v1/products` page 1 | public | normalised query + limit | 60 s | 3 d | 40 |
| `catalog.offers` | `GET /v1/offers` (catalogue + marketing share it) | public | — | 60 s | 1 d | 4 |
| `product.detail` | `GET /v1/products/:slug` | public | slug | 60 s | 3 d | 60 |
| `product.reviews` | `GET /v1/products/:slug/reviews` page 1 | public | slug + limit | 5 min | 7 d | 60 |
| `recipes.list` | `GET /v1/recipes` page 1 | public | limit | 60 s | 7 d | 4 |
| `recipes.detail` | `GET /v1/recipes/:slug` | public | slug | 60 s | 7 d | 40 |
| `marketing.page` | `GET /v1/pages/:slug` | public | slug | 1 h | 30 d | 10 |
| `pro.program` | `GET /v1/subscription-plans` | public | — | 5 min | 7 d | 4 |
| `pro.subscription` | `GET /v1/account/subscription` (+ the subscribe / cancel replies) | customer | — | 60 s | 7 d | 4 |
| `orders.list` | `GET /v1/orders` page 1 | customer | limit | 30 s | 30 d | 4 |
| `orders.detail` | `GET /v1/orders/:id` (+ the cancel reply) | customer | order id | 0 (always revalidates) | 30 d | 30 |
| `notifications.page` | `GET /v1/notifications` page 1 | customer | all / unread + limit | 30 s | 14 d | 4 |
| `account.wallet` / `account.loyalty` | `GET /v1/account/wallet` / `loyalty` page 1 | customer | limit | 60 s | 14 d | 4 |
| `assistant.history` | `GET /v1/assistant/conversations` page 1 | customer (guest chats move to the customer at sign-in) | limit | 60 s | 14 d | 4 |

**Never cached:** the cart (its own `cart.mirror.v1` mirror; the server sends `no-store`), profile
and addresses (their own device copies), checkout slots / branches / store rules, any `POST`,
search suggestions, auth / OTP, SSE frames and the assistant chat stream / transcripts.

**Observed cache headers** (live, 2026-09-27): the public catalogue routes (`/v1/home`, `/v1/init`,
`/v1/categories`, `/v1/products`, `/v1/brands`, `/v1/offers`, `/v1/recipes`) answer
`cache-control: public, max-age=60, stale-while-revalidate=300`; `/v1/cart` answers `no-store`;
no route sends `ETag` / `Last-Modified`, so revalidation is a full re-fetch; only `vary: Origin`
is sent. Dio keeps no HTTP cache — the policy above is the app's own.

### 10.3 Store, keys, wipe rules

- **Files:** `FileJsonCacheStore` (`core/storage/json_cache_store.dart`) under the app cache folder:
  `api_cache/<bucket>/<namespace>/<fnv64>.json`, one record `{ v, ns, nsv, key, savedAt, lang,
  owner, data }`. Bucket = `public`, `guest` or `customer`. The file name is a 64-bit FNV-1a
  hash of `namespace|version|language|owner|id` (`CacheKey.full`), which the record repeats and
  the read checks, so a collision or a version bump reads as a miss. Owner = `public`, `guest` or
  `c:<customerId>` — never a token, an OTP or a header.
- **Writes** are atomic (temp file + rename), serialized, fire-and-forget. An entry over 1 MB is
  not saved; past 12 MB in total, or past a namespace's `maxEntries`, the oldest go first. Files
  over 64 KB are decoded off the UI isolate. Logs (name `cache`) carry the namespace, the key
  hash and the byte size — never a payload.
- **Owner:** `CacheOwner`, kept in step by the auth local datasource (the one writer of the
  customer's device copy): `signedIn(id)` when it saves / reads the customer, `signedOut()` when
  it clears it. Until then (launch, before the session restore resolves) owner / customer slots
  are disabled — nothing personal is read or written. A reply that lands after the owner changed
  is not saved.
- **Wipe:** sign-out and session expiry clear the customer copy → `CacheOwner.signedOut()` +
  `JsonCacheStore.removeOwnedEntries()` (the whole `customer/` bucket). Public and guest
  entries stay. A copy past `maxAge` is never shown; a copy that no longer parses is deleted
  and treated as a miss; bumping a namespace `version` (DTO shape change) or
  `FileJsonCacheStore.formatVersion` turns every older entry into a miss. The Settings
  "clear cache" tile is not wired yet (follow-up: `JsonCacheStore.clear()` + the image cache).
- **Check on a device:** `adb shell run-as <applicationId> ls -R cache/api_cache` (application id
  in `android/app/build.gradle.kts`).

### 10.4 Read path and screen contract

`cachedRead(cache:, fetch:, toEntity:, forceRefresh:)` (`CachedRepositoryMixin`) streams
`DataSnapshot<T>`s (a `Failure` on the error channel): the device copy first (unless past `maxAge`) — a copy younger
than `freshFor` ends the read there; then the network snapshot (saved); a failure arrives after any
copy, so the screen keeps the copy and marks it stale. `forceRefresh` (pull to refresh, retry,
reconnect) skips the copy. A mutation reply that answers a cached read is kept with
`keepReply(slot, raw)` (a cancelled order, a Pro subscribe / cancel).

The cubit (`SnapshotLoaderMixin`) follows the watch use case with `followSnapshots` — a newer
load of the same channel cancels the older one — and keeps `DataFreshness freshness` (fetched at,
from cache, refresh failed) plus a transient `Failure? failure` in its state. The page:
- data + offline or a failed refresh → the data with the stale note (`StaleDataNotice` /
  `CubitStaleNotice`, "Updated 12 min ago"); never a full-screen error over data;
- nothing saved + `NetworkFailure` → `FailureView`: known offline → `HeroStateView.offline`;
  otherwise "Checking your connection…" (`HeroStateView.checking`) and a live check
  (`ConnectivityScope.recheckerOf`, held ≥ 1.5 s so the verdict lands with the banner) → reachable:
  the screen loads again by itself (at most one such retry per `AppConstants.readRetryGap`, 15 s,
  app-wide) / not: `HeroStateView.offline`; other failures → `ErrorView`;
- "load more" failing offline → `LoadMoreOfflineNote` (the list asks again on reconnect);
- a background failure → `showFailureSnackBar`: a transport failure (no connection, timeout)
  shows no snack of its own — the connection check and the banner speak (offline: a nudge);
- `ReconnectRefresh` → cubit `onReconnected()` → `refreshOnReconnect(needed: stale || error)`:
  single-flight, after a 0–600 ms jitter, at most one request per stale screen.

### 10.5 Recovery and mutations

- **Reconnect** (`app.dart`, `ConnectivityCubit.reconnectEpoch`): `CartCubit` flushes pending deltas
  (or refetches), `AuthSessionCubit` re-verifies an unverified session, `AddressBookCubit` syncs,
  `UnreadNotificationsCubit` re-probes the badge, `AssistantAvailabilityCubit` retries a failed
  read, `ProStatusCubit` refreshes an unconfirmed standing, `LocalizationCubit` re-sends an owed
  language sync, and `HeroImage.retryAllPendingImages()` retries images that failed.
- **Mutations:** nothing is queued or replayed except the cart's coalesced quantity deltas. A
  failed submit keeps its draft and says `connectivity.action_needs_internet` once (and nudges the
  banner). Place order and cancel order run `ConnectivityScope.confirmOnline` first — a live
  check while offline — and send nothing while the connection is still gone.
