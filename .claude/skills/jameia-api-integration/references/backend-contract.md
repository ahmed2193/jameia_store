# jm3eia backend contract (what the app relies on)

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

## Integration status

Update this table (and `docs/api_integration.md` §6.1) when you ship a feature.

| Feature | Backend tag / routes | Status |
|---|---|---|
| auth | Auth: `send-otp`, `verify-otp`, `refresh`, `logout`; `account/me` (restore) | **on API** |
| account — profile | `GET account/me`, `PATCH account/profile` | **on API** (form: name, email, gender; DOB / household UI missing) |
| language | `PATCH account/profile { language }` | **on API** (mirror of the device language) |
| notifications | `GET notifications`, `PATCH :id/read`, `PATCH read-all`, `GET sse`, `POST push/register` | **on API** (no FCM / APNs token source yet → `RegisterPushTokenUseCase` has no caller) |
| account — wallet, loyalty, wishlist, viewed, subscription | Account | offline / not built |
| address | `account/addresses`, Delivery (`areas`, `resolve-location`, `select-address`) | offline (`JameiaRepository`, local persistence, `lbs_service.dart` on `package:http` — legacy) |
| home, discovery, shop, product_details, search | Bootstrap (`init`, `home`), Catalog | offline catalogue (`assets/data/jameia_data.json`) |
| cart, coupons | Cart (`items`, `coupon`, `loyalty`, `express`) | offline + local persistence |
| checkout | Delivery (`slots`, `select*`), Orders `POST` | offline |
| orders | Orders (`GET`, `:id`, `:id/cancel`), Reviews | offline |
| support | Support (`categories`, `tickets`, `messages`) | offline |
| assistant | Assistant (`conversations`, `messages` SSE, `handoff`, `actions/:id/confirm`) | not built |
| marketing, store_mode, splash, shell | — | no backend dependency today |

Known gaps in core (raise them, do not patch around them in a feature):
- `ServerFailure` does not carry field-level validation `details`.
- User-scoped local state (cart, addresses) is not cleared on sign-out.
- No router guard for signed-in-only routes (pages render the sign-in prompt instead).
- `EventStreamClient.connect` is `GET` only; the assistant reply stream is a `POST`.
