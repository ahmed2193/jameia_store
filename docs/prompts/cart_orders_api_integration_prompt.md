# FEATURE NAME

Cart + Delivery + Orders on the jm3eia API — single-store cart with an offline-first local mirror

---

## CONTEXT

JameiaMart is ONE store (Jm3eia), but the cart, checkout and orders features still carry the
multi-shop model inherited from the Keeta clone (`shopId` on the cart and cart lines, a synthetic
`jameia` shop resolved through `resolveCheckoutShopId()`, checkout started with a `shopId`, shop
header/logo in checkout, "go to shop" on order cards, per-shop cart cards in the orders tab).
Cart, coupons, checkout and orders still read `JameiaRepository` / `LocalStorage`
(CLAUDE.md §3.1 "On the API today" and §12).

This task:
1. Moves **cart** to `/v1/cart*`, **delivery selection** to `/v1/delivery/*`, **place order** to
   `POST /v1/orders`, and **orders list / detail / cancel** to `/v1/orders*`.
2. Rebuilds the cart as an **offline-first local mirror of the server cart** (the way Talabat /
   Instacart / Amazon behave): instant taps, persisted across restarts, synced to the server,
   and always reconciled to what the server says. The server is the single source of truth for
   prices, totals, fees, offers, stock and line keys.
3. Removes every multi-store concept from cart, checkout and orders UI and state.
4. Holds every change to the performance and architecture bars below; the review agents gate
   completion.

Read before writing (CLAUDE.md §0.1): `CLAUDE.md`, the `jameia-api-integration` skill (all four
references — `migrating-offline-feature.md` is mandatory: this is a legacy target),
`jameia-api-session` (guest `X-Cart-Token`, merge on login), `jameia-api-testing`,
`jameia-api-verify`, then every layer of `features/cart`, `features/checkout`, `features/orders`,
`features/coupons`, and the comparable shipped features `features/address` (single-writer device
cache wiped on sign-out, app-global cubit) and `features/notifications` (pagination, optimistic
update, race guards).

---

## FIGMA

None. Keep the existing visual design; only remove multi-store elements and add the states
listed under BEHAVIOR, built from existing `core/widgets` and design tokens.

---

## API SPEC

Source of truth = the live spec. Re-read each route before building its layer:
`node .claude/skills/jameia-api-integration/scripts/openapi_route.js /v1/cart` (also `/v1/delivery`,
`/v1/orders`, `/v1/reviews`). On Git Bash set `MSYS_NO_PATHCONV=1` first, otherwise the leading
`/` becomes a Windows path and the script reports "no route matches". Docs:
https://docs.jm3eia.store/developers/cart-delivery.html · https://docs.jm3eia.store/developers/orders.html

Paths already exist in `EndPoints` (`cart`, `cartItems`, `cartItem(key)`, `cartCoupon`,
`cartLoyalty`, `cartExpress`, `delivery*`, `orders`, `order(id)`, `orderCancel(id)`, `reviews`).
All money is **int fils**. Every route below returns the normal envelope (none is SSE).

### Cart — guest (`X-Cart-Token`) or customer (Bearer, never the cart token)

| Route | Body | `results` |
|---|---|---|
| `GET /v1/cart` | — | Cart |
| `POST /v1/cart/items` | `{ items: [{ productId, variantId?, quantity ≥1 }] }` (1–50 items) | Cart |
| `PATCH /v1/cart/items/{key}` | `{ quantity ≥0 }` | Cart |
| `DELETE /v1/cart/items/{key}` | — | Cart |
| `POST /v1/cart/coupon` / `DELETE` | `{ code (2..32) }` | Cart |
| `POST /v1/cart/loyalty` / `DELETE` (customer only) | `{ points ≥1 }` | Cart |
| `POST /v1/cart/express` | `{ enabled: bool }` | Cart |
| `DELETE /v1/cart` | — | Cart |

**Every cart mutation returns the whole Cart** — replace local state with it, never patch it.

