---
name: jameia-api-verify
description: Prove a jm3eia API integration works in the running JameiaMart app — read the debug request/response trace (NetworkLogInterceptor, log names api / auth / sse), run the bundled local mock API on the emulator, force token expiry, revoked refresh, 429 and live pushes, point the app at another host with --dart-define. Use after building or changing an API feature, when asked to view the API calls and responses, or when debugging a request that fails on device.
---

# Verifying an API integration on a running app

"Tests pass" is not the end. Every new call is watched once on a device: right method, path,
body, headers, and the UI reacts to success, empty, error, signed-out and offline.

## 1. Read the trace

`NetworkLogInterceptor` (debug builds only, last in the chain, also on the bare refresh
client) logs one block per request / response / error under the log name **`api`**:

```
--> #7 PATCH /v1/account/profile
    url: http://10.0.2.2:5055/v1/account/profile
    headers:
      Accept-Language: ar
      Authorization: Bearer acc_…3f9a
    body:
      { "language": "ar" }
<-- #7 200 PATCH /v1/account/profile (41ms) UPDATED
    body: { … }
xx  #8 401 GET /v1/account/me (12ms) TOKEN_EXPIRED
```

`#n` pairs a response with its request. Session events are under **`auth`**, stream events
under **`sse`**. Secrets (keys containing `authorization`, `token`, `secret`, `password`,
`cookie`, `guest`) are masked `abcd…wxyz`; `--dart-define=API_LOG_SECRETS=true` reveals them
(never paste revealed output into a report). Bodies cap at 4000 chars; > 256 KB is summarised.

**Where it shows up.** `dart:developer` `log()` goes to the VM *Logging* stream:
- IDE **Debug Console** (VS Code / Android Studio, launched with the debugger), or DevTools → Logging.
- It does **not** appear in a plain `flutter run` terminal or in `adb logcat`.
- Agents without an IDE: tail it with the bundled script —

```sh
# take the URI from the `flutter run` line "A Dart VM Service on … is available at: http://127.0.0.1:PORT/TOKEN=/"
dart run .claude/skills/jameia-api-verify/scripts/vm_log_tail.dart http://127.0.0.1:PORT/TOKEN=/ 120 api,auth,sse
```

  (drop the name filter to also see feature logs such as a skipped malformed row — those
  use the class name, e.g. `NotificationsPageModel`)
  or, when the `flutter-mcp-toolkit` / `dart` MCP servers are connected, read runtime logs
  through them. Do **not** add `print` / `debugPrint` to see traffic — the rule forbids it and
  the lint fails the build.

## 2. Pick a backend

| Target | Command |
|---|---|
| Live dev API (default) | `flutter run` → `https://api.jm3eia.store` |
| Local mock, Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5055` |
| Local mock, iOS simulator / desktop | `--dart-define=API_BASE_URL=http://127.0.0.1:5055` |
| Physical device | `--dart-define=API_BASE_URL=http://<host-LAN-ip>:5055` |

Plain `http://` needs no native config for Dio (details: `docs/api_integration.md` §1). Never
edit `android/**` / `ios/**` for this.

Use the **live API** for read-only public routes. Use the **mock** for anything that writes,
needs an OTP, or needs a failure you cannot trigger on a real server. Never run destructive or
bulk calls against the live host, and never put a real customer's phone / token in a file.

## 3. The mock API (`scripts/mock_api/server.js`)

Zero-dependency Node server that speaks the real envelope.

```sh
node .claude/skills/jameia-api-verify/scripts/mock_api/server.js     # run in the background
# port: MOCK_API_PORT (default 5055) · OTP: env OTP (default 1234) · listens on 0.0.0.0
```

