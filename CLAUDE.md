# JameiaMart (jameia_mart) — Architecture & Code Rules

This file is the **contract for every agent** working in this repo: the main session,
subagents, workflow agents, builders and reviewers. The rules are hard rules, not
suggestions. They come from the team rule set in `F:\_jam3eia_apps\workflow\workflow\`.
Every agent below is a reference for this repo; read the one that matches your task
before starting, and run the review agents before reporting done (§10).

**Skills** (`skills/`)
- `project-architecture.md` — structure + core building blocks (§1–§3).
- `api-integration.md` — build order: entity → model → mapper → datasource → repository →
  use case → cubit → state → DI (§0.2, §5). Generic; for THIS repo the in-repo API skills
  below replace it.
- `flutter-reviewer.md` — the self-review checklist every builder runs before completion (§10).
- `figma-to-flutter.md` — Figma → tokens/widgets rules (used through the Figma agent).

**In-repo API skills** (`.claude/skills/<name>/SKILL.md` — auto-listed for Claude Code agents
through the Skill tool; any other agent reads the file directly). **Load the matching one
before touching anything that talks to the jm3eia backend** (§3.1, §3.2):
- `jameia-api-integration` — the build recipe for an API-backed feature / moving a feature off
  the offline catalogue. `references/layer-templates.md` (copyable code per layer),
  `references/patterns.md` (pagination, partial `PATCH`, optimistic update, race guards,
  signed-out state …), `references/backend-contract.md` (envelope, codes, conventions,
  **which features are on the API**), `scripts/openapi_route.js` (one route's params / body /
  `results` from the live spec).
- `jameia-api-session` — tokens, automatic Bearer + refresh, expiry, guest ids, sign-in state.
- `jameia-api-streaming` — `text/event-stream` routes through `EventStreamClient`.
- `jameia-api-testing` — the network fakes and the per-layer test recipe.
- `jameia-api-verify` — reading the debug API trace, the bundled mock API
  (`scripts/mock_api/server.js`), failure knobs, the on-device scenario checklist.
Shared network design: `docs/api_integration.md`.

**Build / change agents** (`agents/`)
- `flutter-feature-builder.md` — end-to-end feature build; UI composition + one-widget-per-file rules (§7).
- `flutter-figma-implementation-expert.md` — pixel-perfect UI from a Figma node, through the design tokens.
- `flutter-task-refiner.md` — turns a vague request into an implementation-ready task spec (read-only).
- `flutter-bug-fixer.md` — root-cause first, minimal-diff bug fixes.
- `refactoring-architect.md` — behavior-preserving refactors (edits files).

**Review agents** (`agents/`, all read-only)
- `flutter-architecture-auditor.md` — Clean Architecture / dependency-direction audit.
- `flutter-clean-code-reviewer.md` — clean code, SOLID, project conventions.
- `flutter-performance-reviewer.md` — rebuilds, lists, state emissions, images, network.
- `pre-pr-guardian.md` — correctness / null-safety / async / lifecycle bugs before a PR.
- `senior-pr-reviewer.md` — formal production-grade PR review with approval verdict.

**Other**: `commands/commit-message.md` (commit format), `template/feature-template.md` and
`tools/feature-prompt-generator.md` (feature prompt scaffolds), `agents/book-study-mentor.md`
(study helper, not a code agent).

When this file and existing code disagree, **this file wins**. Never copy a legacy
pattern (see §12). The `architecture_lints` analyzer plugin (`tools/architecture_lints`)
enforces most rules through `dart analyze` (see §9).

Package: `jameia_mart`. `lib/` uses relative imports; `test/` uses `package:jameia_mart/...`.
Stack: Flutter 3.47 / Dart 3.13, flutter_bloc (Cubit), get_it, go_router, dio, dartz,
equatable, easy_localization (`assets/i18n/{en,ar}.json`).

---

## 0. Agent protocol (mandatory for every agent)

1. **Read before writing.** Read this file, then the feature you touch (all layers) and
   one comparable feature. Mirror the target patterns here, not whatever the nearest
   file happens to do. Backend work: load the `jameia-api-integration` skill first and read
   the route from the live spec (`node .claude/skills/jameia-api-integration/scripts/openapi_route.js <filter>`)
   — never guess a field name, status code or limit.
2. **Build bottom-up** (api-integration order):
   entity → model (DTO) → mapper → datasource → repository contract → repository impl →
   use case → state → cubit → DI registration → route → widgets → page → i18n keys → tests.
3. **Stay in scope.** Edit only the files your task owns. When several agents run in
   parallel, respect the ownership list you were given. Never edit `pubspec.yaml`,
   `pubspec.lock`, `android/**` or `ios/**` unless the task explicitly says so.
4. **Behavior is frozen during refactors.** Same screens, data, navigation, transitions,
   texts and animations. If a rule can't be applied without changing behavior, stop and
   report it instead of guessing.
5. **Never silence the rules.** No `// ignore:` / `// ignore_for_file:` for
   `architecture_lints` rules, no new excludes in `analysis_options.yaml`, no deleting tests to go green.
6. **Verify for real** (see §11 Definition of done) and paste the actual command results
   in your report. "Should compile" is not verification.
7. **Self-review** your change against the review checklists in §10 before reporting.
8. **Git:** never commit, push, stash, reset, rebase or checkout unless the user asks.
9. **Report** in this shape: Summary · Files changed · Verification (commands + results) ·
   Behavior preserved (why) · Behavior changes required (not done) · Risks / open issues.

---

## 1. Project structure

```
lib/
├── main.dart                     # bootstrap only: bindings, EasyLocalization, setupServiceLocator(), runApp
└── src/
    ├── app.dart                  # root widget: MaterialApp.router + app-global BlocProviders
    ├── config/
    │   ├── di/service_locator.dart          # GetIt `sl` + setupServiceLocator() (composition root)
    │   ├── routes/
    │   │   ├── routes.dart                  # class Routes — every path constant
    │   │   ├── app_router.dart              # final GoRouter appRouter
    │   │   ├── feature_routes/<f>_routes.dart   # List<RouteBase> per feature
    │   │   ├── route_args/<x>_args.dart     # immutable args when a page needs >1 value
    │   │   └── placeholder_page.dart        # unknown / unbuilt routes
    │   └── theme/                # AppTheme, AppColors, AppSpacing, AppTextStyles, AppShadows
    ├── core/
    │   ├── constants/            # AppConstants, AppEnv (--dart-define build config)
    │   ├── data/
    │   │   ├── jameia_repository.dart       # offline in-memory backend (datasources only!)
    │   │   ├── jameia/                      # catalogue loader + raw catalogue models
    │   │   ├── models/                      # shared DTOs
    │   │   ├── mappers/                     # shared DTO ⇄ entity mappers (barrel: mappers.dart)
    │   │   └── repositories/base_repository_mixin.dart
    │   ├── design/               # JameiaIcons, JameiaAssets
    │   ├── domain/
    │   │   ├── entities/                    # shared framework-free entities (barrel: entities.dart)
    │   │   └── localization/localized_pick.dart
    │   ├── error/                # exceptions.dart, failures.dart
    │   ├── motion/               # AppMotion, MotionGuard, motion widgets
    │   ├── navigation/           # transition pages, showJameiaDialog / showJameiaBottomSheet, navigatorKey
    │   ├── network/              # ApiConsumer/DioConsumer, EndPoints, ApiEnvelope, ApiStatus, ApiHeaders,
    │   │                         # ApiExceptionMapper, interceptors/ (auth, headers, 429 retry, log),
    │   │                         # TokenRefresher, EventStreamClient (SSE), LocaleProvider,
    │   │                         # SessionExpiryNotifier, NetworkInfo
    │   ├── responsive/           # AppSize, Breakpoints
    │   ├── storage/              # LocalStorage (prefs), SessionStore (keychain: tokens + guest ids), initCoreStorage()
    │   ├── usecase/usecase.dart  # UseCase / SyncUseCase / StreamUseCase / NoParams
    │   ├── utils/                # formatters, context extensions, SafeCubitMixin (utils/performance)
    │   └── widgets/              # shared UI (one widget per file)
    └── features/<feature>/
        ├── data/
        │   ├── datasources/      # abstract XDataSource + XDataSourceImpl — THROW AppException
        │   ├── models/           # feature-owned DTOs only
        │   ├── mappers/          # feature DTO ⇄ entity extensions
        │   └── repositories/     # XRepositoryImpl implements XRepository with BaseRepositoryMixin
        ├── domain/
        │   ├── entities/         # feature-only entities / view aggregates
        │   ├── repositories/     # abstract contracts → Either<Failure, T>
        │   └── usecases/         # one operation per class
        ├── presentation/
        │   ├── cubit/            # x_cubit.dart + x_state.dart
        │   ├── pages/            # x_page.dart → class XPage
        │   └── widgets/          # one widget per file; sub-folder per page allowed (widgets/<page>/)
        └── <feature>_injection_container.dart    # init<Feature>Feature()
```

Nothing else is allowed inside a feature: no `screens/`, `util/`, `utils/`, `popups/`,
`helpers/`, `models/` outside `data/`, and no files at the presentation root.

Features: account, address, auth, cart, checkout, coupons, discovery, home, language,
marketing, notifications, orders, product_details, search, shell, shop, splash, store_mode,
support.
`shell` and `splash` have no data dependency, so they may contain only `presentation/`.

---

## 2. Data flow

```
Widget ──reads──▶ Cubit ──calls──▶ UseCase ──calls──▶ Repository (domain contract)
                                                          ▲ implements
                                              RepositoryImpl with BaseRepositoryMixin
                                                          │ calls
                                                      DataSource ──▶ ApiConsumer (Dio) | JameiaRepository | LocalStorage | SessionStore
Errors:  DataSource throws AppException → BaseRepositoryMixin maps it to Failure
         → UseCase returns Left(Failure) → Cubit emits status: error + message → Widget shows the error UI
```

- Arrows only point inward. Presentation never skips a layer (no cubit → repository, no
  widget → datasource, no page → `JameiaRepository`).
- Entities cross layers. DTOs stay in `data/`.

---

## 3. Core building blocks (always use, never bypass)

| Concern | Use | Never |
|---|---|---|
| HTTP | `ApiConsumer` → `DioConsumer`, paths in `EndPoints`. Returns the envelope's `results` already unwrapped | `Dio()`, `package:http` or `HttpClient` in features; parsing `success`/`statusMessage` in a datasource |
| API environment | `AppEnv.apiBaseUrl` (`--dart-define=API_BASE_URL`), headers in `ApiHeaders`, codes in `ApiStatus` | hardcoded hosts / header strings / status-code literals in features |
| API session | `SessionStore` (keychain: token pair, `X-Cart-Token`, `X-Assistant-Guest`), used **only from a datasource**; Bearer, the pre-flight refresh (token about to expire) and the 401 refresh are automatic (`AuthInterceptor`) | tokens in `LocalStorage`/prefs; manual `Authorization` headers; refresh logic in features |
| API streams (SSE) | `EventStreamClient.connect(path)` in a datasource → repository `guardStream(...)` → `StreamUseCase` → the cubit owns the subscription and cancels it in `close()`; ONE shared connection per route | a stream route through `ApiConsumer`; a retry loop / timer around the client; one connection per listener |
| API payload shape | `ApiPayload.asMap(results, route)`; DTO `fromJson` with key constants, `is` checks, `ParsingException` on a missing identity field, a bad list row skipped | `as` casts on JSON; one malformed row failing the whole page |
| Error text for the user | `failure.localizedMessage` (`core/utils/failure_message.dart`): backend text as sent, transport failures → `core.*` i18n keys | showing `failure.message` of a transport failure; building error strings in a cubit |
| Offline catalogue | `JameiaRepository`, **only inside a datasource** | reading it from a repo impl, cubit, page or widget |
| Exceptions | `AppException` → `ServerException` (`BadRequestException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `RateLimitedException`; all carry `code` = backend `statusMessage`), `NetworkException` (`NoInternetConnectionException`, `RequestTimeoutException`, `RequestCancelledException`), `CacheException`, `ParsingException` | throwing strings or raw `Exception`; importing exceptions outside `data/` |
| Failures | `ServerFailure` (`statusCode`, `code`), `UnauthorizedFailure`, `ForbiddenFailure`, `RateLimitedFailure`, `NetworkFailure`, `TimeoutFailure`, `CacheFailure`, `ParsingFailure`, `UnexpectedFailure` | exposing exceptions to the UI; branching on `failure.message` text (branch on `code`) |
| Repository errors | `with BaseRepositoryMixin` + `execute(() => …)` / `executeSync(() => …)` | a hand-written `try/catch → Left(...)` |
| Use cases | `UseCase<T, P>` (async), `SyncUseCase<T, P>` (same-frame taps), `StreamUseCase<T, P>`, `NoParams` | a cubit calling a repository |
| DI | GetIt `sl`; datasource/repo/use case → `registerLazySingleton<Interface>`, cubit → `registerFactory` | `sl` inside classes (constructor injection only) |
| Navigation | GoRouter: `context.push / go / pushReplacement / pop` + `Routes.*` + `extra:` | `Navigator.push*`, `pushNamed`, `MaterialPageRoute` |
| Transitions | `JameiaTransitionPage` / `JameiaSlideUpTransitionPage` in `pageBuilder:` | `GoRoute(builder:)` (go_router 18 falls back to no transition) |
| Dialogs / sheets | `showJameiaDialog` / `showJameiaBottomSheet` | raw `showDialog` / `showModalBottomSheet` |
| State | Cubit + one immutable Equatable state + `SafeCubitMixin` (`safeEmit`) | multiple state classes per screen, `emit` after close |
| Logging | `log()` from `dart:developer` | `print`, `debugPrint` |

### 3.1 API contract (jm3eia backend)

Full guide: `docs/api_integration.md`. Backend docs: https://docs.jm3eia.store/developers/.

- Base URL from `AppEnv.apiBaseUrl`; every route is `/v1/...` and lives in `EndPoints`.
- Every JSON response is `{ success, statusCode, statusMessage, results, error }`.
  `DioConsumer` hands datasources `results` only and throws a typed exception otherwise.
- Branch on `statusMessage` (`ApiStatus.*`) / HTTP status, never on `error.message`
  (it is localized by `Accept-Language` and is what the UI shows).
- Money is an `int` in fils (1.250 KWD = `1250`); lists paginate with `page`/`limit`
  and return `{ data, pagination: { total, page, limit, hasMore } }`.
- Interceptor chain (fixed in `service_locator.dart`): `AuthInterceptor` (Bearer; refreshes
  via `POST /v1/auth/refresh` BEFORE the request when the stored token is about to expire,
  and once on a 401; `SessionExpiryNotifier` when the refresh is rejected) →
  `AppHeadersInterceptor` (`Accept-Language`, guest ids while signed out) →
  `RateLimitRetryInterceptor` (429 backoff) → `NetworkLogInterceptor` (debug only: full
  request/response trace under the `api` log name, secrets masked;
  `--dart-define=API_LOG_SECRETS=true` reveals them).
- `text/event-stream` routes (`EndPoints.streamingPaths`) bypass the envelope: call them
  through `EventStreamClient` (`core/network/event_stream_client.dart`, auto-reconnect), never
  through `ApiConsumer`.

### 3.2 Integrating an endpoint (short form — full recipe: `jameia-api-integration` skill)

1. **Contract first.** `node .claude/skills/jameia-api-integration/scripts/openapi_route.js <filter>`
   prints the route's query / body / `results` from https://api.jm3eia.store/docs; read the
   docs page for who may call it. Add the path to `EndPoints`, a new code to `ApiStatus`.
2. **Mirror a shipped feature:** list + mutations + live stream → `features/notifications`;
   one object + partial `PATCH` + form → `features/account` (`ProfileCubit`, `ProfileUpdate`);
   tokens / session → `features/auth`; silent server mirror of a local setting → `features/language`.
3. **Build bottom-up** (§0.2). The remote datasource depends on `ApiConsumer` only, returns
   DTOs, throws `AppException`; the repository wraps every call in `execute`.
4. **Behaviors every API screen has:** loading, loaded, empty, error + retry, **signed-out**
   (`UnauthorizedFailure` on a customer route → sign-in prompt, never a pre-check of the
   session), offline. Pagination guards re-entry and drops a stale page (generation counter).
   A submit cannot fire twice and a background reload never overwrites a draft or an in-flight save.
   `PATCH` sends only the changed fields (`null` = clear, absent = unchanged).
5. **Shared customer snapshot:** any reply that carries the customer object goes back to
   `AuthSessionCubit.updateCustomer(...)` from the page listener; never a second copy or a
   second DTO (`core/data/models/customer_model.dart`).
6. **Session-bound work** (badges, live streams, syncing a preference, dropping per-customer
   state) starts / stops in `app.dart`'s listener on `AuthSessionCubit`, not in a page.
7. **Verify on a device** (`jameia-api-verify`): read the `api` / `auth` / `sse` trace (IDE
   Debug Console or DevTools Logging — `dart:developer` output is NOT in the `flutter run`
   terminal or logcat; `scripts/vm_log_tail.dart` tails it for agents), use the bundled mock
   API for writes, OTP and forced failures (expired token, revoked refresh, 429, live push).
8. **Record it:** the feature's row in `docs/api_integration.md` §6.1 and in the skill's
   `references/backend-contract.md` (integration status).

On the API today: **auth**, **account profile**, **language**, **notifications**. Every other
feature still reads the offline catalogue / local persistence (§12).

---

## 4. Layer rules

### Domain (`domain/**`, `core/domain/**`)
- Allowed imports: `dart:*`, `dartz`, `equatable`, `meta`, `collection`, other domain files,
  `core/domain/**`, `core/error/failures.dart`, `core/usecase/**`.
- Forbidden: Flutter, `intl`, `easy_localization`, `google_maps_flutter`, `dio`,
  `shared_preferences`, anything in `data/`, `presentation/`, `config/`, `core/data`, `core/utils`.
- Entities are immutable, have `const` constructors, extend `Equatable`, and carry only
  pure logic (e.g. `priceFor(bool vip)`, `hasDiscount`).
- **Localization in entities:** keep raw bilingual fields and expose pure selectors built
  on `pickLocalized(languageCode, en:, ar:)`, e.g. `String nameFor(String languageCode)`.
  Widgets call `entity.nameFor(context.locale.languageCode)`. This also rebuilds the widget
  live when the locale changes.
- Geo is `GeoPointEntity`, never `LatLng`.
- **Shared entities** (used by 2+ features or by `core/widgets`) live in
  `core/domain/entities/` (import through the `entities.dart` barrel or directly):
  `ProductEntity`, `ProductVariantEntity`, `MenuSectionEntity`, `PromoTagEntity`, `ShopEntity`,
  `CartItemEntity`, `CouponEntity`, `JameiaOrderEntity`, `OrderItemEntity`, `RiderEntity`,
  `JameiaAddressEntity`, `GeoPointEntity`, `UserProfileEntity`, `KingKongItemEntity`,
  `HomeBannerEntity`, `GatheringCardEntity`, `HomeTileEntity`, `BenefitItemEntity`,
  `HomePopupEntity`, `JameiaCategoryEntity`, `JameiaSubCategoryEntity`, `JameiaRankEntity`,
  `FeaturedSectionEntity`, `StoreSettingsEntity`, `VipCardEntity`, `AuthCustomerEntity`
  (the signed-in customer as the API returns it: wallet in fils, loyalty, pro, language,
  gender …; DTO + mapper shared in `core/data/models/customer_model.dart` /
  `core/data/mappers/customer_mapper.dart`).
  **Never re-declare these inside a feature.** Only feature-specific view aggregates live
  in `features/<f>/domain/entities/` (e.g. `HomeFeed`, `CheckoutDraft`, `OrdersView`,
  `CouponBuckets`, `ProductDetail`).
- Repository contracts return `Future<Either<Failure, T>>` (or `Either`/`Stream` for sync/stream).
- Use cases: one public operation per class, file `<verb>_<noun>_usecase.dart`, class
  `<Verb><Noun>UseCase implements UseCase<T, Params>`. Params class extends `Equatable`
  and sits in the same file. Every repository operation a cubit needs goes through a
  use case, including simple pass-throughs.

### Data (`data/**`, `core/data/**`)
- Datasources: `abstract class XLocalDataSource` / `XRemoteDataSource` plus `…Impl`.
  They return DTOs or primitives, **throw `AppException` subclasses**, and never import
  `dartz` or return `Either`.
- Remote datasources depend on `ApiConsumer` only (plus `EventStreamClient` for a
  `text/event-stream` route). Local datasources depend on `JameiaRepository` /
  `LocalStorage` / `SessionStore`. A remote datasource documents each method with its
  `METHOD /v1/path`, guards the payload with `ApiPayload.asMap`, and never sees the envelope.
- DTOs (`data/models/`): `fromJson` with named key constants and `is` checks; a missing
  identity field throws `ParsingException`, anything else falls back to a default; unknown
  enum wire values map to an `other` case; a malformed list row / stream frame is logged and
  skipped. Write bodies come from a `toBody()` mapper on the domain input object and carry
  only the changed fields.
- Mappers are extensions: `extension XMapper on XModel { XEntity toEntity() }`, list helpers
  `toEntities()`, and reverse `toModel()` only for write paths. Shared mappers live in
  `core/data/mappers/` (`mappers.dart` barrel).
- Repository impls: `class XRepositoryImpl with BaseRepositoryMixin implements XRepository`,
  and every method is `execute(() => …)` / `executeSync(() => …)` that maps DTO → entity.

### Presentation (`features/*/presentation/**`)
- Allowed imports: domain, `core/domain`, `core/widgets`, `core/navigation`, `core/motion`,
  `core/responsive`, `core/utils`, `core/design`, `core/usecase`, `core/error/failures.dart`
  (a state may hold the `Failure`; the page shows `failure.localizedMessage`), `config/theme`,
  `config/routes`, plus `config/di/service_locator.dart` **in pages only**.
- Forbidden: any `data/`, `core/data`, `core/network`, `core/storage`,
  `domain/repositories`, `*_injection_container.dart`.
- **Cubits** depend only on use cases (constructor-injected). No repositories, datasources,
  `sl`, `BuildContext`, widgets, `navigatorKey` or `package:flutter/material|widgets`
  (`foundation.dart` is fine).
- **Cross-feature imports** are allowed only for another feature's `presentation/cubit/` and
  only for app-global cubits: `CartCubit`, `StoreModeCubit`, `LocalizationCubit`,
  `SettingCubit`, `AuthSessionCubit` (sign-in state + the customer snapshot; `signOut()` from
  settings, `signedIn()` from the OTP page, `updateCustomer()` from edit-profile, `expired` →
  the app root routes to login), `UnreadNotificationsCubit` (unread badge; the app root starts
  / stops it with the session, the inbox calls `set()`). Anything else two features
  share moves to `core/`. Features never import
  other features' pages or widgets; they navigate through `Routes`.

---

## 5. Templates (copy these shapes)

```dart
// data/datasources/coupons_local_data_source.dart
abstract class CouponsLocalDataSource {
  List<Coupon> getCoupons();
}

class CouponsLocalDataSourceImpl implements CouponsLocalDataSource {
  const CouponsLocalDataSourceImpl(this._catalog);
  final JameiaRepository _catalog;

  @override
  List<Coupon> getCoupons() => _catalog.coupons; // throw CacheException on bad state
}

// data/datasources/notifications_remote_data_source.dart — the API shape
// (every layer, with pagination + PATCH + stream: jameia-api-integration/references/layer-templates.md)
abstract class NotificationsRemoteDataSource {
  /// `GET /v1/notifications?page&limit`.
  Future<NotificationsPageModel> getNotifications({required int page, required int limit});
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._api);
  final ApiConsumer _api;

  @override
  Future<NotificationsPageModel> getNotifications({required int page, required int limit}) async {
    final results = await _api.get( // `results` of the envelope; errors arrive as AppException
      EndPoints.notifications,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return NotificationsPageModel.fromJson(
      ApiPayload.asMap(results, 'notifications'), // ParsingException on a non-object payload
      requestedPage: page,
    );
  }
}

// data/repositories/coupons_repository_impl.dart
class CouponsRepositoryImpl with BaseRepositoryMixin implements CouponsRepository {
  const CouponsRepositoryImpl(this._local);
  final CouponsLocalDataSource _local;

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() =>
      execute(() => _local.getCoupons().toEntities());
}

// domain/usecases/get_coupons_usecase.dart
class GetCouponsUseCase implements UseCase<CouponBuckets, NoParams> {
  const GetCouponsUseCase(this._repository);
  final CouponsRepository _repository;

  @override
  Future<Either<Failure, CouponBuckets>> call(NoParams params) async =>
      (await _repository.getCoupons()).map(CouponBuckets.fromList);
}

// presentation/cubit/coupons_state.dart
enum CouponsStatus { initial, loading, loaded, empty, error }

class CouponsState extends Equatable {
  const CouponsState({this.status = CouponsStatus.initial, this.buckets, this.errorMessage});
  final CouponsStatus status;
  final CouponBuckets? buckets;
  final String? errorMessage;
  CouponsState copyWith({CouponsStatus? status, CouponBuckets? buckets, String? errorMessage}) => /* … */;
  @override
  List<Object?> get props => [status, buckets, errorMessage];
}