Cart object: `cartToken` (guest: save via `SessionStore.saveCartToken`), `itemCount`,
`fulfillmentMode` (`delivery|pickup`), `lines[]` { `key` (server line id, required for
PATCH/DELETE), `quantity`, `maxQuantity`, `unitPrice`, `compareAt?`, `lineTotal`, `variantId?`,
`variantName?`, `product` { `_id`, `name`, `slug`, `type` (`standard|variant|bundle`), `price`,
`proPrice?`, `compareAt?`, `image?`, `stock`, `tags[]`, `unitOfSale` (`piece|kg|l|pack`),
`ratingAverage`, `ratingCount` }, `issue` (`null|out_of_stock|quantity_reduced|unavailable`) },
`offerLines[]` { `key`, `quantity`, `offerId`, `offerName`, `product` } (free items — read-only
lines), `appliedOffers[]` { `offerId`, `name`, `rewardType`, `discount`, `reward` (tagged union
on `type`: `free_delivery | percentage_discount{percent,maxDiscount?} | fixed_discount{amount} |
free_product{productId,quantity}`) }, `offerProgress[]` { `offerId`, `name`, `kind`
(`subtotal|item|category`), `currentValue`, `targetValue`, `remainingValue`, `contextId?`,
`contextName?`, `reward`, `rewardProduct?` }, `coupon?` { `code`, `discount` }, `loyalty`
{ `pointsApplied`, `discount` }, `expressOffered`, `expressSelected`, `expressEtaMinutes`,
`expressSurchargeOffered`, `branchOpen`, `capacityAvailable`, `totals` { `subtotal`,
`couponDiscount`, `loyaltyDiscount`, `offerDiscount`, `discount`, `deliveryFee`, `freeDelivery`,
`total`, `minOrder`, `meetsMinOrder`, `baseDeliveryFee`, `expressSurcharge`, `etaMinutes` }.

Codes: `OUT_OF_STOCK`, `CART_EMPTY`, `VALIDATION_ERROR` (400) — branch on `code`, never on text.
Names in the cart are already resolved for `Accept-Language` → refetch the cart on a locale change.

### Delivery — public (guest token or Bearer)

- `GET /v1/delivery/areas` → `{ data: [{ paciAreaId, govNo, name, governorateName, branchId, branchName, zoneId, zoneName, deliveryFee, minOrder, etaMinutes }] }`
- `GET /v1/delivery/branches` → `{ data: [{ _id, name, code, address, phone, lat, lng, services{delivery,pickup,express}, minOrder, etaMinutes }] }`
- `GET /v1/delivery/slots` → `{ data: [{ date (YYYY-MM-DD, Asia/Kuwait), label, slots: [{ templateId, date, start "HH:mm", end, startAt, endAt, label, capacity, booked, remaining, available }] }] }`
- `POST /v1/delivery/select` `{ paciAreaId }` · `POST /v1/delivery/select-branch` `{ branchId }` (pickup) · `POST /v1/delivery/select-address` `{ addressId }` (customer; address must be on the account) · `POST /v1/delivery/resolve-location` `{ lat, lng }` → selection { `mode`, `branchId`, `branchName`, `zoneId?`, `zoneName?`, `deliveryFee`, `minOrder`, `etaMinutes`, plus route-specific fields (`addressId`, `addressLabel`, `areaName`, …) }. After any select, refetch the cart (fees / min order / express change).

### Orders — customer (Bearer)

- `POST /v1/orders` `{ paymentMethod: "cod"|"wallet", notes? (≤256), address? { label, city?, block?, street?, building?, floor?, apartment?, phone? }, deliverySlot? { templateId, date } }` → Order (status `placed`). Places **the current server cart**. Slot only for scheduled delivery; omit it for pickup / express / ASAP. Fails: `CART_EMPTY`, guest (401), insufficient wallet, online payment (only `cod` / `wallet` exist).
- `GET /v1/orders?page&limit(1..100, default 20)&search?` → `{ data: Order[], pagination{ total, page, limit, hasMore } }`
- `GET /v1/orders/{orderId}` → Order
- `POST /v1/orders/{orderId}/cancel` `{ reason: changed_mind|ordered_by_mistake|too_slow|found_elsewhere|other, note? (≤256) }` → Order. Only while cancellable (usually before picking completes) — otherwise a 400 whose `code` must be shown via `failure.localizedMessage`.

