---
name: jameia-api-integration
description: Integrate a jm3eia backend endpoint (api.jm3eia.store, /v1) into a JameiaMart Flutter feature, or move a feature from the offline JameiaRepository catalogue to the real API. Use when adding or changing a remote datasource, DTO, mapper, repository, use case or cubit that talks to the backend, when adding a route to EndPoints, or when asked to integrate / connect / wire / call an API.
---

# jm3eia API integration — the build recipe

You are adding backend calls to a feature of `jameia_mart`. The transport, auth, headers,
envelope parsing, error mapping, retry and logging are **already built in `core/`**. Your job
is only the feature's vertical slice: DTO → mapper → datasource → repository → use case →
cubit → UI. Read `CLAUDE.md` first (it wins over everything), then this file.

Companion skills (load the one that matches the sub-task):

| Skill | When |
|---|---|
| `jameia-api-session` | the route needs a signed-in customer, guest headers, login/logout, or you touch tokens |
| `jameia-api-streaming` | the route is `text/event-stream` (notifications SSE, assistant messages) |
| `jameia-api-testing` | writing the tests for any layer of an API feature |
| `jameia-api-verify` | proving it works: debug trace, local mock API, emulator run |

Reference files in this skill:
- `references/layer-templates.md` — copyable code for every layer (real shapes from this repo).
- `references/patterns.md` — recipes: pagination, partial `PATCH`, optimistic updates, tolerant
  parsing, signed-out state, syncing an app-global snapshot, fire-and-forget sync.
- `references/backend-contract.md` — envelope, status codes, data conventions, and which
  features are already on the API.
- `scripts/openapi_route.js` — prints one route's params / body / `results` from the live spec.

## 0. What core already does — never rebuild it

| Concern | Already done by | You do |
|---|---|---|
| Base URL, timeouts, JSON | `buildApiBaseOptions()` + `AppEnv.apiBaseUrl` | nothing |
| `Authorization: Bearer`, refresh before expiry, refresh on 401, replay | `AuthInterceptor` | nothing — never set the header |
| `Accept-Language`, `X-Cart-Token`, `X-Assistant-Guest` | `AppHeadersInterceptor` | nothing |
| 429 backoff (3 tries) | `RateLimitRetryInterceptor` | nothing |
| Request/response trace | `NetworkLogInterceptor` (debug, log name `api`) | read it, don't add logging |
| `{success,statusCode,statusMessage,results,error}` | `DioConsumer` → returns **`results`** | parse `results` only |
| HTTP/Dio error → typed `AppException` | `ApiExceptionMapper` | throw only `ParsingException` yourself |
| `AppException` → `Failure` | `BaseRepositoryMixin.execute` / `guardStream` | wrap every repo method |
| `Failure` → text for the user | `failure.localizedMessage` (`core/utils/failure_message.dart`) | call it in the page/widget |
| SSE connection, reconnect, parsing | `EventStreamClient` | see `jameia-api-streaming` |

If something here looks missing or wrong, fix it **in core, once, with a test** — never work
around it inside a feature.

## 1. Workflow

**Step 1 — read the contract before writing code.** Never guess a field name.

```sh
node .claude/skills/jameia-api-integration/scripts/openapi_route.js            # all routes by tag
node .claude/skills/jameia-api-integration/scripts/openapi_route.js orders     # params, body, results
```

Then read the matching page under https://docs.jm3eia.store/developers/ for behavior the
schema cannot say (who may call it, guest headers, side effects). Note for each route:
method + path, auth (public / guest header / customer), query + body fields with limits,
the `results` shape, the `statusMessage` codes you must branch on.

**Step 2 — read the code you will touch.** All layers of the target feature, plus the closest
already-integrated feature as the model to mirror:

| Need | Mirror |
|---|---|
| paginated list + mutations + live stream | `features/notifications/` |
| read + partial update of one object, form validation | `features/account/` (`ProfileCubit`, `ProfileUpdate`) |
| login / tokens / app-global session state | `features/auth/` |
| fire-and-forget sync of a local setting | `features/language/` (`LocalizationCubit.syncToServer`) |

**Step 3 — path.** Add the route to `core/network/end_points.dart` if missing (constant, or a
function for parameterised paths). Routes with a trailing slash in the spec (`/v1/orders/`) are
written without it. A streaming route also goes into `EndPoints.streamingPaths`.

**Step 4 — build bottom-up** (templates in `references/layer-templates.md`):

1. **Entity** — `domain/entities/` (or `core/domain/entities/` when 2+ features use it; never
   re-declare a shared one). Immutable, `const`, `Equatable`, pure logic only. Bilingual text =
   raw `xEn` / `xAr` + `xFor(languageCode)`. Money = `int` fils (+ a `…Kd` getter).
2. **DTO** — `data/models/`. `fromJson` with named key constants, tolerant of optional / extra
   fields, **throws `ParsingException`** when an identity field is missing.