// presentation/cubit/coupons_cubit.dart
class CouponsCubit extends Cubit<CouponsState> with SafeCubitMixin<CouponsState> {
  CouponsCubit(this._getCoupons) : super(const CouponsState());
  final GetCouponsUseCase _getCoupons;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CouponsStatus.loading));
    final result = await _getCoupons(const NoParams());
    result.fold(
      (failure) => safeEmit(state.copyWith(status: CouponsStatus.error, errorMessage: failure.message)),
      (buckets) => safeEmit(state.copyWith(status: CouponsStatus.loaded, buckets: buckets)),
    );
  }
}

// coupons_injection_container.dart
void initCouponsFeature() {
  if (sl.isRegistered<CouponsRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<CouponsLocalDataSource>(() => CouponsLocalDataSourceImpl(sl()))
    ..registerLazySingleton<CouponsRepository>(() => CouponsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetCouponsUseCase(sl()))
    ..registerFactory(() => CouponsCubit(sl()));
}
// …then call initCouponsFeature() from _initFeatures() in config/di/service_locator.dart.

// presentation/pages/my_coupons_page.dart — composes only
class MyCouponsPage extends StatelessWidget {
  const MyCouponsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => sl<CouponsCubit>()..load(),
        child: const Scaffold(appBar: MyCouponsAppBar(), body: MyCouponsBody()),
      );
}
```

---

## 6. Navigation

Adding a screen:
1. Add a path constant to `Routes` (`config/routes/routes.dart`). Paths start with `/`.
2. Add a `GoRoute` in `config/routes/feature_routes/<feature>_routes.dart`:
   ```dart
   GoRoute(
     path: Routes.shop,
     pageBuilder: (_, state) {
       final shopId = state.extra;
       return JameiaTransitionPage<Object?>(
         key: state.pageKey,
         name: state.uri.path,
         child: ShopPage(shopId: shopId is String ? shopId : _fallbackShopId),
       );
     },
   ),
   ```
   Use `JameiaSlideUpTransitionPage` for full-screen slide-up presentations (PDP, viewers).
   If a page needs more than one argument, pass an immutable args class from
   `config/routes/route_args/`. Extras should be entities or primitives, never DTOs.
3. Navigate with `context.push(Routes.x, extra: arg)`. For results use
   `final value = await context.push<T>(…)` and close with `context.pop(value)`.
   Use `context.go(Routes.x)` to replace the whole stack (splash → shell, logout → login)
   and `context.pushReplacement(…)` to swap only the top page.
4. Unknown paths render `PlaceholderPage` through the router's error page.

---

## 7. UI rules

- **Pages** compose widgets, provide cubits, switch on state, and navigate. They hold no
  layout implementation beyond that composition.
- **One widget class per file**, private `_Foo` widgets included. A `StatefulWidget` and its
  `State` share a file. `CustomPainter` / `CustomClipper` / delegates get their own file.
- **No widget-returning helper methods or functions** (`Widget _buildHeader()`,
  `List<Widget> _items()`). Extract a widget class with constructor params instead.
- Widget files stay small (~120–150 lines guideline). If a UI block repeats 2+ times,
  extract it; if something is shared across features, it belongs in `core/widgets/`.
- No business logic in widgets (no filtering, pricing, sorting or persistence). Put it in
  a use case or entity and read the result from state.
- Widgets never read `sl`, repositories or datasources. Use `context.read/watch<XCubit>()`,
  `BlocBuilder`, `BlocSelector` or `BlocListener`.
- **Strings:** no hardcoded user-facing text. Use `'feature.key'.tr()`, adding keys to **both**
  `assets/i18n/en.json` and `ar.json`. Data names come from `entity.nameFor(context.locale.languageCode)`.
- **No magic values** (only `0` and `double.infinity` inline):
  colors → `AppColors`; padding/margins/gaps → `AppSpacing.sN`; widths/heights/icon sizes →
  `AppSize.sN`; radii → `AppSize.rN`; font sizes → `AppSize.fontN`; line-height →
  `AppSize.lhN`; durations/curves → `AppMotion`; text styles → `AppTextStyles`. A one-off
  value gets a named `static const` in its widget. Do not add new tokens casually; reuse
  the existing scale.
- Responsive: `Expanded`/`Flexible`/`flex` in rows/columns; theme from `AppTheme`; clamp
  text scaling via the app builder.
- RTL: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, and
  `matchTextDirection: true` on directional custom icons. Don't wrap Material directional
  icons again.
- Motion: implicit animations pass `duration:`/`curve:` through `MotionGuard`; controllers
  early-return on `MotionGuard.reduced(context)`.
- Performance: `const` constructors, `BlocSelector`/`buildWhen` for narrow rebuilds,
  `RepaintBoundary` around animated list items, and no work in `build` that belongs in
  the cubit.

---

## 8. Testing

- Location: `test/` (feature tests may use `test/features/<f>/…`, core tests `test/core/…`).
- DI setup for widget/cubit tests:
  `TestWidgetsFlutterBinding.ensureInitialized(); SharedPreferences.setMockInitialValues({}); await setupServiceLocator();`
  then provide app-global cubits (`CartCubit`, `StoreModeCubit`, …) with `BlocProvider.value`.
- Cubits: `bloc_test` with fake/mocked use cases. Repositories: test the exception → Failure
  mapping. Mappers: test round-trips. Navigation: `test/app_router_test.dart`.
- API layers (recipe: `jameia-api-testing` skill): no test touches the network or the real
  keychain. Remote datasources run through the real `DioConsumer` on a
  `FakeHttpClientAdapter` with `envelope(...)` / `okBody(...)` bodies
  (`test/core/network/network_test_fakes.dart`, which also has `InMemorySessionStore`,
  `FakeTokenRefresher`); streams use `FakeEventStreamClient`; widget tests that reach DI add
  `FlutterSecureStorage.setMockInitialValues({})` and provide `AuthSessionCubit` +
  `UnreadNotificationsCubit` with the other app-global cubits. Cubit tests cover the races
  (stale page after refresh, double submit, reload during save) with gated fake use cases.
- Every new use case, mapper or cubit behavior gets a test. Never delete or weaken a
  test to make a change pass.

---

## 9. Enforcement — `architecture_lints`

Registered in `analysis_options.yaml` under `plugins:`. Rules are warnings.

**Use `dart analyze` from the repo root with NO path argument.** `flutter analyze` (Flutter
3.47) exits before analyzer plugins report, so it shows normal Dart diagnostics only, and
`dart analyze <subdir>` loads no plugins at all. To look at one area, analyze the root and filter.

| Rule | Enforces |
|---|---|
| `feature_structure` | allowed feature folders; pages named `*_page.dart` |
| `domain_layer_purity` | domain imports only pure Dart / dartz / equatable / domain files |
| `presentation_no_data_layer` | presentation never imports data / network / storage / repositories / ICs |
| `cubit_depends_on_usecases` | cubits never import repositories, data, DI, Flutter widgets, `BuildContext` |
| `no_service_locator_outside_di` | `sl` only in `config/di`, ICs, and pages resolving cubits |
| `no_cross_feature_imports` | cross-feature imports only into `presentation/cubit/` |
| `repository_impl_uses_base_mixin` | every repository impl mixes in `BaseRepositoryMixin` |
| `datasource_no_either` | datasources throw; they don't return `Either` |
| `one_widget_per_file` | one widget class per file |
| `no_widget_helper_methods` | no `Widget _buildX()` methods/functions |
| `no_imperative_navigation` | no `Navigator.push*` outside `config/routes` / `core/navigation` |
| `no_magic_ui_values` | no numeric literals in padding/size/radius/duration/font/color args |
| `no_hardcoded_ui_strings` | no literal UI text without `.tr()` |
| `no_print_statements` | no `print` / `debugPrint` |

Commands:
```
dart analyze                                   # app + architecture_lints (gating: warnings are fatal)
dart analyze --no-fatal-warnings --format=machine | grep -i "features.<f>"   # one area
flutter analyze                                # quick Dart-only check (no architecture_lints)
flutter test                                   # app tests
cd tools/architecture_lints && dart pub get && dart test   # plugin tests (when changing a rule)
```
After editing plugin sources, restart the Dart analysis server in the IDE.
The exact plugin pins (`analysis_server_plugin`, `analyzer`) match the Dart SDK bundle:
bump them together on every Flutter/Dart upgrade and re-run the plugin tests.
Nested packages under `tools/` must stay excluded in `analysis_options.yaml` (or have their
own options file), otherwise diagnostics get reported twice.
If a rule gives a false positive, fix the rule in `tools/architecture_lints` and add a test
for it. Never ignore the diagnostic, even though `// ignore: architecture_lints/<rule>` would compile.

