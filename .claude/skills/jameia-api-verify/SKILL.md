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
`account/me`, `account/profile` (PATCH), `notifications` (list / `:id/read` / `read-all` /
`sse`), `push/register`, `init`. Any phone signs in with the OTP. Every request is printed to
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
- [ ] `rate-limit/2` → retried silently; after 3 failed tries the UI shows the rate-limit message.
- [ ] Offline (airplane mode) → `core.no_internet` text + retry works when back online.
- [ ] Empty list, last page (`hasMore:false`), pull-to-refresh during load-more.
- [ ] `PATCH` sends only changed fields; an unchanged form sends nothing.
- [ ] Double tap on a submit button → ONE request in the trace.
- [ ] Stream: ONE `GET …/sse` for the whole app; `notify` updates the open screen and the
      badge; leaving the screen does not drop the app-global subscription; sign-out closes it.
- [ ] Arabic / RTL and reduced motion still fine on the new screens.
- [ ] Cold start restores the session (keychain) and the feature loads without a login.

Driving the UI: with `flutter run --debug` up, the `flutter-mcp-toolkit` tools (`fmt_*`: semantic
snapshot, tap, enter text, screenshots, hot reload) work from a fresh session; otherwise
`adb shell input …` + `adb exec-out screencap -p`. After code changes: hot reload / restart.

## 5. Static gates (always, before reporting)

```sh
dart analyze        # repo root, NO path argument → includes architecture_lints; 0 errors, 0 warnings in your files
flutter test        # all green
```

`flutter analyze` and `dart analyze <subdir>` skip the architecture plugin — they are not the gate.
