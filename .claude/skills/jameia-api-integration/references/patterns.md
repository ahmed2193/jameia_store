# Integration patterns (each one is shipped code — read the file named)

Every pattern below fixed a real bug found in review. Use them instead of rediscovering them.

## 1. Paginated list

`features/notifications/presentation/cubit/notifications_cubit.dart`,
`domain/entities/notifications_feed.dart`.

- Query `page` (1-based) + `limit` (≤ 100); reply `{ data[], pagination{total,page,limit,hasMore} }`.
- The page aggregate entity (`NotificationsFeed`) owns the list maths: `merge` (append, de-dupe
  by id), `prepend`, `replace`, `markRead`… The cubit only sequences calls.
- `loadMore()` is a no-op while `isLoadingMore`, when `!hasMore`, or before the first load.
- **Stale page guard:** `_generation` is bumped by every first-page load. `loadMore` remembers
  the generation it started under and drops its reply if a refresh happened meanwhile —
  otherwise page N+1 of the old list is appended to a fresh page 1.
- A failed refresh keeps the list on screen (`status` stays `loaded`, `failure` is set for a
  snack bar). A failed first load is the full-screen error.
- Footer: loader while `isLoadingMore`; a retry row only when `loadMoreFailed`.

## 2. Partial update (`PATCH` only what changed)

`features/account/domain/entities/profile_update.dart`,
`data/mappers/profile_update_mapper.dart`.

- A domain input object with **nullable = unchanged** fields and a `diff(current, edited…)`
  factory. `isEmpty` → nothing to send → the save button stays disabled (`state.canSave`).
- "Clear this value" is explicit (`clearGender`, empty `email`) and becomes JSON `null` in
  `toBody()`. Absent key = unchanged; `null` = clear. Never send the whole object back.
- Backend limits from the spec (`maxNameLength = 120` …) are constants on the domain object;
  validation (`isValidName`, `isValidEmail`) is pure and lives there, the state just exposes
  `showNameError`.

## 3. Forms: double submit and refresh-vs-save races

`features/account/presentation/cubit/profile_cubit.dart`.

- `save()` returns early when `state.isSaving`; the button is disabled from state too.
- A background `load()` that lands while a save is in flight **returns without emitting**
  (`if (state.isSaving) return;`) — flipping `saving → ready` re-enables the button (duplicate
  `PATCH`) and swaps the diff base mid-save.
- A slow `load()` never overwrites what the user typed: reseed the draft only when `!isDirty`.
- Seed the form from what the app already knows (`registerFactoryParam` +
  `param1: context.read<AuthSessionCubit>().state.customer` inside `create:`), then refresh.

## 4. Optimistic mutation with rollback

`NotificationsCubit.markRead`.

1. Ignore unknown / already-done targets.
2. Emit the optimistic state.
3. On `Left` → emit the inverse (`markUnread`) + `failure` + which action failed.
4. On `Right` → replace the row with the server's version.
Bulk actions that cannot be undone cheaply (`markAllRead`) wait for the server and use an
in-flight flag (`_markingAll`) instead.

## 5. Transient fields in state

`NotificationsState.copyWith`: `failure`, `failedAction`, `allMarkedRead` are **not** carried
over (`failure: failure`, not `failure ?? this.failure`), so a one-shot snack bar fires once.
Pair it with `listenWhen: (p, c) => c.failure != null && p.failure != c.failure`.
A `failedAction` enum tells the page whether the failure is full-screen or a toast.

## 6. Signed-out on a customer route

The interceptor already tried to refresh. If the datasource still gets 401 the repository
returns `UnauthorizedFailure` → state getter `isSignedOut` → the body shows the sign-in prompt
(`'…sign_in_prompt'.tr()` + button → `context.push(Routes.login)`). Do not pre-check the
session in the cubit and do not read `SessionStore` — let the 401 tell you.
Session **expiry** (refresh rejected) is handled globally: the app root routes to login.

## 7. One customer snapshot for the whole app

`AuthSessionCubit.state.customer` (`AuthCustomerEntity`, shared DTO
`core/data/models/customer_model.dart`) is the single source for the Mine header, wallet tile,
language sync… Any route that returns the customer object must push it back:
`context.read<AuthSessionCubit>().updateCustomer(customer)` from the page's `BlocListener`
(see `ProfileEditPage._onChange`). Never keep a second copy in a feature cubit that other
screens read, and never add another DTO for the same JSON.

Cross-feature import allowed only for the app-global cubits listed in `CLAUDE.md` §4.

## 8. Fire-and-forget server mirror of a local setting

`features/language/presentation/cubit/localization_cubit.dart`.

- The local change is the truth and is applied first; the server call is
  `unawaited(syncToServer())`. A failure is logged, never shown; the next switch / sign-in retries.
- The repository makes the call a **successful no-op when signed out** (datasource asks
  `SessionStore.isSignedIn`) so guests do not produce 401 noise.
- **Launch race:** the app root syncs on sign-in AND when `isInitialized` flips true, through
  `syncIfAccountDiffers(customer.language)`, which refuses to run before the saved locale is
  restored — otherwise the default `en` overwrites an Arabic account at cold start.

## 9. Tolerant parsing

`features/notifications/data/models/*.dart`, `core/data/models/customer_model.dart`.

- Identity fields missing → `ParsingException`. Everything else → default.
- `_id` **or** `id`; numbers as `num` → `toInt()`; ints that may arrive as strings → `int.tryParse`.
- Localized text may be `{en, ar}` **or** an already-resolved string: keep both raw fields in
  the DTO, pick in the entity with `pickLocalized` (`core/domain/localization/localized_pick.dart`).
- A malformed list row / SSE frame is logged and skipped; the page or stream survives.
- Unknown enum wire values → an `other` / `unknown` case, never a throw: the backend adds
  notification types and order statuses without an app release.

## 10. Branching on business errors

```dart
result.fold(
  (failure) => switch (failure) {
    ServerFailure(code: ApiStatus.outOfStock) => safeEmit(state.copyWith(outOfStock: true)),
    RateLimitedFailure(:final retryAfter) => safeEmit(state.copyWith(retryAfter: retryAfter)),
    _ => safeEmit(state.copyWith(status: XStatus.error, failure: failure)),
  },
  (_) => …,
);
```

Add a missing code to `ApiStatus` first. Field-level validation messages arrive in
`BadRequestException.details` (`[{key, message}]`) but are **not** carried by `ServerFailure`
yet — a form that needs them extends `ServerFailure` in core (one place, with a test); it does
not parse `failure.message`.

## 11. One request, many listeners

- Two screens that need the same live data share **one** upstream (the notifications
  datasource keeps a broadcast controller; see `jameia-api-streaming`).
- App-global counters (`UnreadNotificationsCubit`) are started/stopped by the app root with the
  session (`app.dart` `MultiBlocListener`), not by whichever page opens first.
- Narrow rebuilds: `BlocSelector<…, bool>` for a badge, never a whole-page `BlocBuilder`.

## 12. User-typed queries (search, autocomplete)

Debounce in the cubit (timer cancelled in `close()`) and drop stale replies with the
generation counter from §1. `ApiConsumer` exposes no cancel token on purpose — a superseded
request is simply ignored when it lands; do not reach for Dio to cancel it.