---

## 10. Review protocol

Every agent finishing a feature or refactor self-reviews with both checklists. Dedicated
review agents use the same checklists and output formats.

**Architecture review** (flutter-architecture-auditor) checks:
- Domain purity: no data/framework dependencies; entities framework-free; use cases hold the business logic.
- Data: repositories implement contracts; DTOs don't leak; datasources isolated; infrastructure stays in data.
- Presentation: no business logic in UI; focused widgets; clear cubit responsibilities; dependencies injected.
- Dependency direction: inward only; no circular deps, tight coupling, hidden dependencies or service-locator abuse.
- Scalability, reusability (no duplicate logic/widgets/use cases/entities), maintainability
  (no god classes/widgets, large files, feature leakage).
Output: `# Architecture Summary` · `# Architecture Findings` (each: Severity High/Medium/Low ·
Area Architecture/Dependency/Scalability/Maintainability · Problem · Future Risk ·
Recommendation, with `file:line` evidence) · `# Architectural Debt Introduced` ·
`# Scalability Assessment` (Excellent/Good/Concerning/Poor) · `# Architecture Verdict`
(PASS / PASS WITH CONCERNS / FAIL).

**Clean-code review** (flutter-clean-code-reviewer) checks: naming; SOLID (SRP, OCP, DIP,
no god classes); clean-architecture separation; structure (file size, folders, small widgets,
no duplication); readability; reusability; consistency (same patterns, state management and
error handling across features); project conventions (§7 strings/values/one-widget-per-file/
responsive/logging).
Output: `## 🔴 Issues Found` (each: Severity Critical/Major/Minor · Location `file:line` ·
Problem + broken rule · Fix) · `## ✨ Refactored Example` (when useful) · `## ✅ Summary`.