Order: `_id`, `orderNumber`, `status` (`placed → confirmed → picking → ready → out_for_delivery → delivered`; terminal `delivery_failed`, `cancelled`), `statusTimeline[]{at,status}`, `fulfillmentMode`, `branch{id,name{en,ar}}`, `zone?`, `address?`, `lines[]{ key, product{id,name{en,ar},image?,type}, variant?{id,name{en,ar},sku?}, quantity, unitPrice, lineTotal }`, `offerLines[]`, `appliedOffers[]`, `coupon?`, `loyalty{pointsRedeemed,discount,pointsEarned}`, `offerDiscount`, `proDiscount`, `subtotal`, `discount`, `deliveryFee`, `total`, `express`, `etaMinutes?`, `deliverySlot?`, `payment{method,status(pending|paid),walletUsed}`, `picking?` (unavailable / substituted lines), `delivery?` (driver name, attempts, `lastFailureReason`), `cancellation?` (reason enum is WIDER than the cancel body — staff reasons included; unknown values → `other`), `createdAt`, `updatedAt`.
Order names are bilingual `{en, ar}` → entity keeps both and exposes `nameFor(languageCode)` (§4).

- `POST /v1/reviews` `{ productId, orderId, rating 1..5, title?, body? }` / `PATCH /v1/reviews/{id}` — reviews are **per product in a delivered order**, not per order.

No order tracking stream exists. No refund, tip, tableware, delivery-code, rider-location or
invoice route exists.

---

## BEHAVIOR

### Single store (applies everywhere)
- The cart has no shop. Drop `shopId` from cart state, cart lines, `CartCubit.add`,
  `quick_add`, `resolveCheckoutShopId()`, the checkout route extra and `CheckoutPage(shopId:)`.
  No "start a new cart from another shop?" flow.
- Checkout shows the **branch / fulfilment** from the delivery selection, not a shop header.
- Orders tab: one "current cart" card (if the cart is non-empty), not one per shop. Order cards
  lose "go to shop"; "reorder" re-adds the lines (see below) and opens the cart.
- Delete the multi-store leftovers that become dead: `checkout/presentation/util/shop_display.dart`,
  `checkout/domain/entities/shop_entity.dart` + `shop_mapper.dart` if unused, the synthetic
  `jameia` supplier id path. Features other than cart / checkout / orders / coupons that still pass a
  shop id (discovery `shop_model_bridge`, home, shop, recipes, product_details call sites of
  `CartCubit`) only get the **call-site signature change** — no other edits there.

### Cart — offline-first local mirror (the core of this task)
- **One app-global `CartCubit`** (keep the name and its place in `AppGlobalCubits`) backed by a
  new `CartRepository` whose implementation combines a remote datasource (`/v1/cart*`) and a local
  datasource (`LocalStorage`: last server cart snapshot + pending-mutation queue). The state holds
  API-shaped entities (money in fils, server line `key`), replacing the offline `CartItem` /
  `Product` DTOs in cart state.
- **Cold start:** emit the persisted snapshot on the first frame (badge and totals visible at once,
  flagged `syncing`), then `GET /v1/cart` in the background and replace. Never block the UI on the
  network to show the cart.
- **Taps are instant (optimistic):** `+` / `−` / remove update the local quantity for the line
  immediately (badge, steppers, line total estimate from `unitPrice × qty`); server-only numbers
  (discounts, fees, total, offer progress) show as "updating" until the server reply lands.
- **Coalesce + debounce:** rapid taps on the same line collapse into ONE request carrying the final
  quantity (debounce ~350–500 ms per line, value in `AppMotion`/a named constant, not inline). New
  product → `POST /v1/cart/items`; existing line → `PATCH /v1/cart/items/{key}` with the absolute
  quantity (`0` or `DELETE` to remove). Batch several new products added within the window into one
  `POST` (≤50 items).