3. **Mapper** — `data/mappers/`, extensions `toEntity()` / `toEntities()`; write paths get a
   `toBody()` on the domain input object.
4. **Remote datasource** — `abstract class XRemoteDataSource` + `Impl(this._api)` on
   `ApiConsumer`. Returns DTOs / primitives, throws `AppException` only. Guard the payload with
   `ApiPayload.asMap(results, route)`.
5. **Repository** — contract in `domain/repositories/` (`Future<Either<Failure, T>>`), impl
   `with BaseRepositoryMixin`, every method `execute(() async => (await _remote.x()).toEntity())`.
6. **Use case** — one class per operation, `Params extends Equatable` in the same file. Business
   rules and input validation live here or in the entity, not in the cubit / widget.
7. **State + cubit** — one Equatable state, `SafeCubitMixin`, depends on use cases only.
8. **DI** — `<feature>_injection_container.dart` (idempotent guard), called from `_initFeatures()`
   in `config/di/service_locator.dart`. Datasource / repo / use case → `registerLazySingleton`,
   cubit → `registerFactory`.
9. **Route → widgets → page → i18n** — per `CLAUDE.md` §6–§7. Every new key in **both**
   `assets/i18n/en.json` and `ar.json`.
10. **Tests** — see `jameia-api-testing`. Every new mapper, datasource, repository, use case
    and cubit behavior gets one.

**Step 5 — migrating an offline feature.** Keep the repository **contract** and everything above
it stable; swap the implementation underneath: add the remote datasource, point the repository
impl at it, delete the `JameiaRepository` read for that operation. If the API shape forces a
contract change, change the entity/use case deliberately and update the cubit tests — never
leave a half-offline, half-remote method. Behavior that the API cannot serve yet stays on the
local datasource and is listed in your report.

**Step 6 — verify for real** (`jameia-api-verify`): `dart analyze` from the repo root (0 errors,
0 warnings in your files), `flutter test`, then run the app against the mock or dev API and
read the `api` trace for every new call: right method, path, body, headers, and the UI reacts
to success, empty, error, signed-out and offline.

**Step 7 — docs.** Add the feature's row to the table in `docs/api_integration.md` §6.1 and to
`references/backend-contract.md` (integration status). Report in the `CLAUDE.md` §0.9 shape.

## 2. Hard rules

Do:
- Depend on `ApiConsumer` (request/response) or `EventStreamClient` (streams). Nothing else.
- Put every path in `EndPoints`, every header name in `ApiHeaders`, every status code in `ApiStatus`.
- Branch on `failure.code` (`ApiStatus.*`) or the failure **type**. Show `failure.localizedMessage`.
- Send only what changed on `PATCH` (see `ProfileUpdate.diff` + `toBody()`).
- Skip one malformed list row instead of failing the page (log it, keep the rest).
- Guard async results against staleness (generation counter, `isSaving` early return) — a slow
  reply must never overwrite newer state or fire a duplicate write.
- Treat `UnauthorizedFailure` on a customer route as "signed out": show the sign-in prompt.

Never:
- `Dio()`, `package:http`, `HttpClient`, or a hard-coded host / header / path in a feature.
- Parse `success` / `statusMessage` / `error` in a datasource — you only ever see `results`.
- Set `Authorization`, read tokens, or write refresh logic in a feature. `SessionStore` is
  touched only by a datasource, and only for login / logout / guest-id work.
- Return `Either` from a datasource, import `dartz` there, or let a Dio type escape it.
- Catch-and-swallow in a repository (`try/catch → Left`): use `execute`.
- Branch on `failure.message` text — it is localized by `Accept-Language`.
- Use `print` / `debugPrint`, or add a logging interceptor. `log()` from `dart:developer` only.
- Add an interceptor anywhere but `_initNetwork` in `service_locator.dart` (order is fixed).
- Edit `pubspec.yaml`, `android/**`, `ios/**` unless the task says so. No `// ignore:` for
  `architecture_lints`.

## 3. Definition of done (API feature)

- [ ] Contract read from the live spec; field names / limits match it.
- [ ] Path in `EndPoints`; no literals for hosts, headers, codes.
- [ ] Datasource throws `AppException` only; repository uses `execute`; cubit uses use cases.
- [ ] States for loading, loaded, empty, error, signed-out (customer routes) and offline.
- [ ] Stale-reply and double-submit guards where a request can overlap another.
- [ ] Tests: DTO/mapper, datasource (`FakeHttpClientAdapter`), repository failure mapping, use
      case rules, cubit (`bloc_test`), page smoke + `test/app_router_test.dart` for a new route.
- [ ] `dart analyze` (repo root) clean in the touched area; `flutter test` all green.
- [ ] Trace checked on a running app for every new call.
- [ ] i18n keys in `en.json` + `ar.json`; RTL checked.
- [ ] `docs/api_integration.md` §6.1 + `references/backend-contract.md` updated.