**Performance review** (flutter-performance-reviewer) checks: unnecessary rebuilds and
missing `const`; large `build` methods / no widget splitting; `ListView` vs `.builder`,
pagination, heavy items; Cubit emission overhead, whole-screen rebuilds, wrong context use;
deep trees / overdraw; image caching + decode size; repeated API calls, missing debounce,
UI blocked during requests. Output: `## 🔴 Issues Found` · `## 🟡 Severity` (High/Medium/Low)
· `## 🟢 Recommendations` · `## 🚀 Optimized Version` (when needed).

**Self-review** (skills/flutter-reviewer) — every builder runs this checklist before reporting:
layer separation, no business logic / API calls in UI; meaningful names, small focused
classes, reusable widgets; no unnecessary rebuilds / duplicated widgets / state updates;
proper state management, DI, navigation, localization. Output: Issues Found · Suggested
Improvements · Final Approval.

**Pre-PR** (pre-pr-guardian, senior-pr-reviewer): run before opening a PR; they add
correctness, null-safety, async/race, lifecycle-leak, security and test-coverage checks and
end with a production-readiness / approval verdict.

Reviewers report only evidence-backed findings (no personal preferences) and stay read-only
unless their task says to fix.

---

## 11. Definition of done

- [ ] Files are in the §1 structure; the flow follows §2; layers follow §4.
- [ ] `dart analyze` (repo root) → 0 errors and 0 warnings, including `architecture_lints`, in the touched area.
- [ ] `flutter test` → all pass; new behavior has tests.
- [ ] i18n keys exist in both `en.json` and `ar.json`.
- [ ] API work: contract read from the live spec; every new call seen once in the `api`
      trace on a running app (mock or dev host) including its failure paths
      (`jameia-api-verify` checklist); `docs/api_integration.md` §6.1 and the skill's
      `references/backend-contract.md` status table updated.