Implemented: `auth/send-otp`, `auth/verify-otp`, `auth/refresh` (rotating), `auth/logout`,
`account/me`, `account/profile` (PATCH; credits the one-time profile bonus of 50 points
once `dateOfBirth` + `gender` + `householdSize` are set), `account/wallet` and
`account/loyalty` (24 seeded rows each, paged), `notifications` (list / `:id/read` / `read-all` /
`sse`), `push/register`, `init` (with `store.loyalty`), `account/addresses` (GET / POST, `:id` PATCH / DELETE, spec
limits validated, one default address), `cart` (GET, `items` POST batch / `:key` PATCH / `:key`
DELETE / clear, `coupon`, `loyalty`, `express`), `delivery` (`branches`, `slots`,
`select-branch`, `select-address`), `orders` (list with `status` filter + paging, `:id`,
`:id/cancel`) and `reviews` (POST). The commerce state is in `mock_api/commerce.js`
(5 products, 3 branches, free delivery over 10.000 KWD, an express surcharge, a min order,
offer progress, wallet payment and the full order status flow). Any phone signs in with the OTP. Every request is printed to
the server's stdout (method, path, short auth, language, guest id, body).

Failure knobs (all `POST` unless noted):

| Call | Effect |
|---|---|
| `/__admin/expire-access` | current access tokens die → next call 401 → **refresh + replay** |
| `/__admin/revoke-refresh` | refresh answers 401 `INVALID_TOKEN` → app must land on login with the expired notice |
| `/__admin/expires-in/50` | new pairs live 50 s → watch the **pre-flight** refresh (no 401 in the trace) |
| `/__admin/rate-limit/2` | next 2 requests answer 429 `Retry-After: 1` → backoff + replay |
| `/__admin/notify` `{type,title,body,orderId}` | creates an unread notification and pushes it over SSE |
| `GET /__admin/log` | the request log as JSON |
| `GET /v1/account/me?expire=1` | always 401 `TOKEN_EXPIRED` |
| `/__admin/addresses/seed/2` | adds 2 sample addresses to the signed-in customer (the first one ever is the default) |
| `/__admin/addresses/fail/500/1` | the next address request answers 500 `INTERNAL_ERROR` (any status: 404 → `RESOURCE_NOT_FOUND` …) |
| `/__admin/addresses/delay/3000` | address replies wait 3 s → in-flight UI, double tap sends ONE request (`0` turns it off) |
| `/__admin/ledger/fail/500/1` | the next wallet / loyalty request answers 500 (any status) → error view / load-more retry |
| `/__admin/subscription/fail/500/1` | the next Pro subscription request answers 500 (any status) → snackbar, buttons back on |
| `/__admin/subscription/delay/3000` | subscribe / cancel replies wait 3 s → loader on the CTA, double tap sends ONE request |
| `/__admin/subscription/ends-in/90` | the paid period ends in 90 s; the next subscription request after that finds it `expired`. Open the Pro page once so the app learns the new end, then wait: its period-end re-check (end + 1 min) turns the member into "Rejoin" everywhere, without a restart |
| `/__admin/subscription/reset` | no subscription again, `customer.pro` inactive |
| `/__admin/profile/reset` | the customer is back in the sign-up state (name = phone, no date of birth / gender / household, bonus not paid) → "Complete your profile" + the bonus hint |
| `/__admin/cart/out-of-stock/<productId>` | that product answers `400 OUT_OF_STOCK` on add / update |
| `/__admin/cart/stock/<productId>/3` | caps the stock → the line comes back with `quantityReduced` and `blocksCheckout` |
| `/__admin/cart/delay/800` | cart replies wait 800 ms → watch the coalescing: fast taps still send ONE request (`0` off) |
| `/__admin/cart/closed/1` | the branch is closed → `canCheckout:false`, checkout blocked |
| `/__admin/cart/capacity/1` | no delivery capacity → slots come back unbookable |
| `/__admin/orders/advance/<orderId>` | pushes the order one status forward (placed → … → delivered) |
| `/__admin/orders/fail/<orderId>` | marks it `delivery_failed` with a reason |
| `GET /__admin/orders` | every order as JSON |

