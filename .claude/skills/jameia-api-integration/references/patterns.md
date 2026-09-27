# Integration patterns (shipped code unless marked — read the file named)

Patterns §1–§9 and §11 are shipped and each fixed a real bug found in review; §10 and §12 are
the agreed target shape for cases no feature has needed yet. Use them instead of rediscovering them.

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
(`'…sign_in_prompt'.tr()` + button → `context.go(Routes.login)` — `go`, not `push`: auth
transitions replace the stack so every page cubit is rebuilt for the new session). Do not pre-check the
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

## 10. Branching on business errors (target shape — see the blocker below)

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

**Blocker today:** `ApiStatus` lives in `core/network/api_status.dart`, and the lints forbid
`core/network` in presentation (`presentation_no_data_layer`) and in domain
(`domain_layer_purity` allows only `core/error/failures.dart` + `core/usecase`). So neither a
cubit nor a use case can import it, and nothing in `lib/` branches on a code yet. Do **not**
silence the lint or compare against a string literal. The intended fix is a small core change
— move the constants under `core/error/` and re-export them from `failures.dart` — which needs
the owner's go-ahead; raise it in your report when your feature needs a code. Until then
branch on the failure **type** / `statusCode` only.

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
generation counter from §1. `ApiConsumer` takes no cancel token today (`SafeCubitMixin.cancelToken`
exists but is not wired to it), so a superseded request is simply ignored when it lands. If
real cancellation becomes necessary, add it to `ApiConsumer` in core — never reach for Dio
from a feature.

## 13. Cache-then-network read (a screen that paints offline)

Shipped in home, search discover, shop (categories, listing page 1, brands, tabs), product
details (+ reviews page 1), recipes, marketing (offers, CMS pages), orders (list + detail),
notifications, wallet / loyalty ledgers, Pro (programme + subscription) and assistant history.
Policy table and wipe rules: `docs/api_integration.md` §10. Mirror `features/orders`
(`orders_cache_data_source.dart`, `OrdersRepositoryImpl`, `WatchOrdersUseCase`, `OrdersCubit`).

1. **Cache datasource** `data/datasources/<f>_cache_data_source.dart`: one `static const
   CacheNamespace` per read (name, scope public / owner / customer, `freshFor`, `maxAge`,
   `maxEntries`, `version`) and a method returning `CacheSlot<Model>?` from
   `CacheSlots.of(namespace, id:, parse: Model.fromJson-ish)` — `null` = do not cache now
   (unknown owner, no customer for a customer scope). The `id` tells entries apart (slug,
   normalised query, page size); the language and the owner are added by `CacheSlots`.
2. **Remote datasource** returns `RemotePayload(model, raw)` — `raw` is the `results` the
   server sent (`ApiPayload.asMap` output), kept byte for byte.
3. **Repository** `with BaseRepositoryMixin, CachedRepositoryMixin`:
   ```dart
   @override
   Stream<DataSnapshot<OrdersPage>> watchFirstPage({
     required int limit,
     bool forceRefresh = false,
   }) => cachedRead(
     cache: _cache.firstPage(limit: limit), // take the slot when the load STARTS
     fetch: () => _remote.getOrders(page: _firstPage, limit: limit),
     toEntity: (model) => model.toEntity(),
     forceRefresh: forceRefresh,
   );
   ```
   The stream emits the device copy (when there is one) and then the network snapshot; a
   `Failure` arrives on the stream's error channel, after any copy. A mutation whose reply
   answers a cached read keeps it: `keepReply(slot, payload.raw)`.
4. **Watch use case** (`StreamUseCase`, `WatchParams.cached` / `.fresh`) — the only way the cubit
   reaches it. Page 2+ stays a plain `UseCase` (never cached).
5. **Cubit** `with SafeCubitMixin, SnapshotLoaderMixin`: `followSnapshots(stream, onSnapshot:,
   onFailure:, channel:)` (a new load of the channel cancels the old one); `onSnapshot` stores
   the data + `DataFreshness(fetchedAt:, fromCache:)`; `onFailure` with data on screen →
   `freshness.failed()` + a transient `failure` (status stays loaded), without data → status
   error. `Future<void> onReconnected() => refreshOnReconnect(needed: state.freshness.isStale ||
   state.status == error, refresh: () => load(force: true))`. `close()` needs nothing extra.
6. **Page — the screen contract:**
   - data → the data; `CubitStaleNotice<XCubit, XState>(freshnessOf: (s) => s.freshness)` above
     it (shows "Updated 12 min ago" only while offline or after a failed refresh);
   - no data + failure → `FailureView(failure:, onRetry:)` (`NetworkFailure` → "Checking your
     connection…" + a live check while the app does not know it is offline, then the screen
     reloads by itself or shows the calm offline state; anything else → `ErrorView`); never a
     full-screen error over data;
   - load-more failing offline → `LoadMoreOfflineNote`, no retry button (reconnect re-asks);
   - the failure listener → `showFailureSnackBar(context, failure)` (a read that failed in
     transport shows no snack — the check and the banner speak; offline it nudges the banner);
   - wrap the body in `ReconnectRefresh(onReconnected: cubit.onReconnected, child: …)`.
7. **Tests:** cache hit (painted without a request inside `freshFor`), stale copy + network
   replace, stale copy + failure (data kept, stale note), miss + `NetworkFailure` (offline
   state), reconnect refresh (one request, none when fresh), a copy that no longer parses (a
   miss, deleted), customer scope wiped on sign-out. Fakes: `jameia-api-testing`.

Never cached: the cart (own mirror, `no-store`), profile / addresses (own device copies),
checkout data, any `POST`, search suggestions, auth / OTP, SSE frames, assistant transcripts.

## 14. Mutations while offline

- **Nothing is queued or replayed** except the cart's coalesced quantity deltas (its mirror
  flushes on reconnect). No outbox, no "send later".
- A failed submit keeps its draft (the form / sheet stays open, the fields stay filled) and the
  listener calls `showFailureSnackBar(context, failure, action: true)` → "You're offline. Your
  changes are kept …" once + a banner nudge. Online failures still show the server's text.
- A submit that must not be retried blindly (money, orders) asks first:
  `if (ConnectivityScope.readIsOffline(context) && !await ConnectivityScope.confirmOnline(context))`
  → nudge + the "needs internet" snack, send nothing. `confirmOnline` runs a live check, so a
  banner that is a probe behind never blocks a real connection (shipped: place order, cancel
  order).
- Reconnect catch-up of an app-global cubit is its `onReconnected()`, called from `app.dart`'s
  `ConnectivityCubit` listener (cart flush, session re-verify, address sync, unread badge,
  assistant availability, Pro status, language sync); a page cubit's comes from
  `ReconnectRefresh`. Neither fires while still offline.