- [ ] Behavior unchanged (refactors) or matches the requirement (features); RTL and reduced motion still work.
- [ ] Self-review against §10 done; report written in the §0.9 shape.

---

## 12. Migration status (temporary — delete this section when the refactor is complete)

The whole-app refactor to these rules is in progress. The code below is **legacy**:
don't copy it, and migrate it when you own the file.

- Per-feature duplicates of shared entities (`features/*/domain/entities/{shop,product,product_variant,jameia_address,jameia_order,user_profile,coupon}_entity.dart` …) → replace with `core/domain/entities/`.
- `features/*/presentation/util/*_display.dart`, `…/util/*_bridge.dart`, `home/presentation/popups/` → replace with entity `nameFor/titleFor(lc)` and move widgets into `presentation/widgets/`.
- Cubits calling repositories directly (collapsed use cases) → add a use case per operation.
- Repository impls with a hand-written `try/catch → Left(CacheFailure)` → `BaseRepositoryMixin.execute`.
- `core/widgets` taking DTOs (`ShopCard`, `ProductCard`, `PromoRibbon`, `BannerCarousel`) → take core entities.
- Route extras that are still DTOs (`Product`, `JameiaAddress`, `KingKongItem`) → entities.
- `core/utils/lbs_service.dart` using `package:http` → an address remote datasource on `ApiConsumer`.
- **Offline → API.** Only auth, account profile, language and notifications call the jm3eia
  backend. home / discovery / shop / product_details / search (Catalog, `init`, `home`), cart +
  coupons (Cart), checkout (Delivery, Orders), orders, address (`account/addresses`, Delivery),
  support, wallet / loyalty / wishlist still read `JameiaRepository` or local persistence →
  migrate with the `jameia-api-integration` skill: keep the repository contract, swap the
  datasource underneath, one operation at a time. Open core gaps to close on the way:
  per-customer local state (cart, addresses) is not dropped on sign-out; `ServerFailure` has
  no field-level validation `details`; `EventStreamClient` is `GET` only (assistant replies
  stream from a `POST`); no FCM / APNs token source calls `RegisterPushTokenUseCase`; no
  router guard for signed-in-only routes.