- **Serialize writes:** one mutation in flight at a time (each reply is the whole cart). After a
  reply, re-apply still-pending local deltas on top of it before emitting (rebase), so a reply
  never makes a just-tapped stepper jump back. A reply older than the latest applied one
  (generation counter) is dropped.
- **Local line identity:** a line is identified locally by `productId + variantId` until the server
  returns its `key`; keep that mapping so the product tile's stepper resolves to the right `key`.
- **Offline / failure:** mutations made offline stay in the persisted queue and replay in order when
  the network is back or on next launch. A 4xx on a mutation drops that op, restores the server
  truth and shows a snackbar (`showJameiaSnackBar` + `failure.localizedMessage`): `OUT_OF_STOCK` →
  line marked out of stock, quantity rolled back. A transport failure keeps the op queued and
  shows a small "not synced" indicator, never an error page over the cart.
- **Server reconciliation wins:** `issue` on a line renders a line-level notice
  (`out_of_stock` / `quantity_reduced` / `unavailable`) and the stepper respects `maxQuantity`
  (disable `+` at max). `offerLines` render as read-only free items. `offerProgress` renders the
  "add X more for …" hint. `branchOpen == false` / `capacityAvailable == false` /
  `meetsMinOrder == false` disable checkout with the reason (min order shows `remaining` in KWD
  from fils via the existing formatter).
- **Pro price:** the server prices lines for the signed-in customer. Remove the client-side
  `pro` flag from the add path; tiles may keep showing `proPrice` from the catalogue, the cart shows
  the server `unitPrice`.
- **Session:** guest → store `cartToken` from any cart reply (`SessionStore`), sent by the headers
  interceptor while signed out. Sign-in → server merges the guest cart; the `app.dart` listener on
  `AuthSessionCubit` flushes the pending queue first, then refetches the cart (Bearer, no token).
  Sign-out / expiry → wipe the local snapshot + queue + cart token and start an empty guest cart
  (§3.2.6 session-bound work lives in `app.dart`, not a page). Locale change → refetch (names are
  localized server-side).
- **Coupon / loyalty / express** go through `/v1/cart/coupon|loyalty|express` and take the new cart
  from the reply (not optimistic; the button shows a busy state and cannot fire twice). Loyalty is
  customer-only → `UnauthorizedFailure` shows the sign-in prompt. The coupons feature's
  "apply" flow calls the cart coupon use case; the offline coupon wallet lists stay offline (out of
  scope) but must not compute discounts locally any more.
- **Clear cart** → `DELETE /v1/cart`, optimistic empty with rollback on failure.

### Checkout
- Entry: cart preview → checkout (no extra). Checkout reads the app-global cart; no second cart copy.
- Fulfilment: delivery to a saved address (`select-address`, from `AddressBookCubit`'s address)
  or pickup (`branches` + `select-branch`). Guest delivery by area (`areas` + `select`) only if
  already present in the UI; otherwise signed-in only. After a selection → refetch cart.
- Timing: ASAP / express (`POST /v1/cart/express` when `expressOffered`) or a scheduled slot from
  `GET /v1/delivery/slots` (only `available` slots selectable, labels as sent).
- Payment: only `cod` and `wallet` (wallet shows the customer wallet balance from the
  `AuthSessionCubit` customer snapshot; disabled when balance < total). Remove every other payment
  option, tip, tableware and weather-surge UI that has no API.
- Notes ≤256 chars (counter). Place order → `POST /v1/orders`; the button cannot fire twice; on
  success: if `wallet` was used, refresh the customer snapshot (wallet balance) into
  `AuthSessionCubit.updateCustomer`; the cart is refetched (server empties
  it), local snapshot replaced, then `context.pushReplacement` to the order tracking page with the
  new order id. Guest → sign-in prompt → `context.go(Routes.login)`. `CART_EMPTY` / wallet / min-order
  failures → snackbar + stay.

### Orders
- List: `GET /v1/orders` paginated (`limit` 20, infinite scroll, re-entry guard, stale-page drop by
  generation counter), pull-to-refresh with `BrandedRefresh`, tabs by status group (in progress =
  non-terminal, completed = `delivered`, cancelled/failed) computed in a use case/entity, not a
  widget. Loading / empty / error+retry / offline / signed-out states per §3.2.4.
- Detail / tracking: `GET /v1/orders/{id}`; stepper driven by `status` + `statusTimeline`;
  `delivery_failed` and `cancelled` show their reason; picking substitutions / unavailable lines
  shown on the lines. Refresh while the page is visible and the status is non-terminal by polling
  (interval ≥30 s as a named constant), paused when the app is backgrounded or the page is not on
  top; also refresh when a notification for this order arrives if the notifications payload carries
  the order id (check `features/notifications` — do not add a new stream).
- Cancel: reason sheet with exactly the 5 API reasons (i18n labels) + optional note; shown only for
  `placed`, `confirmed`, `picking` (docs: "typically before picking completes" — the server decides;
  a rejection shows its message); the reply replaces the order in list and detail.
- Reorder: add the order's lines through the cart's batched `POST /v1/cart/items`
  (`productId`, `variantId`, `quantity`), then open the cart preview; lines the server rejects are
  reported by the cart `issue` flags.
- Review: per product of a `delivered` order via `POST /v1/reviews`; the current order-level review
  page becomes a list of the order's products with a rating each (only if it fits the existing UI;
  otherwise keep the page reachable only for delivered orders and send one review per rated product).
