# Hero backend contract (what the app relies on)

Sources of truth, in order: the live OpenAPI spec (`https://api.jm3eia.store/docs`, JSON at
`/docs/json` — use `scripts/openapi_route.js`), the developer docs
(https://docs.jm3eia.store/developers/), then `docs/api_integration.md` in this repo.
When this file disagrees with the live spec, the spec wins — fix this file.

## Hosts

| Environment | Value |
|---|---|
| Default (`AppEnv.apiBaseUrl`) | `https://api.jm3eia.store` |
| Override | `--dart-define=API_BASE_URL=http://10.0.2.2:5055` (Android emulator → host machine) |
| Version prefix | `/v1` (`AppEnv.apiVersion`, already inside every `EndPoints.*`) |

## Envelope

Every JSON reply: `{ success, statusCode, statusMessage, results, error }`.
`error` = `{ message, data }`; `message` is localized by `Accept-Language`; `data` holds
field errors `[{ key, message }]` on `VALIDATION_ERROR`.
`DioConsumer` returns `results`; `success:false` on a 2xx throws like a 4xx.
`text/event-stream` routes have no envelope.

## Status → exception → failure

| HTTP | `statusMessage` examples | Exception | Failure |
|---|---|---|---|
| 400 | `VALIDATION_ERROR`, `OUT_OF_STOCK`, `CART_EMPTY` | `BadRequestException(code, details)` | `ServerFailure(400, code)` |
| 401 | `AUTHENTICATION_REQUIRED`, `TOKEN_EXPIRED`, `INVALID_TOKEN`, `INVALID_CREDENTIALS` | `UnauthorizedException` | `UnauthorizedFailure` |
| 403 | `FORBIDDEN`, `ACCESS_DENIED` | `ForbiddenException` | `ForbiddenFailure` |
| 404 | `RESOURCE_NOT_FOUND` | `NotFoundException` | `ServerFailure(404, code)` |
| 409 | `RESOURCE_EXISTS` | `ServerException` | `ServerFailure(409, code)` |
| 429 | `RATE_LIMITED`, `TOO_MANY_ATTEMPTS` (+ `Retry-After`) | `RateLimitedException(retryAfter)` | `RateLimitedFailure` |
| 5xx | `INTERNAL_ERROR`, `SERVICE_UNAVAILABLE` | `ServerException` | `ServerFailure` |
| timeout | — | `RequestTimeoutException` | `TimeoutFailure` |
| offline / TLS | — | `NoInternetConnectionException` / `NetworkException` | `NetworkFailure` |
| bad shape | — | `ParsingException` | `ParsingFailure` |

Codes live in `core/network/api_status.dart`. Add a new one there before branching on it.

## Who may call what (the spec does not declare `security`)

| Group | Auth | Headers the app adds by itself |
|---|---|---|
| Bootstrap, Catalog, Delivery lookups, Offers, Pages, Subscription plans | public (Bearer optional → personalised) | `Accept-Language` |
| Cart | guest **or** customer | guest: `X-Cart-Token` (save the one the server returns — `SessionStore.saveCartToken`); customer: Bearer |
| Assistant | guest **or** customer | guest: `X-Assistant-Guest` (32-hex, generated once) |
| Auth | public | — (never refreshed on 401: `EndPoints.authPaths`) |
| Account, Orders, Reviews (write), Notifications, Push, Support | customer | Bearer |

On login the server merges the guest cart + assistant history into the customer; the auth
datasource then calls `SessionStore.clearGuestSession()`.

## Data conventions

- **Money:** `int` fils. `1250` = 1.250 KWD. Convert only in the entity (`…Kd` getter).
- **Ids:** 24-hex Mongo ids in `_id`. Catalog reads use **slugs** (`EndPoints.product(slug)`).
- **Pagination:** `page` (1-based), `limit` (default 20, max 100), optional `search` →
  `{ data[], pagination{ total, page, limit, hasMore } }` (+ route extras such as
  `unreadCount`, `balance`).
- **Localized text:** public catalogue fields arrive already resolved for `Accept-Language`
  (a string); admin-style objects arrive as `{ en, ar }`. DTO keeps both raw; entity picks.
- **Dates:** ISO-8601 UTC strings; calendar dates (`dateOfBirth`, delivery slots) `YYYY-MM-DD`
  in Asia/Kuwait.
- **Tokens:** `{ accessToken, refreshToken, tokenType: "Bearer", expiresIn }`; access 15 min
  (`expiresIn` 900), refresh 30 days, **rotating** — a used refresh token is revoked.
- **Rate limits:** 429 with `Retry-After`; OTP routes are the strict ones.
- **Trailing slashes:** the spec lists collection routes as `/v1/orders/`; the app calls
  `/v1/orders` (both answer).

## Caching and reachability (observed live 2026-09-27)

- Public catalogue routes (`/v1/home`, `/v1/init`, `/v1/categories`, `/v1/products`, `/v1/brands`,
  `/v1/offers`, `/v1/recipes`) answer `cache-control: public, max-age=60,
  stale-while-revalidate=300`; `/v1/cart` answers `cache-control: no-store`.
- No route sends `ETag` or `Last-Modified` → no conditional GET; revalidating is a full re-fetch.
- Only `vary: Origin` is sent, yet names are resolved by `Accept-Language` → every app cache key
  carries the language.
- `/v1/home` and `/v1/init` are "Bearer optional → personalised" (`/v1/init` carries `user|null`,
  wishlist ids, delivery for the customer or the guest cart) → cached per owner, never public.
- `HEAD <host>/` answers `404` with 0 bytes in ~0.3 s: any HTTP status proves the backend is
  reachable — the app's reachability probe (plus the neutral `https://one.one.one.one`).
- Rate limit 300 requests / 60 s (`x-ratelimit-limit: 300`, `x-ratelimit-reset: 60`): probes
  run every 30 s online / 3 s offline, only in the foreground; a reconnect costs at most one
  request per stale screen plus the app-root hooks.
- The app's own cache policy (namespaces, TTLs, wipe on sign-out / expiry):
  `docs/api_integration.md` §10.

## Integration status

Update this table (and `docs/api_integration.md` §6.1) when you ship a feature.

| Feature | Backend tag / routes | Status |
|---|---|---|
| auth | Auth: `send-otp`, `verify-otp`, `refresh`, `logout`; `account/me` (restore) | **on API** |
| account — profile | `GET account/me`, `PATCH account/profile` | **on API** (form: name, email, date of birth, gender, household size; "complete your profile" while the name is the sign-up phone placeholder; profile-bonus hint from `GET init` → `store.loyalty`. Device copy of the customer in `LocalStorage` `account.profile.v1`, written only by `AuthSessionCubit`, wiped on sign-out / expiry) |
| language | `PATCH account/profile { language }` | **on API** (mirror of the device language) |
| notifications | `GET notifications`, `PATCH :id/read`, `PATCH read-all`, `GET sse`, `POST push/register` | **on API** (the SSE stream is opt-in: `--dart-define=LIVE_NOTIFICATIONS=true` — the production proxy drops the idle stream every ~60 s; no FCM / APNs token source yet → `RegisterPushTokenUseCase` has no caller) |
| account — wallet | `GET account/wallet` | **on API** (`WalletPage`, generic `LedgerCubit<WalletEntryEntity>`: balance + paginated transactions) |
| account — loyalty | `GET account/loyalty`, `GET init` → `store.loyalty` | **on API** (`LoyaltyPage`: balance, programme rules, paginated points history; programme read once per run). `LoyaltyRewardsPage` (`Routes.loyaltyRewards`): the API has **no rewards catalogue** — the tiers are an app choice (`minRedeemPoints` × 1/2/5/10, worth `redemptionPerPoint` fils each) redeemed through the cart's `POST cart/loyalty` |
| account — wishlist, viewed | Account | not built (not in the web account menu either) |
| address — saved addresses | `GET / POST account/addresses`, `PATCH / DELETE account/addresses/:addressId` | **on API** (app-global `AddressBookCubit`; device copy in `LocalStorage`, wiped on sign-out / expiry). Not built: Delivery `areas` (→ `areaId` / `governorateNo` are never sent) and `resolve-location`; `select-address` is used by checkout; the map search / reverse geocode still use `lbs_service.dart` on `package:http` (legacy); home / checkout / orders still read the offline default address |
| home | Bootstrap (`init`, `home`), `GET orders` (count) | **on API** (sealed section entities, popup frequency rules). First-order free-delivery gift popup: on by default, switched off only by `store.featureFlags.firstOrderFreeDelivery: false` (2026-09-30: `featureFlags` = `{assistant}` only; no first-order rule in offers / coupons / totals, the zone fee is still charged — backend must waive it); shown to guests and to customers whose order count is 0 (`pagination.total` of `orders?page=1&limit=1`), re-checked after a sign-in |
| shop — categories, listings, brands | Catalog (`categories`, `products`, `brands`) | **on API** (tabs → sub rail → chips over one cached tree; server-side sort / filters / paging) |
| product_details | Catalog (`products/:slug`, `products/:slug/reviews`, `offers`) | **on API** (buy-bar deal tag = the live offer whose trigger counts the product; offers cached per language in the shared catalogue datasource) |
| search | Catalog (`products?search`, `categories`, `brands`) | **on API** (recents in `LocalStorage`) |
| recipes | Catalog (`recipes`, `recipes/:slug`) | **on API** |
| marketing | Catalog (`offers`, `pages/:slug`) | **on API** (unknown page slug answers `400`) |
| store_mode — Hero Pro | Account (`subscription-plans`, `account/subscription`), Catalog (`brands`) | **on API** (paywall: plan tabs, "Save N%" on the best value per month, member = `hasBenefits` — `cancelled` + `cancelAtPeriodEnd` still has the perks until `currentPeriodEnd`). No trial / promo code / family plan in the API |
| discovery | Catalog | offline catalogue (`assets/data/hero_data.json`) |
| cart | Cart (`GET cart`, `items`, `items/:key`, `coupon`, `loyalty`, `express`) | **on API** (offline-first mirror: local projection + coalesced per-line writes, one request in flight, pending deltas rebased on the reply, stale replies dropped by generation, transport retry, mirror persisted in `LocalStorage` `cart.mirror.v1`, guest cart on `X-Cart-Token`, re-owned on sign-in / sign-out / locale change; deals strip + "Buy more, save more" sheet from `appliedOffers` / `offerProgress`, sheet products via `categories` + `products`. Quirks: a reached offer moves to `appliedOffers`; applied free delivery has `discount: 0`; an empty cart says `freeDelivery: true`; a body-less `DELETE` with a JSON content type → `500`, so `DioConsumer` always sends `{}`) |
| coupons — my coupon wallet | — (no route: the API applies a coupon **code** to the cart) | offline catalogue; the code entered in the cart goes to `POST /v1/cart/coupon` |
| checkout | Delivery (`branches`, `slots`, `select-branch`, `select-address`), Orders (`POST orders`) | **on API** (delivery to a saved address or branch pickup, ASAP / express / scheduled slot, `cod` | `wallet`, notes ≤ 256; every selection re-prices on the server; one in-flight placement). Not built: Delivery `areas` and `resolve-location` (no guest-area / drop-a-pin flow); the API has no drop-off note, tableware, tip, delivery-promise or weather field |
| checkout — store rules, offers, rail, vouchers | Bootstrap (`GET init` → `store.*`), Catalog (`GET offers`, `GET products?inStock&onSale&sort=discount_desc`), Delivery (`slots` after a selection), Cart (`coupon`, `loyalty`, `express`) | **on API** (2026-09-26 Hero-style page: `GET /v1/init` → `CheckoutStoreRules` — COD on/off, default method, loyalty programme, Pro free delivery, maintenance; store fields only, 5-min per-language cache, defaults on failure. `GET /v1/offers` enriches the cart's applied offers / progress (min, cap, `stackable`, `endsAt`, `branchIds`). The rail is on-sale, in-stock products, settled before first paint (≤ 1.2 s). `GET /v1/delivery/slots` answers 400 `VALIDATION_ERROR` "Select a delivery area or pickup branch first" before a selection — slots load after `select-address` only, non-fatal. Coupon / points / express go through the cart routes. New `CheckoutVouchersPage` (`Routes.checkoutVouchers`): code entry, applied coupon, applied / locked offers; no Apply on offers). Not built: tips, guarantees, "if out of stock", Tabby / cards (the API pays `cod` | `wallet` only), VAT line |
| orders | Orders (`GET orders`, `:id`, `:id/cancel`), Reviews (`POST reviews`) | **on API** (paginated list with status-group tabs, detail polled every 30 s while visible and non-terminal, the five cancel reasons + note, reorder through the cart batch `POST`, one review per product of a delivered order). No API for refunds → that route renders `PlaceholderPage`; no API for the rider's position, chat or call either → the live rider map (`Routes.orderLiveMap`) runs a simulated rider (`DemoCourierTrackingDataSource`) on real roads (Google Routes / OSRM through `ExternalApiConsumer`) from the real branch (`GET /v1/delivery/branches`), a simulated chat (`DemoRiderChatDataSource`) and a `tel:` call to the store line; local notifications for the ride (`core/notifications/local_alerts.dart`). Swap the demo datasources for remote ones when the backend streams riders / chat |
| support — order help | Support (`GET categories`, `POST tickets`) | **on API** (2026-09-28: `OrderHelpPage`, `Routes.orderHelp` with the order: grouped “What went wrong?” from the categories that name an order, item picker for a `requireProducts` topic, optional note, one ticket per send; the answer comes as a `support.replied` notification). Live taxonomy (2026-09-28): order (missing_items*, wrong_items*, not_received, quantity*), delivery (late, driver, wrong_address, failed), payment (charge_dispute, double_charge, not_processed), product* (damaged, expired, quality), wallet / account / subscription (no order), other (no topics); * = `requireProducts`. `ticketId` is an ObjectId (the short `ticketNumber` only comes with `GET tickets`). Not built: the ticket list / thread / replies (`GET tickets`, `GET` / `PATCH tickets/:ticketId`, `POST tickets/:ticketId/messages`), attachments (`attachmentUrls`, no upload route) |
| support — hub, FAQ, chat | — | offline catalogue |
| assistant | Assistant (`conversations`, `conversations/:id`, `messages` SSE (`POST`), `actions/:id/confirm`, `conversations/:id/handoff`, `messages/:id/feedback`), Bootstrap (`init` → `store.assistant`) | **on API** (streamed chat over `EventStreamClient.send`, every block kind, cart proposals confirmed by the customer, history, handoff, thumbs; guests on `X-Assistant-Guest`). Live quirks L1–L20 / N1–N26 in `docs/prompts/assistant_chat_prompt.md`; still open server-side: L7 (a failed turn's proposal was never stored → confirm 404s), L13 (empty `delivery_info`), N2 (a bad Bearer is ignored), N4 (in-band errors in English). Never call `handoff` live. No audio route: voice input is on-device speech-to-text sent as a normal text message |
| splash, shell | — | no backend dependency today |
| offline-first (cross-cutting) | `HEAD /` probe; the read routes above, cached | **built** (connectivity banner, device copies of the cached screens with the stale note, reconnect refresh, no queue except the cart deltas; `docs/api_integration.md` §10) |

Known gaps in core (raise them, do not patch around them in a feature):
- ~~No `NotFoundFailure`~~ — closed: `NotFoundException` maps to `NotFoundFailure`, so a
  screen shows its "not found" state without comparing `statusCode` to `404`.
- `ApiStatus` sits in `core/network`, which domain and presentation may not import → no cubit
  / use case can branch on a backend code yet (fix: move under `core/error/`, re-export from
  `failures.dart`).
- `ServerFailure` does not carry field-level validation `details`.
- User-scoped local state on sign-out is handled now: the app root drops the address book
  (`AddressBookCubit.stop()`) and re-owns the cart mirror (`CartCubit.onSignedOut()`).
- No router guard for signed-in-only routes (pages render the sign-in prompt instead).
- ~~`EventStreamClient.connect` is `GET` only~~ — closed: `EventStreamClient.send(path, data:)`
  streams a `POST` reply once (no reconnect, no replay).
