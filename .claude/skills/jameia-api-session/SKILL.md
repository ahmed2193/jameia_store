---
name: jameia-api-session
description: How the JameiaMart app authenticates against the jm3eia API — token pair storage, automatic Bearer header, refresh before expiry and on 401 via POST /v1/auth/refresh, session expiry, guest identities (X-Cart-Token, X-Assistant-Guest), sign-in / sign-out state. Use when a feature calls a customer-only route, needs to know whether the user is signed in, touches login / logout / tokens, handles a 401, or when debugging "logged out unexpectedly" or "401" problems.
---

# API session and auth — what exists, how a feature uses it

All of this is **built and tested**. A feature never re-implements any of it. Read this to know
what happens to your request and what your feature must (not) do. Full design:
`docs/api_integration.md` §6. Backend: https://docs.jm3eia.store/developers/auth.html

## The pieces

| Piece | File | Role |
|---|---|---|
| `SessionStore` / `SecureSessionStore` | `core/storage/session_store.dart` | keychain: access + refresh token, access expiry (UTC), `X-Cart-Token`, `X-Assistant-Guest`. Memoized; single-flight first reads |
| `AuthTokens` | `core/storage/auth_tokens.dart` | `{accessToken, refreshToken, tokenType, expiresIn}` |
| `AuthInterceptor` | `core/network/interceptors/auth_interceptor.dart` | Bearer + pre-flight refresh + 401 refresh + replay |
| `TokenRefresher` | `core/network/token_refresher.dart` | `POST /v1/auth/refresh {refreshToken}` on a **bare** Dio (no auth interceptor → no recursion) |
| `SessionExpiryNotifier` | `core/network/session_expiry_notifier.dart` | fires when the refresh is rejected |
| `AppHeadersInterceptor` | `core/network/interceptors/app_headers_interceptor.dart` | `Accept-Language`; guest ids **only while signed out** |
| `AuthSessionCubit` (app-global) | `features/auth/presentation/cubit/` | `status: unknown / signedOut / signedIn`, `customer`, `expired` |

## What happens to every request

1. `onRequest`: a stored access token → `Authorization: Bearer …`.
   If the token is inside the last **30 s** of its life (`expiresIn` saved at login/refresh) and
   the path is not in `EndPoints.authPaths` → refresh **first**, send with the new token.
   Refresh unreachable → send the current token anyway. Refresh rejected → tokens wiped,
   request goes out anonymous (and fails 401).
2. `onError` 401 (not an auth path, not already replayed) → refresh once → replay through the
   full chain with the rotated token. A second 401 is surfaced, never refreshed again.
3. Refresh answered 400 / 401 / 403 (`INVALID_TOKEN`) → `clearTokens()` +
   `SessionExpiryNotifier.notifyExpired()` → `AuthSessionCubit` emits `expired` → the app root
   (`app.dart`) does `appRouter.go(Routes.login, extra: true)` and the login page shows the
   "session expired" notice. A **network** failure during refresh keeps the session.
4. **Single-flight:** concurrent 401s and pre-flight checks join ONE refresh future
   (`_refreshing ??= …`, installed synchronously). Refresh tokens rotate — a second parallel
   refresh would present a revoked token and log the customer out. Never add a second refresh path.

Log names to read in the trace: `auth` (`401 … → refreshing session`, `access token expiring →
refreshing before …`, `session refreshed`, `refresh rejected … → session expired`).

## Rules for feature code

- **Never** set `Authorization`, read a token, decode a JWT, or call `/v1/auth/refresh`.
- `SessionStore` is injected into a **datasource only**, for exactly these jobs:
  - login: `saveTokens(tokens)` then `clearGuestSession()` — `AuthLocalDataSource`;
  - logout / local wipe: `clearTokens()`;
  - cart: `saveCartToken(token)` when the server hands a guest a cart token;
  - "is there a session?" for a silent no-op: `isSignedIn` (see `LangLocalDataSource`).
- Tokens never go to `LocalStorage` / shared_preferences, logs, analytics or route extras.
- "Is the user signed in?" in the **UI**: `context.select((AuthSessionCubit c) => c.state.isSignedIn)`
  (cross-feature import of this app-global cubit is allowed). In a **cubit**: do not ask —
  call the use case and treat `UnauthorizedFailure` as signed out (`state.isSignedOut` → sign-in
  prompt → `context.push(Routes.login)`).
- A route that returns the customer object → push it to the app:
  `context.read<AuthSessionCubit>().updateCustomer(customer)` (page listener).
- After a successful OTP verify the page calls `AuthSessionCubit.signedIn(customer)`; settings
  log-out calls `signOut()` (server revoke + local wipe; the wipe happens even offline).
- A new route that must never trigger a refresh (another credential exchange) is added to
  `EndPoints.authPaths`.
- Work that must start / stop with the session (badges, live streams, syncing a preference)
  is wired in `app.dart`'s `MultiBlocListener` on `AuthSessionCubit`, not inside a page.
- Guest-capable routes (cart, assistant) need nothing from you: the headers are attached
  while signed out and dropped once a Bearer exists.

## Adding state that belongs to the customer

When you integrate a feature whose local state is per-customer (cart, addresses, wishlist,
recently viewed): it must be dropped or re-fetched on **sign-out, expiry and account switch**.
Hook a listener on `AuthSessionCubit` in `app.dart` (the same place `UnreadNotificationsCubit`
is started / stopped). This is a known open gap for cart + addresses — close it when you
migrate them, and cover it with a test.

## Debugging a session problem

| Symptom | Look at |
|---|---|
| 401 loop / logged out right after login | trace: is the refresh body `{refreshToken}` the **latest** token? two `POST /v1/auth/refresh` close together = a second refresh path was added |
| Customer route returns 401 while signed in | the path was added to `authPaths` by mistake (never refreshed), or the backend really rejects the account — read the `statusMessage` in the trace |
| Guest cart lost after login | `clearGuestSession()` ran before the server merge, or `X-Cart-Token` was never saved |
| Wrong language in server messages | `Accept-Language` comes from `LocaleProvider` (`Intl.defaultLocale`), kept in sync by `LocalizationCubit` |
| Works on cold start, fails after 15 min | pre-flight refresh: check the `auth` log and the stored expiry; reproduce with the mock's `/__admin/expires-in/50` (`jameia-api-verify`) |

Tests that pin this behavior: `test/core/network/auth_interceptor_test.dart`,
`test/core/storage/session_store_test.dart`. Extend them when you touch core; never weaken them.