- Invoice: rendered from the order's own totals (no client-side price maths).
- No API → hide the entry points (do not delete the files in this task; list them in the report):
  refund / refund detail, delivery code, rider live map / rider contact, tip, on-time promise, NPS.

---

## REQUIREMENTS

- Clean Architecture per CLAUDE.md §1–§4; build order §0.2; templates §5 and the skill's
  `layer-templates.md`; legacy-target rules in `migrating-offline-feature.md` (keep a repository
  contract where callers exist, swap the datasource underneath, mind the id-space trap: catalogue
  product ids are backend `ObjectId`s — the offline ids must not reach the API).
- New shared entities go to `core/domain/entities/` only if 2+ features use them (cart line,
  cart totals, order line are used by cart / checkout / orders / home → core). Order view
  aggregates stay in `features/orders/domain/entities/`. Money stays `int` fils in domain; KWD
  formatting only in presentation.
- DTOs: key constants, `is` checks, `ParsingException` on missing `key` / `_id` / `orderNumber`,
  unknown enum wire values → `other`, a malformed line/order row logged and skipped
  (`ApiPayload.asMap`). One cart DTO shared by all cart routes; one order DTO shared by list,
  detail, place and cancel.
- One use case per operation (get cart, add items, set line quantity, remove line, clear cart,
  apply/remove coupon, apply/remove loyalty, set express, flush pending cart ops, get areas /
  branches / slots, select address / branch / area, resolve location if used, place order, get
  orders page, get order, cancel order, reorder, submit review).
- State: one immutable Equatable state per cubit + `SafeCubitMixin`; API-backed states hold
  `Failure?` (transient). The cart state exposes a precomputed `Map<productKey, int>` quantity
  index so tiles never iterate lines in `build`.
- Localization: every new string in both `assets/i18n/en.json` and `ar.json` (status labels,
  cancel reasons, line issues, offer progress, min-order, branch closed, capacity full,
  "not synced", payment methods, slot picker). Data names via `nameFor(languageCode)` for orders;
  cart names come already localized (refetch on locale change).
- Theme / tokens only (`AppColors`, `AppSpacing`, `AppSize`, `AppTextStyles`, `AppMotion`);
  RTL-safe directional widgets; reduced motion respected.
- Reuse: `AppLoader`, `ErrorView`, `EmptyStateView`, `BrandedRefresh`, `showJameiaSnackBar`,
  `showJameiaBottomSheet`, existing stepper / price widgets, `CatalogProductCard`.
- Mock API: `.claude/skills/jameia-api-verify/scripts/mock_api/server.js` has no cart / delivery /
  orders routes — add them (whole-cart replies, `cartToken`, `OUT_OF_STOCK` knob, `CART_EMPTY`,
  guest vs Bearer, slots, place → `placed`, cancel allowed only for `placed|confirmed|picking`, status
  advance knob) so every flow and failure path can be seen in the `api` trace.
