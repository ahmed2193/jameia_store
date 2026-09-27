# FEATURE NAME

Offline-first Hero. The app knows when the connection drops, tells the customer calmly,
keeps showing what they last saw, and recovers by itself when the connection returns.

---

## CONTEXT

Hero is fully on the Hero API (catalogue, cart, checkout, orders, account, notifications,
assistant). Today the app has **no connection awareness and no response cache**. Every screen
behaves as if the network is always there. Popular delivery apps (Instacart,
Instagram, YouTube) handle this in one consistent way:

1. A calm, app-wide "You're offline" signal. It is not an error.
2. The last content the customer saw stays on screen, with a small "Updated 12 min ago" note.
3. Recovery is automatic: stale screens refresh, queued cart taps sync, and a short "Back online"
   confirmation shows.
4. Actions that need the server say so kindly and keep the customer's input.

This task brings the whole app to that standard.

### What exists today (verified 2026-09-27; paths under `lib/src/`)

**Connectivity**
- `core/network/network_info.dart` wraps `internet_connection_checker_plus` 3.1.2 (`hasInternetAccess`).
  It is registered in `config/di/service_locator.dart:107`, but **nothing reads it**. There is no
  status stream, no banner and no `ConnectivityCubit`.
- `core/constants/app_constants.dart:43-46` already declares `connectivityPoll = 3s`, "for
  [ConnectivityCubit] … offline banner". That class was never built.
- The package's default probes are Cloudflare, icanhazip, Google's CDN and Apple's captive portal,
  **not our API**. It polls every 10 s while listened to. It supports `createInstance(customCheckOptions,
  useDefaultOptions, checkInterval, customConnectivityCheck, triggerStream)` and `setIntervalAndResetTimer`.

**Errors**
- `DioExceptionType.connectionError` becomes `NoInternetConnectionException`, then `NetworkFailure`,
  then `'core.no_internet'`. Timeouts (20 s, `AppConstants.connectTimeout`) become `TimeoutFailure`.
- No state marks anything as "offline". Offline is just another `NetworkFailure`.

**Existing device persistence** (keep all of it; do not migrate it)

| Key | What | Notes |
|---|---|---|
| `cart.mirror.v1` | Server cart mirror + pending deltas | The only real offline queue. Retries 5 s → 80 s. `cart_sync_banner.dart` shows `cart.unsynced`. `CheckoutBlockReason.offline` exists but is tied to the unsynced cart only |
| `account.profile.v1` | `CustomerModel` snapshot | `AuthSessionCubit.restore()` paints it first. Offline it stays signed in with `isVerified = false` |
| `account.addresses.v2` | Address book | Painted first, then synced. Wiped on sign-out |
| `jameia.search.recents.v1` | Recent search terms | |
| `jameia.home.popup_shown.*`, `assistant.nudge.v1`, `app_language` | Small local flags | |

- In-memory TTL caches only (lost on restart): categories and offers (5 min per language) in
  `core/data/datasources/catalog_remote_data_source.dart`, checkout branches (5 min), checkout rail
  (2 min), and `/v1/init` memoized separately by **four** datasources (home, loyalty, assistant, checkout).
- Images: `core/widgets/hero_image_cache_manager.dart` keeps a 365-day disk cache (10 000 objects),
  so images seen before already work offline. `retryAllPendingImages()` (`core/widgets/hero_image.dart:72`)
  is documented as "wire into the reconnect path", but nothing calls it.

**Automatic retries today**
- Cart (5 → 80 s), SSE `connect` (1 → 30 s), 429s, images, and the order-tracking poll (30 s).
- `AssistantAvailabilityCubit`: 4 tries, then it stops for good.
- `UnreadNotificationsCubit.start()`: none, and it never retries.
- `LocalizationCubit.syncToServer`: none, and it never retries.

### App flow map (what the customer passes through)

```
main.dart ─ EasyLocalization.ensureInitialized → setupServiceLocator (offline catalogue from assets,
            SharedPreferences, session, Dio chain, 19 feature ICs) → runApp(HeroApp)
app.dart  ─ app-global cubits: Cart, Localization, Setting, AuthSession(..restore), UnreadNotifications,
            AddressBook, AssistantAvailability(..ensureLoaded)
          ─ session listeners: address book / cart owner / unread badge / expiry → login / language sync
          ─ MaterialApp.router(builder: text-scale clamp only)   ← the one place above every route
/  splash ─ animation only → context.go(/shell)
/shell    ─ MainShellPage: IndexedStack keyed by language (tabs recreated on a language switch)
            0 Home  (GET /v1/home + /v1/init)
            1 Search (discover = categories + brands; suggestions = GET /v1/products?search, 300 ms debounce)
            2 Cart | Orders (nested IndexedStack; history built lazily; refetch on tab activation)
            3 Mine  (profile, wallet, loyalty, Pro, settings, notifications, addresses, assistant)
            + assistant buddy overlay (Stack over the tab body, above the bottom nav)
pushed    ─ /categories /category /products /brands /offers /recipes /recipe /content-page /pro
            /product-detail /checkout /orders /order-tracking /order-review /order-invoice
            /notifications /wallet /loyalty /profile-edit /address-* /assistant /login /otp-verify …
            (coupons, discovery, support = offline catalogue only; no network)
```

### Offline behaviour today, feature by feature

| Feature / screen | Routes | Today when offline |
|---|---|---|
| Home | `/v1/home`, `/v1/init` | Cold start: full-screen `ErrorView`, nothing cached. Refresh fail: snack, data kept. Language switch: skeleton, then error |
| Search | catalogue | Silent: discover blocks and suggestions empty, recents shown, no explanation |
| Categories / listing / brands | `/v1/categories`, `/v1/products`, `/v1/brands` | Full `ErrorView`. `ProductListingCubit.load()` **always** emits loading, so retry or a language switch drops the data. `ListingTabsCubit` resets to empty tabs on failure |
| Product detail | `/v1/products/:slug`, reviews, offers | Full `ErrorView` **discards the preview card** the customer tapped. No pull-to-refresh |
| Recipes / Offers / CMS page / Pro | `/v1/recipes*`, `/v1/offers`, `/v1/pages/:slug`, subscription routes | Full `ErrorView` on first load. CMS reload failure is silent |
| Cart | cart routes (`no-store`) | Offline-first queue works. **But** `CartView` snacks every failed retry (5 → 80 s), and the Cart tab stays mounted, so an offline customer is spammed |
| Checkout | `/v1/init`, delivery, `POST /v1/orders` | Full error on branches failure. Place order is blocked only when the cart is unsynced |
| Orders / tracking | `/v1/orders*` | Error view on first load. Tracking poll fails silently every 30 s (wasted requests) |
| Notifications / wallet / loyalty | customer routes | Error view on first load. Refresh fail: snack |
| Account / addresses / auth | profile, addresses | Saved copies painted. Sync failures kept quietly. Unverified session never re-verified until the next launch |
| Assistant | `/v1/init`, SSE `POST` | Availability stays `unknown` after 4 tries, so the entry points disappear for the whole run. Send fails with a failed bubble + retry (good) |
| Coupons / discovery / support | offline catalogue | Unaffected |