- Multi-widget files, `_buildX()` helpers, inline numeric literals, and `sl<…>()` in widgets/cubits.
- `core/storage/storage_injection.dart` registers DI outside `config/di` → move it into `config/di`.
- **Review-found legacy** (details + file:line in `docs/architecture_review.md`; lints can't see these):
  - Datasources that translate text, use motion tokens, compute business rules or invent demo data, and return domain aggregates (`orders_local_data_source`, `product_details_dummy_data_source`) → datasources return DTOs; rules move to use cases/entities; strings resolve in widgets.
  - Pricing/VAT/fee/line-total maths in widgets or cubit state (orders invoice/summary/refund) → one domain price-breakdown value object.
  - Pages with no cubit that read repositories through `sl` and reshape DTOs in `State` (`ShopPage`, `ShopMapPage`) and god `State`s calling infrastructure (`AddressEditPage` → `JameiaLbs` / `JameiaLocation` / `JameiaGeocode`) → cubit + use cases + datasources.
  - `core/utils/jameia_geocode.dart` (541 lines: enums, form schema, DTO, geometry, `LatLng`) → split into address domain entities, a data geometry service and presentation helpers.
  - Mutations whose `Either` is ignored with success UI shown anyway (orders review/refund), and form input never submitted → cubit emits error/success; page listens.
  - Validation / label / pricing rules duplicated across cubit, state and widgets (address has 5 disagreeing validity checks; SKU/variant pricing in both `ShopSkuCubit` and `ProductDetailCubit`) → single use case or entity method.
  - Cross-feature widget reuse (`shop/…/product_sku_sheet.dart` used by product_details; PDP card copies home rail add/stepper controls) → `core/widgets` (+ shared cubit/use case).
  - Multi-value route args packed in strings (`catId~subId~rankId` built in the home data layer, parsed in `shop_page`) → a `route_args` class.
  - Home filters identified by substrings of i18n keys (`SelectHomeFilterUseCase`) and rendered without `.tr()` → a filter enum/entity with a label key.
- Baseline when this list was written: 1,876 `architecture_lints` warnings (magic values 1,263, one-widget-per-file 414, presentation→data 52, cubit→repository 44, …).