- Record: `docs/api_integration.md` §6.1 rows and `references/backend-contract.md` status table
  (cart, coupons-apply, checkout, orders → on API) plus any contract quirk found while testing.

---

## PERFORMANCE REQUIREMENTS (gated by `flutter-performance-reviewer`)

- Product tiles, steppers and cart badge use `BlocSelector` / `buildWhen` on the single value they
  show (quantity for one product key, `itemCount`); a quantity change on one product must not
  rebuild other tiles, the whole home feed or the cart page.
- Equality: entities `Equatable`; the state is replaced only when something changed (no emit of an
  identical state; no `props` getters that recompute totals).
- Network: debounce + coalesce per line, batch new lines, one in-flight cart mutation, no refetch on
  every page open (the cubit is app-global; refetch only on start, session change, locale change,
  delivery selection, place order, pull-to-refresh). Delivery areas / branches cached in memory for
  the session. Orders polling only while visible + non-terminal, cancelled in `close()`.
- Local storage: snapshot + queue written once per settled state (debounced), never on every tap;
  JSON encode/decode off the frame if the payload is large (`compute` over a threshold).
- Lists: `ListView.builder` / slivers for cart lines and orders; stable `ValueKey(line.key)` /
  `ValueKey(order.id)`; `RepaintBoundary` around animated list items; paginated orders.
- Images: cached network images with `memCacheWidth/Height` sized to the thumbnail.
- `const` constructors everywhere possible; no work in `build` that belongs in the cubit/entity.

---

## UI GUIDELINES

- Keep the current layouts and visual language; only remove multi-store parts and add the new
  states (line issues, offer progress, min-order bar, branch closed, capacity full, sync indicator,
  slot picker, fulfilment switch, cancel sheet with API reasons).
- One widget per file (private ones too), ~120–150 lines max, no `Widget _buildX()` helpers,
  sub-folder per page (`widgets/cart/`, `widgets/checkout/`, `widgets/orders_list/`, `widgets/tracking/`).
- Pages compose, provide cubits, switch on state and navigate; no pricing, grouping, filtering or
  sorting in widgets.
- Navigation via `Routes` + GoRouter with `JameiaTransitionPage`; route extras are entities or
  primitives (order id `String`), never DTOs.
- Dialogs / sheets via `showJameiaDialog` / `showJameiaBottomSheet`; messages via `showJameiaSnackBar`.
- Responsive: `Expanded` / `Flexible`; text scaling clamped by the app builder; test at small width
  and in Arabic.

---

## ARCHITECTURE GUIDELINES (gated by `flutter-architecture-auditor`)

- Dependency direction inward only (§2). Remote datasources depend on `ApiConsumer` only; the
  cart local datasource on `LocalStorage` / `SessionStore` only; the cart repository impl is the
  ONLY place that combines them (sync queue, rebase, snapshot). Every repository method in
  `execute(...)`.