### This task delivers

1. **Connection awareness** (core + a new `features/connectivity`). Reachability of *our* backend,
   an app-global `ConnectivityCubit`, and a `ConnectivityScope` that core widgets can read.
2. **A global connection banner** above every route: offline → reconnecting → back online.
3. **An on-device response cache** (core `JsonCacheStore`) plus **one cache-then-network policy**
   (`CachedRepositoryMixin`). Every read-only API screen in the table below shows its last data offline.
4. **An offline-first screen contract** applied to every API-backed cubit and page listed under
   BEHAVIOR §D.
5. **Friendly offline handling of mutations and automatic recovery on reconnect**: the app root
   plus every screen, with no snack spam.
6. Tests, device verification, docs, and the review gates (performance + clean code are mandatory).

### Read before writing (CLAUDE.md §0.1)

- `CLAUDE.md`. It wins over this prompt when they disagree. Also `docs/api_integration.md`.
- Skills: `hero-api-integration` (+ `references/patterns.md`, `layer-templates.md`,
  `backend-contract.md`), `hero-api-session`, `hero-api-streaming`, `hero-api-testing`,
  `hero-api-verify`.
- Reference features to mirror:
  - `features/address` + `address_local_data_source.dart`: device copy painted first, then sync,
    owner check, wipe on sign-out. This is the closest existing pattern to what every cached
    screen will do.
  - `features/cart/data/repositories/cart_repository_impl.dart`: offline queue, generation guard,
    retryable-error classification.
  - `features/notifications`: paginated feed, generation counter, transient `Failure` in state.
  - `features/home/presentation/cubit/home_cubit.dart`: keeps the old feed on a refresh failure.
- `core/motion/*` (`SizeFadeSwitcher`, `CollapseReveal`, `TintFlash`, `ShakeX`, `BlockedTapShake`,
  `RotatingLine`, `Haptics`, `MotionGuard`, `SecondClockScope`) and `core/widgets/*`
  (`HeroStateView`, `StateIconPlate`, `ErrorView`, `BrandedRefresh`, skeletons) before writing
  any widget.
- The two review agents that gate this work, **before you design**, because their checklists are
  design constraints here:
  - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-performance-reviewer.md`
  - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-clean-code-reviewer.md`

### Working constraints

- **Do not touch** `pubspec.yaml`, `pubspec.lock`, `android/**` or `ios/**`. Everything needed is
  already a dependency: `internet_connection_checker_plus`, `path_provider` (`getApplicationCacheDirectory`),
  `dio`, `shared_preferences`, `flutter_bloc`, `easy_localization`.
- The working tree already has uncommitted work from other sessions (splash, launcher icon,
  i18n, backend-contract). Run `git status` first. Edit only the files this task needs. Merge
  into `assets/i18n/*.json` carefully and never reformat or reorder those files. Never commit,
  stash, reset or checkout.
- Deliver in the phases under BUILD ORDER. Each phase ends with `dart analyze` and `flutter test` green.

---

## FIGMA

None. Build from the existing design system only: `AppColors`, `HeroColors`, `AppSpacing`,
`AppSize`, `AppRadius`, `AppTextStyles`, `AppShadows`, `AppMotion`, and the `core/motion` kit.
Tone: calm, reassuring, never alarming. Offline is a **neutral** state (dark neutral surface), not
an error (no red). "Back online" uses the brand green `primary`. Illustrations reuse `StateIconPlate`
(or the painted Hero mark if it reads better), never new raster assets. Add at most two colour
tokens if nothing fits (e.g. `offlineSurface`, `onOfflineSurface`) in both `AppColors` and
`HeroColors`, and say why in the report.

---

## API SPEC

No new routes and no new `EndPoints`. Facts observed live against `https://api.jm3eia.store` on
2026-09-27:

- **Cache headers.** Every public catalogue route answers `cache-control: public, max-age=60,
  stale-while-revalidate=300`: `/v1/home`, `/v1/init`, `/v1/categories`, `/v1/products`,
  `/v1/brands`, `/v1/offers`, `/v1/recipes`. `/v1/cart` answers `cache-control: no-store`. No route
  sends `ETag` or `Last-Modified`, so there is no conditional GET: revalidation is a full re-fetch.
- **Language is not in `Vary`.** Only `vary: Origin` is sent, yet names are resolved by
  `Accept-Language`. **Every cache key must include the language.**
- **Personalisation.** `/v1/home` and `/v1/init` are "Bearer optional → personalised". `/v1/init`
  carries `user|null`, wishlist ids and delivery (branch / zone for the customer or the guest cart
  token). Scope them per owner, not as public.
- **Cheap reachability probe.** `HEAD https://api.jm3eia.store/` answers `404` with 0 bytes in about
  0.34 s. **Any HTTP status means our backend is reachable.** Use it (built from `AppEnv.apiBaseUrl`)
  as a custom check option with a `responseStatusFn` that accepts any status. Add **one** neutral
  fallback (`https://one.one.one.one`) so a backend outage never reads as "you're offline".
- **Rate limit.** 300 requests per 60 s (`x-ratelimit-limit: 300`, `x-ratelimit-reset: 60`). The
  probe cadence and the reconnect fan-out below must stay far under it.
- Money, envelopes and codes are unchanged (CLAUDE.md §3.1). The cache stores the envelope's
  **`results`** exactly as the server sent it.

### What gets cached

Only read routes. The first page only for paginated lists. Keys include the language and the owner.

| Namespace | Route | Owner scope | Fresh TTL (skip network on open) | Max age (never shown after) |
|---|---|---|---|---|
| `home.feed` | `GET /v1/home` | owner | 60 s | 7 d |
| `home.init` | `GET /v1/init` (home bootstrap) | owner | 60 s | 7 d |
| `catalog.categories` | `GET /v1/categories` | public | 5 min (matches the existing memory TTL) | 7 d |
| `catalog.brands` | `GET /v1/brands` (page 1, limit 100) | public | 60 s | 7 d |
| `catalog.products` | `GET /v1/products`, **page 1 per normalised query** | public | 60 s | 3 d; cap about 40 queries |
| `catalog.offers` | `GET /v1/offers` (catalogue + marketing share one key) | public | 60 s | 1 d |
| `product.detail` | `GET /v1/products/:slug` | public | 60 s | 3 d; cap about 60 products |
| `product.reviews` | page 1 | public | 5 min | 7 d |
| `recipes.list` / `recipes.detail` | `/v1/recipes`, `/v1/recipes/:slug` | public | 60 s | 7 d |
| `marketing.page` | `GET /v1/pages/:slug` | public | 1 h | 30 d |
| `pro.program` | subscription plans | public | 5 min | 7 d |
| `pro.subscription` | `GET` account subscription | customer | 60 s | 7 d |
| `orders.list` | `GET /v1/orders` page 1 | customer | 30 s | 30 d |
| `orders.detail` | `GET /v1/orders/:id` | customer | 0 (always revalidate) | 30 d |
| `notifications.page` | page 1 (all / unread = two keys) | customer | 30 s | 14 d |
| `account.wallet` / `account.loyalty` | ledger page 1 | customer | 60 s | 14 d |
| `assistant.history` | conversations page 1 | customer or guest | 60 s | 14 d |