Assistant (`scripts/mock_api/assistant.js`; scripted replies by keyword — `butter eggs milk …` →
products, `add 2 butter` → proposal, `my cart`, `track`, `orders`, `offers`, `recipe`, `faq`,
`categories`, `brands`, `slots`, `fee`, `area` (empty L13 card), `branch`, `escalate` (N6),
`error`, `future` (unknown kind), `markdown`, `long`, `everything`; Arabic equivalents too):

| Knob | Effect |
|---|---|
| `/__admin/assistant/reset` | no conversations / proposals / tickets, knobs off |
| `/__admin/assistant/fail-persist/1` | next turn streams its cards + text, then `error` (L7: its proposal 404s) |
| `/__admin/assistant/error-frame/1?code=X` | next turn: half the text, then `error {code}` → "Retry" / "Talk to a person" |
| `/__admin/assistant/drop-mid-stream/1` | socket closed mid-text, no terminal frame (the reply is still saved) |
| `/__admin/assistant/slow/3000` · `stall/70000` | wait before the first word, with / without heartbeats |
| `/__admin/assistant/closed/1` | next send finds its thread closed → `message_start` carries a NEW id |
| `/__admin/assistant/disabled/0` · `guests-off/1` · `flag/0` | assistant off / guests refused (401) / feature flag off — `GET /v1/init` follows |
| `/__admin/assistant/rate-limit/2` · `validation/1` | 429 with `Retry-After` / 400 before the stream |
| `/__admin/assistant/fail/<list|detail|confirm|feedback|handoff>/<status>/<n>` | that route fails n times |
| `/__admin/assistant/delay/3000` | JSON routes wait 3 s (double taps, in-flight UI) |
| `/__admin/assistant/expire-actions` | every pending proposal 404s on confirm |
| `/__admin/assistant/strict-auth/1` | an unknown Bearer gets 401 `TOKEN_EXPIRED` instead of being ignored (N2) |
| `/__admin/assistant/seed/45?owner=customer` | 45 finished conversations over the last weeks (history paging) |

```sh
curl -s -X POST http://127.0.0.1:5055/__admin/notify -H "Content-Type: application/json" \
  -d '{"type":"order.delivered","title":"Delivered","body":"Your order arrived"}'
```

**Extending it for your feature** is part of the job when the route is not there yet: add the
route next to the others, reply with `ok(res, results, 'DATA_LOADED')` / `fail(res, status,
'CODE', message)`, copy the `results` shape from `openapi_route.js` output, guard customer
routes with the existing Bearer check, and add a knob for the failure your UI must survive.
Keep it dependency-free. Git Bash on Windows rewrites arguments that start with `/` — quote
full URLs.

## 4. Scenario checklist

Run the ones that apply and quote the trace lines in your report.

- [ ] Happy path: request block has the right method / path / query / body; response code is
      the expected `statusMessage`; UI shows the data.
- [ ] `Accept-Language` flips with the app language; server text follows.
- [ ] Signed out: customer route → 401 → sign-in prompt (no crash, no retry storm).
      Guest route carries `X-Cart-Token` / `X-Assistant-Guest` and **no** Bearer.
- [ ] Signed in: Bearer present, guest headers gone.
- [ ] `expire-access` → one `POST /v1/auth/refresh`, then the original call replayed, UI never notices.
- [ ] `expires-in/50`, wait → refresh happens **before** the call.
- [ ] `revoke-refresh` → login page with the expired notice; feature state is gone.
- [ ] `rate-limit/2` → retried silently (the interceptor allows 3 retries = 4 requests);
      `rate-limit/4` → the retries run out and the UI shows the server's rate-limit message.
- [ ] Offline (airplane mode) → the banner, the screen's device copy with the stale note (or
      the calm offline state when nothing was saved); back online → the screen refreshes by
      itself. Full offline list below.
- [ ] Empty list, last page (`hasMore:false`), pull-to-refresh during load-more.
- [ ] `PATCH` sends only changed fields; an unchanged form sends nothing.
- [ ] Double tap on a submit button → ONE request in the trace.
- [ ] Stream (build with `--dart-define=LIVE_NOTIFICATIONS=true`; without it there is NO
      `GET …/sse` at all): ONE `GET …/sse` for the whole app; `notify` updates the open screen and the
      badge; leaving the screen does not drop the app-global subscription; sign-out closes it.
