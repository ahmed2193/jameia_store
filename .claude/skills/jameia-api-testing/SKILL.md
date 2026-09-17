---
name: jameia-api-testing
description: Write the tests for a JameiaMart feature that talks to the jm3eia API — DTO / mapper, remote datasource with a scripted HTTP transport, repository exception-to-failure mapping, use case rules, cubit with bloc_test (races, pagination, optimistic rollback), page smoke tests and router coverage. Use when adding tests for an API-backed layer, when a network test fails, or when you need the project's fakes (FakeHttpClientAdapter, InMemorySessionStore, FakeEventStreamClient, gated use-case fakes).
---

# Testing an API feature

No test ever touches the network or the real keychain. Location: `test/features/<f>/…`,
core tests in `test/core/…`. `test/` imports with `package:jameia_mart/...`.
Never delete or weaken a test to go green (`CLAUDE.md` §0.5 / §8).

## The fakes you already have

`test/core/network/network_test_fakes.dart`

| Fake | Use |
|---|---|
| `FakeHttpClientAdapter((options, callIndex) => ResponseBody)` | scripted transport; `.requests` records every `RequestOptions` (snapshot per call, so replays are visible) |
| `envelope(status:, statusMessage:, results:, errorMessage:, errorData:, headers:)` | a real jm3eia envelope body |
| `okBody(results)` | 200 `SUCCESS` envelope |
| `InMemorySessionStore` | `accessToken`, `refreshToken`, `accessTokenExpiry`, `cartToken`, `clearTokensCalls` |
| `FakeTokenRefresher((refreshToken) => AuthTokens)` | counts `calls` |
| `FakeLocaleProvider`, `RecordingExpiryNotifier` | headers / expiry assertions |

Feature-level: `test/features/notifications/notifications_test_fakes.dart`
(`FakeEventStreamClient`, entity builders `notification(...)`, `feedOf(...)`, use-case fakes),
`test/features/account/account_test_fakes.dart` (gated fakes), `test/features/auth/auth_test_fakes.dart`
(`FakeRestoreSessionUseCase`, `FakeLogoutUseCase`, `FakeWatchSessionExpiryUseCase`).
Put a new feature's fakes in `test/features/<f>/<f>_test_fakes.dart`.

## One test file per layer

### DTO + mapper — `<x>_model_test.dart`
Full payload copied from the spec; minimal payload (only required fields); `_id` vs `id`;
`{en, ar}` vs plain string; number as `int` / `double` / string; unknown enum value → `other`;
missing identity → `throwsA(isA<ParsingException>())`; list with one bad row → the rest
survives; `toEntity()` field by field; write-path `toBody()` sends **only** changed keys and
`null` for "clear".

### Remote datasource — `<x>_remote_data_source_test.dart`

```dart
XRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
  adapter = transport;
  final dio = Dio()..httpClientAdapter = adapter;
  return XRemoteDataSourceImpl(DioConsumer(dio));
}

test('getLedger GETs /v1/account/wallet with page + limit', () async {
  final dataSource = build(FakeHttpClientAdapter((_, _) => okBody({'data': [], 'pagination': {}})));
  await dataSource.getLedger(page: 2, limit: 20);
  final request = adapter.requests.single;
  expect(request.method, 'GET');
  expect(request.path, EndPoints.accountWallet);
  expect(request.queryParameters, {'page': 2, 'limit': 20});
});
```

Assert: method, `EndPoints.*` path, query, body (`Map<String, dynamic>.from(request.data as Map)`),
parsed result; non-object payload → `ParsingException`; 401 envelope → `UnauthorizedException`;
a business 400 → `BadRequestException` with the right `code`. Going through the real
`DioConsumer` proves the envelope unwrap + error mapping with your route.

### Repository — `<x>_repository_impl_test.dart`
Hand-written `_FakeRemote implements XRemoteDataSource` with an `Object? error` to throw.
One success test (DTO → entity) + the mapping table you rely on:
`UnauthorizedException → UnauthorizedFailure`, `NoInternetConnectionException → NetworkFailure`,
`RequestTimeoutException → TimeoutFailure`, `ParsingException → ParsingFailure`,
`ServerException(code: …) → ServerFailure` **with the same `code`**. Streams: an upstream error
reaches the listener as a `Failure` (`guardStream`).

### Use case — only when it holds a rule
Validation that returns `Left` without calling the repository (assert the fake saw 0 calls),
aggregation / sorting / defaults. A pure pass-through needs no dedicated test.

### Cubit — `<x>_cubit_test.dart` with `bloc_test`
Fake use cases = small classes implementing the use case, with a mutable `result`, recorded
`calls`, and a **gate** for races:

```dart
class FakeGetXUseCase implements GetXUseCase {
  FakeGetXUseCase(this.result);
  Either<Failure, X> result;
  final List<GetXParams> calls = [];
  Completer<void>? gate; // hold the reply to test in-flight behavior

  @override
  Future<Either<Failure, X>> call(GetXParams params) async {
    calls.add(params);
    await gate?.future;
    return result;
  }
}
```

Cover at least: load success / failure; signed-out (`Left(UnauthorizedFailure)` →
`isSignedOut`); empty; pagination (`loadMore` appends, no-op when `!hasMore` / in flight,
failure sets `loadMoreFailed`); **refresh during loadMore drops the stale page**; optimistic
mutation + rollback on failure; double tap sends ONE request; a background load landing
mid-save emits nothing; transient fields (`failure`) cleared by the next emit; stream item
updates state; `close()` cancels the subscription.
State classes need `Equatable` props complete — a missing prop makes `expect:` lie.

### Page / widget — `<x>_page_test.dart`
Setup used across the repo:

```dart
TestWidgetsFlutterBinding.ensureInitialized();
SharedPreferences.setMockInitialValues({});
FlutterSecureStorage.setMockInitialValues({});
await EasyLocalization.ensureInitialized();
await setupServiceLocator();
// load en.json into easy_localization (see profile_edit_page_test.dart) so `.tr()` resolves
```

Swap the cubit factory for one built on fakes:
`sl..unregister<XCubit>()..registerFactory(() => XCubit(fakeUseCase));`
Provide the app-global cubits above the page with `BlocProvider.value`: `CartCubit`,
`StoreModeCubit`, `LocalizationCubit`, `SettingCubit`, `AuthSessionCubit`,
`UnreadNotificationsCubit`. Assert the five faces of the screen: loading, loaded, empty, error
(+ retry), signed-out prompt. Dates rendered through `intl` may contain U+202F — normalize
before comparing.

### Router — `test/app_router_test.dart`
Every new `Routes.*` constant gets a case there (it builds the real route table).

## Core changes

Touching `core/network` or `core/storage` means extending its test in `test/core/…`
(`auth_interceptor_test`, `dio_consumer_test`, `event_stream_client_test`,
`network_log_interceptor_test`, `rate_limit_retry_interceptor_test`, `session_store_test`).
Inject time and waiting (`now:`, `wait:`) instead of sleeping; the interceptors already take
them as constructor parameters.

## Commands

```sh
flutter test test/features/<f>        # while iterating
flutter test                          # before reporting — all must pass
dart analyze                          # repo root, no path argument (loads architecture_lints)
```

Paste the real totals in your report.