**Never cached** (say so in code comments where a reader might expect a cache):
- The cart (it has its own mirror, and the server sends `no-store`).
- Profile and addresses (they already have device copies).
- Checkout delivery slots / branches / store rules and `POST` anything (time- and money-sensitive).
- Search suggestions (typed live).
- Auth / OTP, SSE frames, and the assistant chat stream.

---

## BEHAVIOR

### A. Connection states

- `ConnectivityStatus { unknown, online, offline }`. At launch the status is `unknown` until the
  first check. **`unknown` never shows the banner.**
- **Going offline is debounced.** Show offline only after the monitor reports it continuously for
  about 1.5 s, so a Wi-Fi ↔ mobile handover never flickers the banner.
- **Coming back is instant**, on the first success from either:
  - the probe, or
  - any HTTP response from our API. The Dio chain reports it: a response proves reachability
    without waiting for the next poll.
- **A transport failure asks for an immediate re-check.** A Dio `connectionError` or timeout
  triggers an immediate check through the package's `triggerStream`. It never flips the status by itself.
- **Poll cadence:**
  - `AppConstants.connectivityPoll` (3 s) **while offline**, for fast recovery.
  - About 30 s while online (new named constant).
  - **Zero probes while the app is in the background.** Pause on `paused` / `hidden`. On
    `resumed`, resume and check at once.
- `reconnectEpoch` (an int in the state) increments on every `offline → online` transition.
  Screens and the app root react to that number, never to raw status flips.
- **Server trouble is not offline.** A 5xx, a timeout while the probe says online, or a 429 keeps
  today's error UI (`TimeoutFailure` → `core.request_timeout`, etc.). The banner reflects
  reachability only.

### B. Global connection banner

- **Placement.** One host in `MaterialApp.router(builder:)`, so it is above every route: pushed
  pages, sheets and dialogs included. It is **never over the splash**; the first appearance comes
  after the splash hands over to the shell.
- **Layout.** A slim bar at the top that extends under the status bar and **pushes** content down
  (no overlap). Remove the top padding from the child `MediaQuery` while the bar is visible, so
  page `SafeArea`s do not double-pad. Set status-bar icon brightness through an `AnnotatedRegion`
  while it shows.
- **States:**
  1. **Offline:** neutral dark surface, `wifi_off_rounded` icon, `connectivity.offline_title` +
     `connectivity.offline_subtitle`. **Tap = check now**, with a light haptic and a "Reconnecting…"
     state with a small rotating mark while the check runs.
  2. **Back online:** the surface morphs to brand green (`TintFlash`), `connectivity.back_online`
     with a check icon. It holds for about 2 s, then collapses (`CollapseReveal` / `SizeFadeSwitcher`).
  3. **Nudge:** when the customer tries a network action while offline (pull-to-refresh, a submit,
     load-more), the banner does one `ShakeX` + a light haptic instead of a snack bar.
- **Accessibility and adaptation:**
  - `Semantics(liveRegion: true)` announces "You're offline" / "Back online" once per transition.
  - It works at the 1.3× text-scale clamp (wrap, then ellipsis) and in RTL (directional padding,
    icon on the start side).
  - Reduced motion: an instant swap, no shake, no colour morph.

### C. Offline-first screen contract (every cached screen follows this exactly)

1. **Open.**
   - Cache hit younger than max age: render it at once with no skeleton (`status` loaded,
     `isStale = true`, `snapshotAt = savedAt`).
   - Hit younger than the fresh TTL: **no network call** (pull-to-refresh still forces one).
   - Otherwise revalidate in the background.
   - Miss: the skeleton as today.
2. **Network OK.**
   - Replace the data, set `isStale = false` and `snapshotAt = now`, and write the cache (fire and forget).
   - If the new data equals the cached data (Equatable), emit only the freshness change: no list
     rebuild, no flicker.
3. **Network fails with data on screen.** Keep the data and keep `isStale = true`.
   - Offline: **no snack bar** (the banner covers it). The stale note shows.
   - Online (server error, timeout): today's snack + the stale note.
4. **Network fails with no data.**
   - `NetworkFailure`: the friendly offline state (`HeroStateView.offline`), with auto-retry on
     reconnect and a manual "Try again".
   - Other failures: today's error view.
   - `UnauthorizedFailure`: today's sign-in view (`context.go(Routes.login)`).
5. **Reconnect** (`reconnectEpoch` changed). If `isStale || status == error`, run one silent
   refresh (no skeleton), otherwise do nothing.
6. **Ordering guard.** A cache snapshot **never** replaces a network snapshot. If the network
   answers before the disk read, drop the cache emission. The existing generation counters stay,
   and a refresh cancels the previous load's subscription.
7. **Language switch.** The key includes the language, so a language visited before paints instantly.
8. **Pagination.**
   - Only page 1 comes from the cache.
   - `loadMore` needs the network. Offline, the footer says `connectivity.load_more_offline` and
     retries by itself on reconnect.
   - A refresh overwrites page 1 in the cache. Later pages are never written.
9. **Unparseable cached payload** (schema changed, corrupt file): treat it as a miss, delete the
   entry and log it once. The screen never crashes and never shows a parsing error because of the cache.

### D. Per-screen behaviour