- [ ] Arabic / RTL and reduced motion still fine on the new screens.
- [ ] Cold start restores the session (keychain) and the feature loads without a login.
- [ ] Cart: fast ± taps render instantly and collapse into ONE request per line; killing the
      app mid-queue and reopening it replays the queue; a signed-out cart carries
      `X-Cart-Token`, and signing in re-owns the mirror.
- [ ] Checkout: a selection re-prices from the server; a double tap on Place order sends ONE
      `POST /v1/orders`; success replaces the page with tracking.
- [ ] Tracking: `GET /v1/orders/:id` repeats every 30 s while the page is on top, stops when
      another page covers it / the app is backgrounded / the status is terminal.

### Offline checklist (the offline-first build; record each result)

Tools: `adb shell cmd connectivity airplane-mode enable|disable` (or `adb shell svc wifi disable` +
`adb shell svc data disable`); emulator console `network delay gprs` / `network speed gsm`; the
mock API's 5xx / 429 knobs. Log names: `connectivity` (probe results, monitor paused / resumed),
`cache` (saved / dropped / skipped with namespace, key hash and size — never a payload), `api`.

- [ ] Cold start ONLINE on a real phone (debug build, slow first probe): never a banner flash —
      a single failed probe is confirmed by a second check before "offline" (`connectivity`
      log: `probe → unreachable (5000+ms)` then `probe → reachable`, no `ConnectivityCubit`
      offline).
- [ ] Cold start offline, first install: splash → home says "Checking your connection…" →
      "No connection" together with the banner (never "No connection" straight away). Online →
      "Back online", home loads by itself.
- [ ] Visit home, categories, a listing, 2 PDPs, recipes, orders online; kill; airplane on;
      relaunch → each paints from the cache with "Updated … ago"; no generic error anywhere.
- [ ] Listing offline: a cached and an uncached filter / sort; the load-more footer says it
      will load when back; reconnect loads it.
- [ ] PDP never opened, offline: the tapped preview stays, the inline offline note, reconnect
      fills it in.
- [ ] Cart offline, 3 taps: no snack spam for minutes; reconnect → the flush at once (trace).
- [ ] Checkout offline: the calm offline line in the bar; Place order runs a live check and
      sends NOTHING while offline; online → places normally, once.
- [ ] Mock API 500 while online: the normal error UI, NO banner.
- [ ] Wi-Fi without internet (if available) → offline.
- [ ] Sign out → `adb shell run-as <applicationId> ls -R cache/api_cache`: `customer/` is gone;
      `public/` (and `guest/`) stay. No token / OTP / header in any file.
- [ ] Arabic + RTL: banner, stale-note plurals (1, 2, 3–10, 11+ minutes), offline state.
- [ ] The banner text sits on a `Material` (it is above the navigator): no yellow double
      underline under "You're offline" / "Back online".
- [ ] Reduced motion: no animation, instant swaps.
- [ ] 5 min in the background offline → no `connectivity` probe lines; resume → one probe.
- [ ] Reopen a screen inside its fresh TTL → no request in the `api` trace; after it → the copy,
      then ONE revalidation. Pull-to-refresh always fetches.

Driving the UI: with `flutter run --debug` up, the `flutter-mcp-toolkit` tools (`fmt_*`: semantic
snapshot, tap, enter text, screenshots, hot reload) work from a fresh session; otherwise
`adb shell input …` + `adb exec-out screencap -p`. After code changes: hot reload / restart.

## 5. Static gates (always, before reporting)

```sh
dart analyze        # repo root, NO path argument → includes architecture_lints; 0 errors, 0 warnings in your files
flutter test        # all green
```

`flutter analyze` and `dart analyze <subdir>` skip the architecture plugin — they are not the gate.