- Cubits depend on use cases only; no `sl`, no `BuildContext`, no `ApiStatus` (it sits in
  `core/network` — branch on `Failure.code` string constants in the domain, or, if a cubit must
  branch on a backend code, first do the §12 core gap "move `ApiStatus` under `core/error/` and
  re-export from `failures.dart`" as its own step and report it).
- Cross-feature: other features import only `CartCubit` (app-global). Checkout reads the cart
  through `CartCubit`; orders' reorder calls a cart use case through its own cubit or through
  `CartCubit` — never a cart datasource/repository.
- DI: `initCartFeature()` / `initCheckoutFeature()` / `initOrdersFeature()`: datasources,
  repositories, use cases lazy singletons; page cubits factories; `CartCubit` stays built by
  `AppGlobalCubits` with constructor injection (remove its `sl` factory constructor).
- Remove from the touched features the §12 legacy they contain: per-feature duplicate entities
  (`checkout/domain/entities/{coupon,jameia_address,jameia_order,shop}_entity.dart`),
  `presentation/util/*_display.dart`, cubits calling repositories, hand-written `try/catch → Left`.
- No `// ignore:` for `architecture_lints`, no new excludes, no deleted tests.

---

## EXECUTION ORDER

Work phase by phase, one at a time, in the main session (no parallel agents for the build). Each
phase ends green (`dart analyze` + `flutter test`) before the next starts.

1. **Cart data + domain** — DTOs, mappers, remote + local datasources, repository with sync
   queue / rebase / snapshot, use cases, tests (DTO, datasource on `FakeHttpClientAdapter`,
   repository failure mapping, queue replay, rebase, stale reply drop).
2. **Cart presentation + single-store** — new `CartCubit` state, call-site updates in every
   feature, cart preview page, line issues, offer progress, min-order, badge selectors, session
   wiring in `app.dart`, cubit tests with gated fakes (rapid taps coalesced, reply during taps,
   offline queue, sign-in merge, sign-out wipe, `OUT_OF_STOCK` rollback).
3. **Delivery + checkout + place order** — delivery datasource / use cases, checkout rewrite
   without shop, slots, payment `cod|wallet`, express, notes, place order, double-submit test.
4. **Orders** — list pagination, detail + polling, cancel, reorder, review, invoice from order
   totals, hide no-API entry points, tests (stale page, cancel race, polling stops on terminal
   status / close).
5. **Mock API + on-device verification** (`jameia-api-verify` checklist), docs + contract status.
6. **Reviews** — run, in order, and fix every High/Medium finding before reporting:
   `F:\_jam3eia_apps\workflow\workflow\agents\flutter-performance-reviewer.md`,
   `F:\_jam3eia_apps\workflow\workflow\agents\flutter-architecture-auditor.md`, then the
   clean-code reviewer and `pre-pr-guardian` (CLAUDE.md §10). Paste each verdict.

---

## ACCEPTANCE CRITERIA

- No `shopId` / shop header / per-shop cart anywhere in cart, checkout or orders; checkout opens
  without a route extra; `grep -rn "shopId" lib/src/features/{cart,checkout,orders}` is empty.
- Guest: add to cart offline-first → `POST /v1/cart/items` seen once in the `api` trace for a burst
  of 5 taps on one product (coalesced); `X-Cart-Token` saved and sent; restart app → cart visible on
  the first frame, then matches `GET /v1/cart`.
- Airplane mode: taps still update the cart; "not synced" shown; back online → queue replays in
  order and the final cart equals the server's.
- `OUT_OF_STOCK` (mock knob) → line rolled back + snackbar; `quantity_reduced` / `unavailable`
  issues rendered; `+` disabled at `maxQuantity`.
- Totals, discounts, fees, offers, min-order and express shown are exactly the server's; no
  client-side pricing maths remains in cart / checkout / orders (grep for fee / VAT / discount
  arithmetic).
- Sign-in merges the guest cart (server) and the app shows the merged cart; sign-out empties the
  local cart and token; locale switch refetches localized names.
- Checkout: delivery (saved address) and pickup (branch) both place an order with `cod` and with
  `wallet`; scheduled slot sent only when chosen; guest is sent to login via `go`; double tap on
  "Place order" sends one request; success lands on tracking for the new order and the cart is empty.
- Orders: paginated list with all five screen states, tracking stepper from `statusTimeline`,
  polling stops on terminal status and on page close, cancel is offered for `placed|confirmed|picking` and shows
  the backend message otherwise, reorder refills the cart in one request.
- `dart analyze` (repo root, no path) → 0 errors / 0 warnings in touched files, including
  `architecture_lints`; `flutter test` → all pass, new tests for every use case, mapper, datasource,
  repository and cubit behavior listed above.
- i18n keys present in `en.json` and `ar.json`; RTL and reduced motion checked on device.
- Performance and architecture reviewers: no High findings open; verdicts pasted.
- Docs: `docs/api_integration.md` §6.1 + `backend-contract.md` status updated; CLAUDE.md §3.1 /
  §12 lines for cart / checkout / orders updated to "on the API".
- Report in the §0.9 shape, listing hidden no-API screens and any contract quirk found.