| Screen | Target behaviour |
|---|---|
| **Home** (tab 0) | Owner-scoped cache for feed + init. Cold start offline with a cache: full home + stale note, no error. Without a cache: `HeroStateView.offline` inside the real header. Popups are never shown from a cached bootstrap (they are time-boxed) |
| **Search** (tab 1) | Discover blocks from the cached categories / brands. Typing offline: show recents + `connectivity.search_offline`. No spinner and no silent empty list. Results page = the listing rules below |
| **Categories / category / listing / brands** | Cache per rule C. **Fix `ProductListingCubit.load()`** so it never drops loaded data (loading only when empty). `ListingTabsCubit` keeps the previous tabs on failure. Filter / sort changes offline: cached page 1 for that query if present, otherwise the offline state inside the listing |
| **Product detail** | Cache per slug. **Never discard the preview**: on failure with no detail, keep the preview card + an inline offline notice + auto-retry on reconnect. Stale price / stock: show the stale note. Add-to-cart stays allowed (the cart syncs, and the server is the authority) |
| **Recipes / recipe / offers / CMS page / Pro** | Cache per rule C. Expired offers stay hidden (`GetOffersUseCase` already filters `isLiveAt(now)`). The CMS reload failure is no longer silent: stale note |
| **Cart** (tab 2) | No new cache. **Stop the snack spam**: transport failures while offline show nothing (the banner + `cart_sync_banner` already speak). Keep `cart.unsynced` and `cart.block_offline`. On reconnect the pending deltas flush immediately (reset the backoff) |
| **Checkout** | Needs the network. Opened offline with no data: offline state. **Place order**: when offline, the bar shows an inline offline hint; the tap runs a live check first (`ConnectivityCubit.checkNow()`), proceeds if online, otherwise nudges the banner and shows `connectivity.action_needs_internet`. **Never queue or auto-replay an order** |
| **Orders / tracking / invoice / review** | Orders page 1 + order detail cached per customer. Tracking offline: last known status with `connectivity.order_status_as_of` (time), never presented as live. **Skip scheduled polls while offline** and poll once immediately on reconnect |
| **Notifications / wallet / loyalty** | Page 1 cached per customer. Mark-read offline: optimistic, then rolled back silently on `NetworkFailure` + banner nudge (no snack) |
| **Account / addresses / auth** | Existing device copies unchanged. On reconnect: re-verify an unverified session, sync an unsynced address book, retry the account-language sync |
| **Assistant** | Availability: on reconnect, retry if still `unknown` (restart its ladder) so the entry points come back. Composer offline: stays enabled; a send that fails keeps the draft as a failed bubble (today's behaviour) without an extra snack. History page 1 cached. **Never auto-resend a message** |
| **Images** | On reconnect, call `retryAllPendingImages()` once |

### E. Mutations while offline

- **No queue** except the cart's existing quantity deltas. **No automatic replay** of any mutation
  on reconnect (orders, payments, reviews, profile, addresses, Pro, assistant, coupons, loyalty, express).
- Submit buttons stay enabled (the probe can be wrong). The request is attempted. A real no-network
  fails fast (DNS / socket error, not the 20 s timeout).
- On `NetworkFailure`:
  - Keep every draft and every form value.
  - Show `connectivity.action_needs_internet`: inline where the screen has an inline error slot,
    otherwise through the new `showFailureSnackBar`, which shows it once and nudges the banner.
- Optimistic mutations (mark-read, make-default address, assistant thumbs, cart clear) roll back
  exactly as today. Only the message changes.

### F. Automatic recovery on reconnect

- **App root (`app.dart`).** One new `BlocListener<ConnectivityCubit>` with `listenWhen` =
  `reconnectEpoch` changed. It calls (each a no-op when nothing is pending):
  - `CartCubit`: flush pending / refetch when unsynced;
  - `AuthSessionCubit`: re-verify when `isSignedIn && !isVerified`;
  - `AddressBookCubit`: sync when signed in and not synced;
  - `UnreadNotificationsCubit`: re-probe when signed in;
  - `AssistantAvailabilityCubit`: retry when `unknown`;
  - the existing `_syncAccountLanguage(context)`;
  - `retryAllPendingImages()`.
  Add one small public method per cubit where it is missing (`onReconnected()`), with tests.
- **Screens.** A core `ReconnectRefresh` widget wraps each cached page body and calls the page
  cubit's `onReconnected()`.
  - Jitter each screen by 0–600 ms. Allow at most one request per screen per reconnect
    (single-flight in the cubit).
  - Offstage `IndexedStack` tabs are allowed to refresh, but only when stale.

### G. Cold start offline

The splash plays as today, then the shell opens.
- The banner appears after the splash once offline is confirmed.
- Home paints its owner-scoped cache or the offline state.
- The saved profile and address book paint as today.
- The cart mirror restores.
- The assistant entry points come back on reconnect.

The app must never show a full-screen generic error anywhere offline when a cache exists.

### H. Privacy and ownership

- Owner scope = `public`, `guest`, or the customer id. Customer-scoped entries are **wiped on
  sign-out and on session expiry**. Put this in the same place the profile snapshot is forgotten
  (`AuthSessionCubit` `_forget` → auth local datasource → cache store `removeOwnedEntries()`).
- A cache write that finishes after the owner changed is dropped. Capture the owner when the
  request starts and compare it before writing.
- Tokens, OTPs and request headers are never written to the cache. Cache logs contain only the
  namespace, key hash and byte size, never payloads.

### I. Edge cases to handle (each gets a test or a verification step)

1. The network flaps every second: debounced, no flicker, at most one reconnect fan-out per real recovery.
2. A captive portal or Wi-Fi without internet: the probe on our host fails, so the app is offline even though the OS says Wi-Fi.
3. The backend is down but the internet works: the fallback probe keeps the app "online", and screens show today's server error, not the offline UI.
4. A VPN or proxy that blocks Cloudflare but allows our API: the API probe succeeds, so the app is online.
5. The customer switches language while offline: the other language's cache or the offline state, never a crash or a mixed language.
6. The device clock moves backwards (`savedAt` in the future): treat the entry as stale, never "fresh forever".
7. The disk is full or a write fails: log it, keep the in-memory data, no user-facing error.
8. An app upgrade changes a DTO: bump that namespace's schema version, so old entries become misses.
9. The same key is written from two screens: the last write wins, and a write is atomic (temp file, then rename).
10. Sign-out while a write is in flight: dropped (§H).
11. The assistant stream breaks mid-reply while offline: the partial reply is kept (today), with no extra snack.
12. The app goes to the background while offline for 10 minutes: zero probes during that time, then one check on resume.

---

## REQUIREMENTS

### 1. Core: reachability (data infrastructure)

- **Extend `NetworkInfo`** (`core/network/network_info.dart`) and keep the class name:
  - a status stream;
  - the last known status (synchronous);
  - `checkNow()`;
  - `reportReachable()` / `reportTransportFailure()` (fed by the interceptor below);
  - `pause()` / `resume()`;
  - poll-interval switching.
  Build it on `InternetConnection.createInstance` with the probe list from API SPEC,
  `triggerStream`, and `setIntervalAndResetTimer`. Keep it testable through `customConnectivityCheck`.
- **New `ReachabilitySignalInterceptor`** (`core/network/interceptors/`). A response of any status
  → `reportReachable()`. `connectionError` / timeouts → `reportTransportFailure()`. Register it in
  `service_locator.dart` **after** `RateLimitRetryInterceptor` and before the debug trace, and
  document the new order in the comment there and in CLAUDE.md §3.1. The bare refresh client does not need it.

### 2. New feature `features/connectivity` (Clean Architecture, like `features/language`)

- `data/datasources/connectivity_data_source.dart`: wraps `NetworkInfo`, no `Either`.
- `data/repositories/connectivity_repository_impl.dart`: `with BaseRepositoryMixin`, streams
  through `guardStream`.
- `domain/entities/connectivity_status.dart`.
- `domain/repositories/connectivity_repository.dart`.
- `domain/usecases/`: `watch_connectivity_usecase.dart` (`StreamUseCase`),
  `check_connectivity_usecase.dart`, `set_connectivity_monitoring_usecase.dart` (pause / resume).
- `presentation/cubit/connectivity_cubit.dart` + `connectivity_state.dart`, holding:
  - `status`
  - `reconnectEpoch`
  - `isChecking`
  - `showBackOnline` (the 2 s confirmation)
  - `lastChangedAt`

  Use `SafeCubitMixin` and emit on distinct changes only. It is a **new app-global cubit**:
  provided in `app.dart`, created through `AppGlobalCubits.connectivity()`, `start()`ed there.
- `presentation/widgets/`: the banner host (lifecycle pause / resume through
  `AppLifecycleListener`, provides `ConnectivityScope`) and the banner pieces, **one widget per file**.
- `connectivity_injection_container.dart` → `initConnectivityFeature()`, called from `_initFeatures()`.

### 3. Core: presentation helpers (no feature imports in core)

- `core/widgets/connectivity_scope.dart`: an `InheritedWidget` carrying `isOffline` and
  `reconnectEpoch`, plus a `nudge` callback. The banner host fills it from `ConnectivityCubit`.
  `updateShouldNotify` fires only when those values change. It gives core widgets and every page
  offline awareness without cross-feature imports, and tests can pump it directly.
- `core/widgets/reconnect_refresh.dart`: calls `onReconnected` when the scope's epoch changes, with jitter.
- `core/widgets/stale_data_notice.dart`: a small pill with a clock icon and the relative age. It
  ticks at most once per minute through the existing clock scope, never per second.
- `HeroStateView.offline({onRetry})`: a new named constructor that reuses `StateIconPlate`
  (`wifi_off_rounded`), `connectivity.offline_state_title` / `_message`, and "Try again".
- `core/navigation/hero_snack_bar.dart`: add `showFailureSnackBar(context, failure)`. It
  suppresses `NetworkFailure` / `TimeoutFailure` while `ConnectivityScope` says offline (and
  nudges the banner instead); otherwise it shows `failure.localizedMessage`. **Every page listener
  that snacks `failure.localizedMessage` moves to it**. Find them with
  `grep -rn "localizedMessage" lib/src/features --include=*.dart`.
- A relative-age formatter in `core/utils/formatters.dart` (or `core/utils/relative_age.dart`),
  based on i18n plurals, never hand-built strings.

### 4. Core: the cache

- `core/storage/json_cache_store.dart`: `abstract class JsonCacheStore` + a file-backed
  implementation. Local datasources use it; nothing else does.
  - **Location.** `getApplicationCacheDirectory()/api_cache/`, resolved lazily on first use.
    Startup (`runApp`) must never wait for it.
  - **Storage backend.** Not SharedPreferences for payloads: prefs are loaded fully into memory at
    launch. SharedPreferences stays for small flags.
  - **Record format.** One file per key: `{ v (global cache version), ns, nsv (namespace schema
    version), key (full key, verified on read), savedAt (UTC ms), lang, owner, data (raw results) }`.
    File name = namespace directory + a stable 64-bit FNV-1a hash of the full key (write it locally;
    no new dependency). A hash collision reads as a miss because the stored key does not match.
  - **Atomic writes** (temp file, then rename). JSON decoding runs off the UI isolate
    (`Isolate.run`) for files over about 64 KB.
  - **Limits.** About 12 MB total. An entry over 1 MB is skipped. Per-namespace entry caps come
    from the API SPEC table. Evict the oldest first.
  - **Failures.** Corrupt or unreadable → delete + miss. Every I/O error is logged with `log()`
    and never thrown to the UI; it surfaces as `CacheException` only where a datasource contract
    requires it.
  - **API.** Read, write, remove, `removeOwnedEntries()` (everything not `public` / `guest`), clear.
- `core/domain/entities/data_snapshot.dart`: `DataSnapshot<T>` (`data`, `fetchedAt`,
  `origin: network | cache`), Equatable, pure Dart.
- `core/data/models/remote_payload.dart`: `RemotePayload<M>` = the DTO **plus the raw `results`
  map it was parsed from**. Remote datasources of cached routes return it. **This is why no
  `toJson` is needed.**
  - The inventory found about 25 catalogue / feature DTOs that are `fromJson`-only (home ×10,
    product details ×5, recipes ×4, store mode ×3, core Brand / Category / Offer / ProductsPage /
    RecipeSummary).
  - The cache stores the server's own JSON, and the local datasource re-parses it with the **same**
    `fromJson`. That gives perfect fidelity, no serializers to maintain, and no round-trip drift.
  - Do not add `toJson` to those DTOs.
- `core/data/repositories/cached_repository_mixin.dart`: `mixin CachedRepositoryMixin on
  BaseRepositoryMixin` with **one** cache-then-network method. It takes a cache read, a network
  fetch, a cache write, the DTO → entity mapping, the namespace policy (fresh TTL, max age) and
  `forceRefresh`. It returns a `Stream<DataSnapshot<E>>` with `Failure`s on the error channel (the
  `guardStream` convention). It must implement rules C.1, C.2, C.6 and C.9 once and be tested
  once, exhaustively. It also owns the owner-changed write drop from §H.
- `core/utils/performance/snapshot_loader_mixin.dart`: a small cubit mixin (next to
  `SafeCubitMixin`) that owns the snapshot subscription, the generation guard, cancel in `close()`
  and single-flight `onReconnected()`. **Write the cubit flow once.** If a second cubit copies it,
  that is a clean-code finding.

### 5. Per feature (data → domain → presentation, bottom-up)

For every row in the "What gets cached" table:

1. **Datasources.**
   - The remote datasource method returns `RemotePayload<XModel>`.
   - Add a local cache datasource (`x_cache_data_source.dart`, abstract + Impl, depends on
     `JsonCacheStore` + `LocaleProvider` for the language) that reads / writes the raw map and
     parses with `XModel.fromJson`.
   - Shared catalogue reads get one core cache datasource
     (`core/data/datasources/catalog_cache_data_source.dart`) beside `CatalogRemoteDataSource`.
2. **Repository.** The contract gains a `watchX(params, {forceRefresh})` returning
   `Stream<DataSnapshot<Entity>>`. The impl uses `CachedRepositoryMixin`. Existing `Future`
   methods stay where other callers need them.
3. **Use case.** `Watch<Noun>UseCase implements StreamUseCase<DataSnapshot<T>, Params>`, one per
   operation, with Params in the same file.
4. **State.** Add `isStale` + `snapshotAt` (and keep the transient `Failure? failure`). A state you
   touch that still has `String? error` moves to `Failure?` (CLAUDE.md §5).
5. **Cubit.** Implement contract C through `SnapshotLoaderMixin`, plus `onReconnected()`.
6. **Page.** Wrap the body in `ReconnectRefresh`. Show `StaleDataNotice` when
   `isStale && (offline || failure != null)`. Use `HeroStateView.offline` for the no-data
   `NetworkFailure` case. Snack bars go through `showFailureSnackBar`.
7. **DI.** Register the new datasource, use case and repository changes in the feature IC.

### 6. i18n (both files, same keys; suggested copy; keep it this warm and short)

| Key | EN | AR |
|---|---|---|
| `connectivity.offline_title` | You're offline | أنت غير متصل بالإنترنت |
| `connectivity.offline_subtitle` | Showing what you last saw | نعرض لك آخر ما تصفّحته |
| `connectivity.reconnecting` | Reconnecting… | جارٍ إعادة الاتصال… |
| `connectivity.back_online` | Back online | عاد الاتصال |
| `connectivity.tap_to_retry` (semantics hint) | Tap to check again | اضغط للتحقق مجدداً |
| `connectivity.offline_state_title` | No connection | لا يوجد اتصال |
| `connectivity.offline_state_message` | Check your Wi-Fi or mobile data. This page loads as soon as you're back online. | تحقّق من شبكة Wi-Fi أو بيانات الجوال. ستظهر الصفحة فور عودة الاتصال. |
| `connectivity.action_needs_internet` | You're offline. Your changes are kept, try again when you're back. | أنت غير متصل. احتفظنا بتعديلاتك، حاول مجدداً عند عودة الاتصال. |
| `connectivity.search_offline` | Search needs a connection. Here are your recent searches. | البحث يحتاج إلى اتصال. إليك عمليات بحثك الأخيرة. |
| `connectivity.load_more_offline` | You're offline. More will load when you're back. | أنت غير متصل. سيتم تحميل المزيد عند عودة الاتصال. |
| `connectivity.order_status_as_of` | Last known status · {time} | آخر حالة معروفة · {time} |
| `connectivity.updated_just_now` | Updated just now | تم التحديث للتو |
| `connectivity.updated_minutes` (plural) | Updated {} min ago | one: آخر تحديث قبل دقيقة · two: قبل دقيقتين · few: قبل {} دقائق · many/other: قبل {} دقيقة |
| `connectivity.updated_hours` (plural) | Updated {} h ago | one: قبل ساعة · two: قبل ساعتين · few: قبل {} ساعات · many/other: قبل {} ساعة |
| `connectivity.updated_days` (plural) | Updated {} d ago | one: قبل يوم · two: قبل يومين · few: قبل {} أيام · many: قبل {} يوماً · other: قبل {} يوم |

Use easy_localization `plural()` with all six Arabic forms (zero / one / two / few / many / other).
Check the Arabic on a device.

### 7. Tests (recipe: `hero-api-testing`; no test touches the network or real disk outside a temp dir)

- **Test isolation.** Add `FakeNetworkInfo` (a controllable stream + last status) to
  `test/core/network/network_test_fakes.dart`, and an in-memory `JsonCacheStore` fake.
  - Every test that runs `setupServiceLocator()` (9 files today) must register `FakeNetworkInfo`,
    so the real checker never probes the internet from a test.
  - Every widget test that provides the app-global cubits also provides `ConnectivityCubit` (or
    pumps `ConnectivityScope`).
- **`NetworkInfoImpl`** (through `customConnectivityCheck`):
  - probe any-status = reachable;
  - fallback;
  - interval switching;
  - pause / resume;
  - trigger on transport failure.
- **`ReachabilitySignalInterceptor`** on `FakeHttpClientAdapter`: 200 / 404 / 500 → reachable;
  connection error / timeout → failure report.
- **`ConnectivityCubit`** (bloc_test, fake clock):
  - `unknown` never shows;
  - 1.5 s debounce;
  - instant recovery;
  - `reconnectEpoch` increments once per recovery;
  - back-online auto-hide;
  - distinct emits only;
  - `checkNow` sets `isChecking`.
- **`JsonCacheStore`** (temp dir):
  - round trip;
  - global / namespace version mismatch → miss;
  - corrupt file → miss + deleted;
  - key collision → miss;
  - size cap eviction;
  - over-1 MB entry skipped;
  - `removeOwnedEntries`;
  - atomic write (no partial file visible);
  - future `savedAt` → stale.
- **`CachedRepositoryMixin`**, every branch:
  - fresh hit → no fetch;
  - stale hit → cache then network;
  - stale hit + failure → cache then failure;
  - miss + failure;
  - `forceRefresh`;
  - network before cache → cache dropped;
  - bad cached payload → miss;
  - owner changed → write dropped.
- **Per feature:**
  - the cache datasource parses a saved fixture of a real `results` payload;
  - repository wiring;
  - cubit contract C (open with a cache, network OK / failure with data / failure without data,
    reconnect refresh single-flight, equal data → only a freshness emit, pagination footer offline).
- **`showFailureSnackBar`** suppression. `ReconnectRefresh` fires once per epoch. `StaleDataNotice`
  ticks per minute.
- **Widget tests for the banner:** offline / reconnecting / back-online, RTL, Arabic, 1.3× text,
  reduced motion (`MediaQuery(disableAnimations: true)` → no running ticker), liveRegion semantics.
- **Regression tests for the fixed bugs:**
  - `ProductListingCubit.load()` keeps data;
  - the PDP keeps the preview on failure;
  - the cart does not snack while offline;
  - the tracking poll is skipped while offline;
  - the assistant availability retries on reconnect;
  - unread notifications re-probe on reconnect.

### 8. Docs (part of done)

- **CLAUDE.md:**
  - §1: add `connectivity` to the feature list and `json_cache_store` to `core/storage`.
  - §3 table: two new rows, "Connectivity" (`ConnectivityCubit` / `ConnectivityScope`; never a raw
    checker in a feature) and "Offline cache" (`JsonCacheStore` through a cache datasource +
    `CachedRepositoryMixin`; never SharedPreferences for payloads).
  - §3.1: the interceptor order.
  - §3.2 "Behaviors every API screen has": add stale-while-offline + reconnect refresh.
  - §4: the `ConnectivityCubit` app-global entry; local datasources may depend on `JsonCacheStore`.
  - §8: the new fakes.
- `docs/api_integration.md`: a new "Offline & caching" section (policy table, key anatomy, wipe
  rules, observed cache headers).
- **Skills:**
  - `hero-api-integration/references/patterns.md`: the cache-then-network pattern and the
    screen contract.
  - `references/backend-contract.md`: the cache-header facts from API SPEC.
  - `hero-api-testing`: the fakes.
  - `hero-api-verify`: the offline device checklist below.

---

## UI GUIDELINES

- **Tokens only.** Durations and curves come from `AppMotion`. Spacing, sizes, radii and type come
  from `AppSpacing` / `AppSize` / `AppTextStyles`. A one-off value becomes a named `static const`.
  No `// ignore`.
- **One widget per file**, including private ones. No `Widget _buildX()`. Banner pieces: host, bar,
  icon slot, label block, back-online variant. Each file stays under about 120–150 lines.
- **Reuse before you create.**
  - `HeroStateView` (the new `.offline`), `StateIconPlate`, `BrandedRefresh`, and the existing
    skeletons.
  - The existing `ListingLoadMoreFooter` / load-more rows get an offline variant; do not build new
    footers.
  - The stale note is one core widget used everywhere.
- **Motion** (all through `MotionGuard`; nothing animates with reduced motion; nothing re-animates
  on rebuild or scroll):

| Moment | Building block | Notes |
|---|---|---|
| Banner enters / leaves | `CollapseReveal` or `SizeFadeSwitcher` | Height + fade. Content below slides once, no bounce |
| Offline → back online | `TintFlash` colour morph + icon `PopSwitcher` | About 2 s hold, then collapse |
| Reconnecting | `RotatingLine` (or the branded dot loader) in the icon slot | Only while `isChecking` |
| Network action while offline | `ShakeX` on the banner + `Haptics` light | Once per attempt, never looped |
| Stale note appears | fade in only | Never on every refresh |
| Offline state view | `PopScale.onMount` on the icon plate (as `ErrorView` does) | |

- **RTL.** `EdgeInsetsDirectional` / `AlignmentDirectional`, the icon on the start side, and the
  shake axis mirrored if it is directional.
- **Accessibility.** Semantics labels on the banner + the tap hint. The stale note reads as
  "Updated 12 minutes ago". Contrast of at least 4.5:1 on the offline surface.
- **Performance** (flutter-performance-reviewer checklist; each item is a hard requirement):
  - The banner host must **not rebuild the `Navigator` subtree** when the status changes. The
    router child is passed through untouched; only the bar rebuilds (`BlocSelector` on the fields
    it needs, and a `RepaintBoundary` around the bar).
  - `ConnectivityScope.updateShouldNotify` fires only on `isOffline` / `reconnectEpoch` changes.
    Dependents read a narrow accessor.
  - The cubit emits at most once per real transition (debounced, distinct).
  - A cache read is async. Cached first paint targets under 100 ms after the page opens on a
    mid-range device. Decoding over about 64 KB runs off the main isolate. A write never blocks an
    emit (fire and forget, errors logged).
  - Equal network data → a freshness-only emit. The list sections use `BlocSelector` / `buildWhen`,
    so they do not rebuild for a freshness change.
  - **No request storm on reconnect:** jitter, single-flight per cubit, only stale / error screens,
    at most one call per screen.
  - **No polling in the background.** The tracking poll is skipped while offline.
    `EventStreamClient` keeps its backoff (no change).
  - `StaleDataNotice` rebuilds once per minute, not per second, and only its own subtree.
  - No raw JSON kept in memory after the cache write.
- **Clean code** (flutter-clean-code-reviewer checklist):
  - SRP per class: reachability ≠ cache ≠ UI ≠ policy.
  - One policy implementation (the mixin), not one per repository.
  - Consistent naming (`watchX`, `XCacheDataSource`, `Watch<Noun>UseCase`, `onReconnected`).
  - `log()` only.
  - No hardcoded strings.
  - No duplicated offline widgets.
  - Comments only where the why is not obvious (probe choice, owner drop, ordering guard).

---

## ARCHITECTURE GUIDELINES

| Piece | Layer / folder | May depend on |
|---|---|---|
| `NetworkInfo`, `ReachabilitySignalInterceptor` | `core/network` | the checker package, Dio |
| `JsonCacheStore` | `core/storage` | `path_provider`, `dart:io`, `dart:isolate` |
| `DataSnapshot` | `core/domain/entities` | pure Dart, equatable |
| `RemotePayload`, `CachedRepositoryMixin`, `CatalogCacheDataSource` | `core/data` | core storage / error / domain |
| `ConnectivityScope`, `ReconnectRefresh`, `StaleDataNotice`, `HeroStateView.offline` | `core/widgets` | theme, motion, i18n. **No feature imports** |
| `showFailureSnackBar` | `core/navigation` | `core/widgets/connectivity_scope.dart`, `core/utils/failure_message.dart` |
| `SnapshotLoaderMixin` | `core/utils/performance` | bloc, `core/domain`, `core/error/failures.dart` |
| `features/connectivity/**` | its own data / domain / presentation | `core/network/network_info.dart` in data only |
| Feature cache datasources | `features/<f>/data/datasources` | `JsonCacheStore`, `LocaleProvider` |

- **Dependency direction is inward only.**
  - Cubits get `Watch…UseCase`s by constructor.
  - Other features read connectivity only through `ConnectivityScope` (core) or the app-global
    `ConnectivityCubit` (a cross-feature cubit import, allowed by the lint).
  - **Never** another feature's connectivity use case, and never `NetworkInfo` outside the data layer.
- **No pre-checks.** No screen asks "am I online?" before loading; it loads and follows contract C.
  The only live check is **place order**, and it is a confirmation, not a gate.
- `sl` only in DI / ICs / pages resolving cubits. App-global creation goes through `AppGlobalCubits`.
- `dart analyze` (repo root, **no path**) must show 0 new warnings, including `architecture_lints`.
  If a rule gives a false positive, fix the rule with a test; never ignore it.

---

## BUILD ORDER (phases; each ends green and reviewable on its own)

1. **Reachability.** `NetworkInfo` upgrade + interceptor + `features/connectivity` +
   `ConnectivityScope` + banner host in `app.dart` + i18n + tests. Verify the banner on an
   emulator in airplane mode.
2. **Cache core.** `JsonCacheStore`, `DataSnapshot`, `RemotePayload`, `CachedRepositoryMixin`,
   `SnapshotLoaderMixin`, `StaleDataNotice`, `HeroStateView.offline`, `ReconnectRefresh`,
   `showFailureSnackBar`, relative-age formatter + exhaustive tests.
3. **Home**, then the **Search discover** blocks (catalogue cache datasource). This is the
   cold-start-offline path, the highest-value screen.
4. **Catalogue browse:** categories, listing page 1 (+ the `load()` fix, listing tabs), brands,
   PDP (+ keep preview), reviews page 1, recipes, offers, CMS, Pro program.
5. **Customer:** orders list + detail (+ tracking poll pause), notifications, wallet / loyalty,
   Pro subscription, assistant history. Plus the sign-out / expiry wipe.
6. **Mutations and recovery:**
   - the app root reconnect listener (+ `onReconnected()` on the global cubits);
   - the `showFailureSnackBar` migration across all pages (the cart spam fix included);
   - the place-order confirmation;
   - assistant availability;
   - `retryAllPendingImages()`.
7. **Verification, docs, reviews** (below).

---

## VERIFICATION (device / emulator; `hero-api-verify` checklist + these)

**Tools**
- Airplane mode: `adb shell cmd connectivity airplane-mode enable` / `disable`, or
  `adb shell svc wifi disable` + `adb shell svc data disable`.
- Bad network: the emulator console `network delay gprs` / `network speed gsm`.
- Server failures without going offline: the bundled mock API
  (`.claude/skills/hero-api-verify/scripts/mock_api/server.js`) failure knobs (5xx, 429).
- Read the `api` trace through `.claude/skills/hero-api-verify/scripts/vm_log_tail.dart` or the
  DevTools Logging view. It is not in the `flutter run` terminal.

**Scenarios** (record the result of each in the report)
1. Cold start offline, first install: splash, then the home offline state, then the banner. Go
   online: back online, and home loads by itself.
2. Browse home, categories, a listing, 2 PDPs, recipes and orders online. Kill the app. Airplane
   on. Relaunch: every one of those screens paints from the cache with the stale note; nothing
   shows a generic error.
3. Offline on the listing: filter / sort to a cached and an uncached query; load-more footer offline; reconnect auto-loads.
4. Offline on a PDP never opened: the preview is kept, then the inline offline notice, then reconnect fills it in.
5. Add to cart offline (3 taps): no snack spam over 3 minutes on the Cart tab; reconnect syncs at once (trace shows the flush).
6. Checkout offline: the place-order hint; tap does a live check; no order sent; online → places normally.
7. Assistant offline: the send fails into a failed bubble, the draft is kept, no extra snack; reconnect brings the entry points back if they were hidden.
8. Mock API 500 while online: the normal error UI, **no offline banner**.
9. Wi-Fi with no internet (connect the emulator to a network with no upstream, if available) → offline.
10. Sign out: customer-scoped cache files are gone (`adb shell run-as <applicationId> ls -R cache/api_cache`, where `<applicationId>` comes from `android/app/build.gradle.kts`); public ones stay.
11. Arabic + RTL: banner, stale note plurals (1, 2, 3–10, 11+ minutes) and offline state read correctly.
12. Reduced motion on: no animation, instant swaps.
13. App in the background for 5 min while offline: the `api` trace and a network capture show no probe traffic; resume → one check.
14. DevTools performance overlay while toggling airplane mode on a long home feed: no jank frames, and the route subtree does not rebuild (widget rebuild stats).

---

## REVIEWS (gates; run in this order, fix every High / Medium, paste each verdict)

1. `F:\_jam3eia_apps\workflow\workflow\agents\flutter-performance-reviewer.md`. **Mandatory.**
   Its full output format (Issues Found / Severity / Recommendations / Optimized Version).
2. `F:\_jam3eia_apps\workflow\workflow\agents\flutter-clean-code-reviewer.md`. **Mandatory.**
   Its full output format (Issues Found / Refactored Example / Summary).
3. `flutter-architecture-auditor`, then `pre-pr-guardian` (CLAUDE.md §10).

Give each reviewer the diff scope of the phase just finished, not the whole codebase. Re-run a
reviewer after fixing its findings until nothing High remains.

---

## ACCEPTANCE CRITERIA

**Connection awareness**
- The banner shows after at most about 1.5 s of real disconnection and never for `unknown`.
- Back online shows instantly on the first probe success or API response, holds about 2 s, then hides.
- There are zero probes in the background.
- A backend 5xx never shows the offline banner.
- A captive portal shows offline.

**Last data offline**
- Every screen in the "What gets cached" table, once visited online, paints from the cache offline
  on the next launch with the stale note.
- No full-screen generic error appears offline anywhere a cache exists.
- The PDP never loses the tapped preview.
- `ProductListingCubit` never drops loaded data.

**Fresh data online**
- Within the fresh TTL, reopening a screen sends no request (trace).
- After the TTL, it paints the cache and revalidates once.
- Pull-to-refresh always fetches.

**Recovery**
- One reconnect produces at most one request per stale screen, plus the root hooks (trace, counted).
- Cart deltas flush immediately.
- The unverified session is re-verified.
- The assistant entry points return.
- Pending images retry.

**Mutations**
- Nothing except cart deltas is queued or replayed.
- Every failed offline submit keeps its draft and shows `connectivity.action_needs_internet` once.
- Place order runs a live check and never double-sends.

**Snack spam**
- No `core.no_internet` / `core.request_timeout` snack bar appears while the banner is showing (the cart included).

**Privacy**
- Customer-scoped cache is wiped on sign-out and expiry (verified on device).
- No token, OTP or header is in any cache file.

**Quality**
- `dart analyze` (repo root, no path): 0 errors / 0 warnings in touched files.
- `flutter test`: all green, with every test listed in REQUIREMENTS §7 present.
- No test hits the network.
- The performance + clean-code reviewers have no open High findings (verdicts pasted).
- The architecture auditor passes.

**Also**
- i18n keys exist in both files, Arabic is checked on a device, RTL and reduced motion work.
- Docs are updated (REQUIREMENTS §8).
- There are no changes to `pubspec.*`, `android/**` or `ios/**`, and no unrelated files are touched.

---

## OUT OF SCOPE (list in the report as follow-ups; do not build)

- Offline mutation queue beyond the cart (outbox with idempotency keys).
- Collapsing the four separate `/v1/init` fetches into one shared, cached bootstrap.
- Wiring the Settings "clear cache" tile (`SettingCubit` is built without use cases, so it is a
  no-op today). When it is wired, it should clear `JsonCacheStore` + the image cache.
- Caching assistant conversation transcripts, checkout data, or later list pages.
- Replacing the probe with `connectivity_plus` (a new dependency needs approval).
- Background sync / prefetch of unvisited screens.

---

## REPORT (CLAUDE.md §0.9 shape)

Summary · Files changed (per phase) · Verification (commands + results + the 14 device scenarios)
· Behavior preserved (why) · Behavior changes (the table in BEHAVIOR §D, confirmed) · Reviewer
verdicts · Risks / open issues (e.g. probe false positives, cache size on low-end devices) ·
Follow-ups (OUT OF SCOPE list + anything new found).
