# FEATURE NAME

Jm3eia Assistant: a streaming AI shopping chat on `/v1/assistant`. It covers the SSE turn, rich cards, cart proposals, history, handoff, feedback and a full motion layer.

---

## CONTEXT

The jm3eia backend has a shopping assistant. It is an LLM with store tools (product search, cart,
delivery, recipes, offers, orders, FAQ). It answers over **server-sent events** and attaches
typed UI cards ("blocks") to every reply. The app has no assistant yet:
- `EndPoints` already lists the routes (`core/network/end_points.dart:107-126`).
- `SessionStore.ensureAssistantGuestKey()` + `AppHeadersInterceptor` already send `X-Assistant-Guest`
  while the customer is signed out.
- `EventStreamClient` can only do a reconnecting `GET` (CLAUDE.md §12 gap: "assistant replies stream from a `POST`").
- `features/support` has an **offline, scripted** rider chat (`ImChatPage`). It is not an assistant.
  Do not build on it and do not change it.

This task:
1. Adds a new feature **`features/assistant`** on the jm3eia API: chat thread, streaming replies,
   every documented block kind, cart proposals confirmed through the assistant, suggestion chips,
   message feedback, handoff to a human, conversation history.
2. Extends **`EventStreamClient`** in core with a one-shot `POST` stream (no auto-reconnect).
3. Gives the screen a **deliberate motion design** (§ANIMATIONS) built from the existing
   `core/motion` layer and tokens, with reduced motion respected everywhere.
4. Holds the change to the performance, architecture and clean-code bars below. The three review
   agents gate completion.

Read before writing (CLAUDE.md §0.1):
- `CLAUDE.md` (wins over this prompt if they disagree).
- The skills: `jameia-api-integration` (+ `references/layer-templates.md`, `patterns.md`,
  `backend-contract.md`), `jameia-api-streaming` (mandatory: SSE rules, one-shot `POST` gap),
  `jameia-api-session` (guest key, merge on login), `jameia-api-testing`, `jameia-api-verify`.
- The shipped features to mirror:
  - `features/notifications`: SSE datasource, `guardStream`, paginated feed with generation
    counter, optimistic update + rollback, transient `Failure` in state.
  - `features/account`: `ProfileCubit` double-submit guards.
  - `features/cart`: `CartCubit.refresh()`; checkout already calls it from a page listener at
    `checkout_page.dart:39`.
- `core/motion/*` and `core/widgets/*`, before writing any animation or widget.

Every fact under API SPEC marked **(live)** was observed against `https://api.jm3eia.store` on
2026-09-24: 6 guest turns (EN + AR), list/detail/feedback/confirm, validation and ownership errors.
The raw frames are saved in `test/features/assistant/fixtures/live_2026_09_24/`.
Re-run the probe with `.claude/skills/jameia-api-verify/scripts/assistant_sse_probe.js`. Every
live send creates a real conversation and uses LLM tokens, so keep live runs few. **Never call
`handoff` on the live host**: it opens a real support ticket. Use the mock.

---

## FIGMA

None. Design from the existing design system only:
- Tokens: `AppColors` (brand = `primary` `#22C55E` green; ignore old comments that say "yellow"),
  `AppSpacing`, `AppRadius`, `AppSize`, `AppTextStyles`, `AppShadows`, `AppMotion`.
- Shared widgets: `core/widgets`.
- Motion widgets: `core/motion`.

Visual direction:
- The page is calm and light: `mediumBackground` page, white assistant surfaces, and brand green for
  the user's bubbles and primary actions.
- Cards reuse the catalogue look (`CatalogProductCard`, `CatalogRecipeCard`).
- Existing chat-sized tokens nobody uses yet: `SuiRadius.bubble` (16), `SuiRadius.callout` (6),
  `SuiRadius.inputPill` (24) in `core/constants/app_constants.dart`.
- `AppColors.chatBubbleMine` exists but belongs to the rider chat's olive palette. Use
  `primary` / `brandForeground` for the user bubble unless it looks wrong next to the green brand.
  If you add a token, add exactly one (e.g. `assistantBubbleIncoming`) in `AppColors` + `JameiaColors`.

---

## API SPEC

Source of truth = the live spec. Re-read each route before building its layer:
`node .claude/skills/jameia-api-integration/scripts/openapi_route.js assistant`. On Git Bash, a
filter with a leading `/` needs `MSYS_NO_PATHCONV=1`. Docs:
https://docs.jm3eia.store/developers/assistant.html. Paths already exist in `EndPoints` (no new
constants needed). `assistantMessages` is already in `EndPoints.streamingPaths`.

### Routes

| Route | Who | Body / query | `results` |
|---|---|---|---|
| `GET /v1/assistant/conversations` | customer or guest | `page` ≥1, `limit` 1..100 (default 20), `search` 1..120 | `{ data: Conversation[], pagination{ total, page, limit, hasMore } }` |
| `GET /v1/assistant/conversations/{id}` | owner | — | `{ conversation: Conversation, messages: Message[] }` |
| `POST /v1/assistant/messages` | customer or guest | `{ message (1..2000), conversationId? (24-hex) }` | **SSE stream**, not the envelope |
| `POST /v1/assistant/actions/{actionId}/confirm` | owner | — (actionId 8..64) | `{ message: string, blocks: Block[] }` |
| `POST /v1/assistant/conversations/{id}/handoff` | owner | `{ subject? 1..120, category? 1..64, subcategory? 1..64 }` all optional | `{ ticketId, ticketNumber, message }` |
| `POST /v1/assistant/messages/{messageId}/feedback` | owner | `{ feedback: "up" \| "down" \| null }` | `{ message }` |

- **Auth.** Bearer when signed in. While signed out, `X-Assistant-Guest` (32-hex) is added by the
  interceptor, so a feature never touches it.
- **Guest merge.** After OTP login the server merges guest threads onto the customer, and the app
  drops the key (`clearGuestSession()`).
- **Guests off.** Unsigned callers get `AUTHENTICATION_REQUIRED` (401) when `allowGuests` is false.
- **Assistant off.** When `Settings → Assistant enabled: false`, every route fails.
- **Rate limits:** list 60/min, send 20/min. The 429 is retried by `RateLimitRetryInterceptor`
  before the stream opens.

**Conversation:**
- Fields: `_id`, `title` (= first user message), `language` (`en|ar`),
  `status` (`active|handed_off|closed`), `supportTicketId?`, `messageCount`, `lastMessageAt`,
  `lastMessagePreview`, `usage{promptTokens, completionTokens}`, `createdAt`, `updatedAt`.
- A thread **closes** at a message/token cap. The next send starts a NEW conversation, and
  `message_start` carries the new id.

**Message:**
- Fields: `_id`, `conversationId`, `role` (`user|assistant|system`), `content` (plain text),
  `blocks[]`, `feedback` (`up|down|null`), `createdAt`, `updatedAt`.

**Availability:**
- Source: `GET /v1/init` → `results.store.assistant { enabled, allowGuests }` and
  `results.store.featureFlags.assistant` (bool).
- **(live)** both `true`; `/v1/init` is ~2.9 KB.
- Nothing in the app parses these yet.

### SSE protocol: `POST /v1/assistant/messages`

Request headers: `Content-Type: application/json`, `Accept: text/event-stream`. Frames are
`event: <name>\ndata: {json}\n\n`, in this order:

| # | event | data | Client does |
|---|---|---|---|
| 0 | `: connected` (comment) | — | nothing; it counts as liveness |
| 1 | `message_start` | `{ conversationId }` | keep the id; if it differs from the current thread, the old one was closed (see BEHAVIOR) |
| 2 | `user_message` | `{ conversationId, message: Message }` | swap the optimistic user bubble for the real one (real `_id`) |
| 3* | `text_delta` | `{ delta }` | append to the live text (coalesced, see PERFORMANCE) |
| 3* | `tool_start` | `{ name, callId }` | show the tool status line |
| 3* | `tool_end` | `{ name, callId, ok }` | clear that tool; `ok:false` is NOT an error for the UI |
| 3* | `block` | `{ block: Block }` | append a card to the live turn |
| 4 | `message_end` | `{ conversationId, message: Message }` | **replace** the live turn with this hydrated message; close |
| 4 | `error` | `{ code, message }` | terminal: keep what streamed, show an inline error + retry; close |

### Block kinds (switch on `kind`; drop unknown kinds in the DTO with a `log`, never crash)

| kind | fields | Reuse / render | Tap |
|---|---|---|---|
| `text` | `text` (≤8000, light markdown) | `AssistantRichText` (see below) | long-press → copy |
| `products` | `products[]` (catalogue product shape) | `ProductModel` → `CatalogProductEntity` (core) → horizontal rail of `CatalogProductCard` with the normal `CartCubit` add control | card → `Routes.productDetail`, `ProductDetailArgs.of(product)` |
| `product_detail` | `product` | same entity, one wide card (image, name, price, rating, add control) | same |
| `cart_action` | `actionId`, `items[]{ productId, variantId?, quantity ≥1, product? }`, `status` (`pending\|confirmed\|cancelled\|expired`), `estimatedTotal?` (fils) | proposal card (see BEHAVIOR) | Confirm → `POST /actions/{id}/confirm` |
| `cart_summary` | `cart` (**same shape as `GET /v1/cart`**) | feature-owned **`AssistantCartSnapshot`** entity with plain fields only (item count, `totalFils`, `minOrderFils`, `meetsMinOrder`, ≤4 `{ name, imageUrl }` pairs), parsed by a small assistant DTO (core `ProductModel` may be used inside the assistant `data/` layer only; no DTO reaches the entity, cubit or widgets). Do **not** move or import the cart feature's DTOs (see REQUIREMENTS). Compact summary card | "View cart" → `Routes.cartPreview` |
| `order` / `order_status` | `order{ _id, orderNumber, status, total, createdAt, itemCount, thumbnails[] }` | new `AssistantOrderSummary` entity; status decoded with core `OrderMapper.orderStatusOf` → core `OrderStatus` (+ `labelKey`, `OrderStatusPalette`) | → `Routes.orderTracking`, extra = **`_id`** (not `orderNumber`) |
| `offers` | `offers[]` (offer shape), `couponCode?` | `OfferEntity` moved to core (REQUIREMENTS); cards: name, description; copyable coupon chip | → `Routes.offers` |
| `recipe` | `recipe{ _id, slug, title, imageUrl, prepMinutes, cookMinutes, servings, cuisine{slug,name}, diet{slug,name} }`, `servings` (1..20), `ingredientCount` | `RecipeSummaryModel` → `RecipeSummaryEntity` (core) + `CatalogRecipeCard`, plus a "{n} ingredients · serves {s}" line | → `Routes.recipe`, extra slug |
| `faq` | `items[]{ id, question, answer }` | accordion rows (`AnimatedAccordion`) | expand |
| `categories` | `categories[]` (category shape) | `CategoryModel` → `CatalogCategoryEntity` (core), circle rail | → `Routes.category`, `CategoryArgs.of` |
| `brands` | `brands[]{ _id, name, slug, image }` | `BrandModel` → `BrandEntity` (core), logo rail | → `Routes.productListing`, `ProductListingArgs.brand(slug, name)` |
| `delivery_slots` | `days[]{ date YYYY-MM-DD (Kuwait), label, slots[]{ templateId, date, start, end, startAt, endAt, label, capacity, booked, remaining, available } }` | `DeliverySlotDayEntity` + `DeliverySlotEntity` moved to core (REQUIREMENTS), parsed by an assistant-owned DTO; day tabs + slot chips (unavailable greyed) | an available slot sends `assistant.slot_prompt` (day + slot label) as the next message |
| `delivery_info` | `areaName?`, `zoneName?`, `fee?` (fils), `etaMinutes?` | info row; **hide when every field is absent** | — |
| `locations` | `items[]{ label, address?, phone?, lat, lng }` | list tiles (no inline map; see PERFORMANCE) | phone → copy + snackbar |
| `handoff` | `ticketId`, `ticketNumber` | ticket card with copyable number | — (support is offline, no ticket screen) |
| `actions` | `suggestions[]{ label 1..80, prompt 1..240 }` | chips; **label** shown, **prompt** sent | send `prompt` |
| `error` | `code`, `message?` | inline error card (message as sent, else `assistant.error_generic`) | — |

Money is `int` fils everywhere; format only in presentation with the existing formatter. Names are
already resolved for `Accept-Language`.

### Verified live behaviour (2026-09-24). Build for these; don't rediscover them

| # | Finding (live) | Evidence | What the app must do |
|---|---|---|---|
| L1 | Stream opens with a `: connected` comment, then `message_start` + `user_message` within ~1 ms | 6/6 turns | treat the first bytes as "connected"; show "thinking" until the first delta / tool / block |
| L2 | Time to first content 1.0–3.8 s (tool calls first); whole turn 2.6–4.2 s | all turns | thinking + tool status UI is required, not optional |
| L3 | `text_delta` is **word-sized, ~10 ms apart** (25–100 frames/turn) | turn 1: 27 deltas in 190 ms | never emit one state per delta (PERFORMANCE: coalesce) |
| L4 | **Blocks stream BEFORE the text**; the hydrated `message_end.blocks` order is `text` → cards (stream order) → `actions` | turns 2, 5, 6 | render the live turn in the canonical order (text bubble on top, cards under it, chips last) so the `message_end` swap causes **no reflow** |
| L5 | `actions` (suggestion chips) arrive **only in `message_end`**, never as a live `block` | turns 1, 2, 5 | chips appear at the swap (animated in); never expect them live |
| L6 | `message_end.message.content` == concatenated deltas == the `text` block | 4/4 completed turns | the swap never changes the visible text |
| L7 | **Every turn with a `cart_action` ends with `error {code: "INTERNAL_ERROR", message: "Document failed validation"}`**; the assistant message is NOT saved; confirming the streamed `actionId` → **404 `RESOURCE_NOT_FOUND` "Action not found"** | EN turn 3 + AR turn 4 (2/2) | backend bug (report it). App: keep the streamed cards + inline error + Retry; a confirm 404 marks the card **expired** ("This suggestion is no longer available"), never a crash or page error |
| L8 | Validation fails **before** the stream as a normal JSON envelope 400 `VALIDATION_ERROR` (empty message, bad `conversationId`, `limit` > 100) | curl | the one-shot `POST` must read a non-2xx body as the envelope and throw the typed `AppException` with `code` |
| L9 | A `conversationId` the caller doesn't own → HTTP 200 SSE + terminal `error {code: "RESOURCE_NOT_FOUND", message: "Conversation not found"}` | curl with another guest key | drop the stale id, offer "Start a new chat" |
| L10 | `GET …/conversations` without / with a malformed guest header → 200 empty list (no 401); `POST /messages` without any identity **creates an orphan thread** | curl | the app always has an identity (interceptor); never call these with headers stripped |
| L11 | `search` is **ignored** (every query returns all threads); list is sorted by `lastMessageAt` desc | `search=zzzqqq` → 3 of 3 | no search box in v1 (report to backend) |
| L12 | `messageCount` is stale (4 with 5 messages; 0 with 1) | detail vs list | never display or rely on `messageCount` |
| L13 | `delivery_info` can arrive with **no fields** (`{"kind":"delivery_info"}`) | turn 5 | hide the empty card |
| L14 | `user_message.message.blocks` is `[]`, but the stored user message has a `text` block | stream vs detail | a user bubble renders `content`, never blocks |
| L15 | `message_end.message.createdAt` == the user message's `createdAt` (detail says +3.5 s) | turn 1 | don't sort by `createdAt`; keep server/list order |
| L16 | Feedback is accepted on **user** messages too; `null` clears it; a bad value → 400 | curl | show thumbs only on persisted assistant messages |
| L17 | Tool names seen: `search_products`, `add_to_cart`, `list_delivery_slots`, `check_delivery`, `search_recipes`, `list_offers` | frames | map to i18n labels; unknown name → `assistant.tool.generic`; never show raw names |
| L18 | `tags[]` leak raw 24-hex ids | products blocks | already filtered by `CatalogProductMapper.toEntity` (reuse it) |
| L19 | `variant` products carry `price: 0` in lists (catalogue quirk) | catalogue memory | reuse the card's existing variant handling (`canQuickAdd` → choose options → PDP) |
| L20 | No rate-limit headers on the SSE response; list shows `x-ratelimit-limit: 60`, confirm `300` | headers | rely on the 429 path only |

### Backend issues to report (not app work; list them in the final report)

1. **L7**: every assistant turn that proposes a cart change fails to persist ("Document failed
   validation"), so no cart proposal can ever be confirmed in production.
2. **L11**: `GET /v1/assistant/conversations?search=` is not applied.
3. **L12**: stale `messageCount`.
4. **L13**: empty `delivery_info` block.
5. **L10**: `POST /messages` with no identity creates an unreachable thread (should be 401).
6. **L15**: the `createdAt` on the `message_end` message is wrong.
7. Open question: does a guest's confirmed cart action use the guest's `X-Cart-Token` cart, and can
   `cart_summary.cart.cartToken` differ from the stored token? The app assumes the same cart and
   refetches (`CartCubit.refresh()`). If it can differ, the cart feature must adopt the token (cart
   owner's decision).
8. Open question: which `statusMessage` does a disabled assistant return (403 / 503 / 404)?

---

## BEHAVIOR

### Availability + entry points
- **Availability** = `store.assistant.enabled && store.featureFlags.assistant != false`, read from
  `GET /v1/init` by the assistant's own datasource. Memoize the result for the app run (copy the
  memoized-future pattern of `LoyaltyRemoteDataSourceImpl`); a failed read is not memoized. It is
  exposed by the app-global **`AssistantAvailabilityCubit`**
  (`unknown | available | unavailable`, plus `allowGuests`). The cubit loads lazily when the first
  entry point builds, never blocks app start, and keeps `unknown` → entries hidden on failure.
- **Entry 1: Home header.** An assistant button beside the notifications bell in
  `HomeHeroDelegate` (same 40 dp disc as `HomeNotificationsBell`; icon `Icons.auto_awesome_outlined`,
  already used in home), shown only when `available`. `context.push(Routes.assistant)`.
  `features/home` was being redesigned by another session on 2026-09-24, so `HomeHeroDelegate`
  may be renamed or gone. Coordinate with the home owner, and put the button wherever the
  redesigned header keeps its bell.
- **Entry 2: Mine menu.** A row in `MineMenuGroup` next to customer service (label `assistant.title`),
  shown only when `available`.
- Signed out + `allowGuests == false`: the entries still show, and the chat page opens on the
  sign-in prompt (`SignedOutView`-style, `context.go(Routes.login)`), never a pre-check of the session
  in the entry widget.
- Optional (not required): "Ask about this product" on the PDP → `Routes.assistant` with
  `AssistantChatArgs(initialPrompt:)`. Build only if everything else is done; list it in the report.

### Chat page (`Routes.assistant`, extra `AssistantChatArgs?{ conversationId?, initialPrompt? }`)

**Page states:**
- **new chat**: the welcome view.
- **loading thread**: skeleton bubbles.
- **ready**.
- **thread error**: `ErrorView` + retry.
- **signed-out**: sign-in prompt.
- **unavailable**: `EmptyStateView` with `assistant.unavailable` and a back action.
- **offline**: `ErrorView` with `core.no_internet` via `failure.localizedMessage`.

**Welcome view (new chat):**
- A hero with the assistant name, one line of copy, and 4 starter chips
  (`assistant.starter_*`: offers today, breakfast essentials, where is my order, delivery times &
  fees). Each chip has a label + prompt from i18n.
- A **"Continue your last chat"** tile when `GET /conversations?limit=1` returns an `active` thread.
  This is the only request made on open. If it fails, the tile is hidden and no error view shows.

**App bar:**
- Back.
- Title `assistant.title` with a subtitle that swaps between `assistant.subtitle_ready` and
  `assistant.subtitle_typing` while a turn streams.
- Actions:
  - **history** (push `Routes.assistantHistory`, await the chosen conversation id).
  - **cart** icon with the `CartCubit` item-count badge (`BlocSelector` on the count). It is the
    `FlyToCart` target while this page is on top.
  - overflow menu: **New chat** and **Talk to a person** (handoff; enabled only when a
    `conversationId` exists and the status is `active`).

**Composer:**
- Multi-line (1–5 lines), `assistant.composer_hint`.
- Trims before sending. Send is disabled when empty or while a turn streams.
- 2000-char limit enforced in the domain (`AssistantPrompt`). A counter shows from 1800 chars.
- Send ↔ Stop morph while streaming.
- Respects the keyboard inset and bottom safe area.
- Replaced by a **"This chat has ended — Start a new chat"** bar when the thread is `closed`.
- `handed_off` shows a banner above it: `assistant.handed_off_banner` with the ticket number. The
  composer stays enabled.

### Sending a turn (the core flow)
1. The user taps send (or a chip / slot / starter).
   - The cubit validates via `AssistantPrompt`.
   - An **optimistic user bubble** appears at once (local id, `sending`).
   - The composer clears; a **thinking** indicator appears.
   - One `SendAssistantMessageUseCase` stream subscription is opened.
   - Re-entry guard: a second send while streaming is ignored.
2. `message_start`: store the `conversationId`. If there was a different current id → the old thread
   was closed. Insert a local divider "New chat started" and continue in the new thread.
3. `user_message`: swap the optimistic bubble for the server message (keep its position, no animation).
4. `tool_start` / `tool_end`: the status line under the thinking bubble shows the **latest running**
   tool's label. It clears when no tool is running. `ok:false` is silent.
5. `text_delta`: appended to the live text. Rendered with a streaming caret.
6. `block`: appended to the live turn's cards, shown under the text in canonical order (L4).
7. `message_end`: the live turn is replaced **in place** by the hydrated message (text + cards +
   chips).
   - The caret disappears; the chips animate in.
   - Thumbs become available (the message now has an `_id`).
   - Stream closed.
8. `error` (terminal): keep the streamed text/cards, mark the turn `failed`, show an inline error
   row (message as sent) with **Retry**.
   - Retry re-sends the same user text as a new turn. The server already stored the first user
     message, so the reload shows both.
   - `RESOURCE_NOT_FOUND` with a conversation id → drop the id + offer "Start a new chat".
9. **Stop** (user):
   - Cancel the subscription, which cancels the HTTP request.
   - Keep the partial text, marked `assistant.stopped`.
   - The server may still finish and save the reply, so the next open of this thread re-reads it
     (no local merge).
10. **Transport drop mid-stream** (no terminal event): same as `error` with `core.no_internet` /
    generic text. Never re-POST automatically (it would duplicate the message).
11. **Pre-stream failure** (L8, 401, 429 after retries, offline):
    - The optimistic bubble turns `failed` with a retry icon; the text returns to the composer
      only if it is empty.
    - `UnauthorizedFailure` → the sign-in prompt state.
12. Leaving the page while streaming cancels the subscription (`close()`).

### Cart proposals (`cart_action`)
- The card shows, from `items[].product` when present:
  - each item's thumbnail, name, `× quantity`;
  - `estimatedTotal` (as sent; omit when absent);
  - a status-dependent footer:
    - `pending` → primary **Confirm** button (`AppButton`, busy while confirming). There is no
      reject route, so the user simply ignores it.
    - `confirmed` → success row "Added to your cart" (the confirm reply's `message` as sent) +
      "View cart".
    - `cancelled` / `expired` → muted row `assistant.action_cancelled` / `assistant.action_expired`,
      no button.
- **Confirm** → `ConfirmAssistantActionUseCase(actionId)`:
  - One in flight per `actionId` (a `Set<String>` guard in state). A double tap sends one request.
  - On success, replace that `actionId`'s block wherever it is in the thread with the returned
    `cart_action`, and insert the other returned blocks (typically `cart_summary`) right after it
    in the same message.
  - Bump `state.cartRevision`. The page `BlocListener` calls `context.read<CartCubit>().refresh()`
    (`Future<bool>`: `true` when the server snapshot came back), which updates the badge and home
    steppers. The refetch is needed because the server cart changed outside the local mirror.
    Nothing else in the assistant reads or fetches the cart: the app-bar badge reads `CartCubit`
    state, and the summary card shows the block's snapshot. **Never** call the app-root lifecycle
    hooks `onSignedIn` / `onSignedOut` / `onGuestSession` / `onLocaleChanged` / `onOrderPlaced`.
  - **Never** call `/v1/cart` mutations for a proposal.
- Confirm failures:
  - `NotFoundFailure` (L7) → mark the card `expired` locally + snackbar
    `assistant.action_unavailable`.
  - `UnauthorizedFailure` → sign-in prompt.
  - Others → the card stays `pending` + snackbar (`failure.localizedMessage`).
- Product cards inside the chat add through the **normal** `CartCubit.addCatalogProduct` (they are
  catalogue tiles, not proposals), with `FlyToCart` into the app-bar cart icon.

### Suggestions, feedback, copy
- **Chips:**
  - Only the **latest** assistant message's `actions` chips are interactive. Older ones render
    muted / hidden.
  - Tapping sends `prompt` and hides that chip row.
- **Thumbs up / down** under each persisted assistant message:
  - Optimistic toggle; tapping the active one clears it (`null`).
  - One request in flight per message; the last tap wins (per-message generation).
  - Roll back + snackbar on failure.
  - Initial state = `message.feedback` from the server.
- **Long-press a bubble** → `showJameiaBottomSheet` with **Copy** (`Clipboard` + snackbar
  `assistant.copied`).

### Handoff ("Talk to a person")
- The overflow item opens a confirm dialog (`showJameiaDialog`).
- On confirm → `RequestAssistantHandoffUseCase(conversationId)` with an **empty body**. Never guess
  `category` / `subcategory` values.
- Busy + double-submit guard.
- Success:
  - status → `handed_off`;
  - banner with `ticketNumber`;
  - a local `handoff` card appended if the server's thread doesn't already have one;
  - snackbar with `results.message` as sent.
- Failure → snackbar.
- **Mock only during development** (see CONTEXT).

### History (`Routes.assistantHistory`)
- Paginated `GET /conversations` (`limit` 20):
  - infinite scroll with a re-entry guard + generation counter (drop stale pages);
  - pull-to-refresh with `BrandedRefresh`;
  - the five screen states (loading skeleton, list, empty with "Start a chat", error + retry,
    signed-out).
- Row: title (1 line), `lastMessagePreview` (2 lines), relative time from `lastMessageAt`, and a
  status chip for `handed_off` / `closed`. `messageCount` is not shown (L12).
- Tap → `context.pop(conversationId)`. The chat cubit loads that thread (`GET /conversations/{id}`).
- No search (L11), no delete / rename (no API).

### Session, locale, lifecycle
- **Sign-in / sign-out:** the chat is page-scoped, so it is rebuilt after `context.go(Routes.login)`.
  - `AssistantAvailabilityCubit` keeps its memoized flags (they don't depend on the session).
  - A conversation id taken from a guest session stays valid after sign-in (the server merges it).
    If the server answers L9, the "new chat" path handles it.
- **Locale change** while the chat page is open: a `BlocListener<LocalizationCubit>` on the page
  (pushed pages don't rebuild by themselves) reloads the thread, because names are resolved
  server-side. The reload is deferred until the current turn ends.
- **App to background during a turn:** nothing special. If the OS kills the socket, the drop path
  applies.

### Edge cases (must all be handled)
- An empty text block or `content` → no empty bubble.
- A message with only cards → cards without a text bubble.
- A reply over 8000 chars → the bubble wraps (no max height).
- Text scale 1.3 → no overflow in chips or cards.
- RTL:
  - bubbles align to the correct side;
  - rails scroll from the start edge;
  - slide-in offsets are mirrored.
- A product with `stock` 0 → the card's unavailable overlay (existing).
- A `products` block with 1 item → a rail of one (no stretched card).
- More than 20 products → the rail stays lazy (`ListView.builder`).
- A thread with 100+ messages → still smooth (lazy list; images cached at display size).
- Unknown block kind (the mock sends `future_card`) → dropped, the rest of the message renders.

---

## ANIMATIONS & MOTION

Rules for every animation (CLAUDE.md §7 + the existing `core/motion` layer):
- **Timing:** durations and curves only from `AppMotion`. Implicit animations get
  `duration: MotionGuard.duration(context, …)`. Explicit controllers early-return (value = 1) on
  `MotionGuard.reduced(context)`.
- **Performance:**
  - one `AnimationController` per widget, disposed;
  - `RepaintBoundary` around each animated card / bubble and the live turn;
  - never an `AnimatedBuilder` around the list.
- **Direction:** offsets are directional. Mirror the x-offset when `context.isRtl`, because
  `SlideTransition` offsets are not directional.
- **Animate once.** A message animates only when it first appears **in this session's live flow**.
  - History loaded from `GET` does not animate, except the first-page stagger in the history list.
  - Items re-mounted by list recycling never re-animate.
  - The `message_end` swap must be visually static apart from the caret leaving and the chips
    arriving.
- **Haptics** through `Haptics` (it respects `Haptics.enabled`):
  - tap on send (via `PressScale`);
  - `success` on a confirmed cart action;
  - `warning` on a failed turn;
  - `selection` on thumbs.

| Element | Motion | Built from | Token | Reduced motion |
|---|---|---|---|---|
| Chat page open | full-screen slide-up | `JameiaSlideUpTransitionPage` | existing | instant (existing) |
| History page | standard push | `JameiaTransitionPage` | existing | instant |
| Home entry button | press scale + one soft "breathe" pulse of the icon (scale 1→1.08→1, 2 cycles) when home first appears per app run | `PressScale` + small controller | `AppMotion.breathe`, `signature` | no pulse |
| Welcome hero | icon pops in; title/body/chips stagger up | `PopScale.onMount`, `StaggerEntrance` (index 0..5) | `medium`, `emphasized`; stagger 30 ms | static |
| Starter / suggestion chips | stagger in from the start edge (mirrored in RTL); press scale; the tapped row fades out | `StaggerEntrance(beginOffset: ±0.08,0)`, `PressScale`, `AnimatedOpacity` | `medium`, `fast` | static |
| User bubble (send) | rises from the composer: fade + slide-up 0.3 + scale 0.96→1, anchored to the end edge | new `AssistantBubbleEntrance` (feature widget) | `medium`, `emphasizedDecelerate` | static |
| Thinking indicator | incoming bubble with three pulsing dots | `BrandedDotLoader(size, color: AppColors.primary)` | built-in | built-in static |
| Tool status line | label cross-fades + slides when the tool changes | `AnimatedSwitcher` (keyed by tool name) | `fast`, `signature` | instant swap |
| Streaming text | text grows at the flush cadence (no per-character animation); a blinking caret at the end, removed at `message_end` | `AssistantStreamingCaret` (one repeating controller) | `slow` blink | caret hidden |
| Live cards (`block`) | each card enters with fade + slide-up 0.08 + scale 0.98→1, staggered within the turn | `StaggerEntrance` (index = card index, maxIndex 6) | `medium`, stagger 40 ms | static |
| Product rail items | stagger in horizontally on first appearance only | `StaggerEntrance` | `medium`, 30 ms | static |
| Add from a chat product card | thumbnail flies to the app-bar cart icon; badge pops | `FlyToCart.flyFrom` + `PopScale(popKey: itemCount)` | `slow`, `emphasized` | no flight; badge updates |
| Cart proposal: confirming | button shows the busy loader | `AppButton(loading: true)` | existing | same |
| Cart proposal: confirmed | footer cross-fades to the success row; check icon pops; card border tweens to `success`; optional `BrandMoment(kind: addOnDone)` | `AnimatedSwitcher`, `PopScale`, `AnimatedContainer` | `medium`, `emphasized` | instant |
| Cart proposal: expired / cancelled | footer cross-fades to the muted row; card desaturates (opacity 0.6) | `AnimatedSwitcher`, `AnimatedOpacity` | `medium` | instant |
| Suggestion chips at `message_end` | fade + slide in after the swap (the only visible change at the swap) | `StaggerEntrance` | `medium`, 30 ms | static |
| Thumbs | selected icon pops (1→1.2→1) + colour tween; the other icon fades out partially | `PopScale(popKey: feedback)`, `AnimatedDefaultTextStyle` / `TweenAnimationBuilder<Color?>` | `microPop`, `fast` | instant |
| Failed turn | error row slides in; send button does a short horizontal shake (4 dp, 2 cycles) | `StaggerEntrance` + new generic `core/motion/shake_x.dart` (reusable, e.g. OTP) | `medium` | no shake |
| Send ↔ Stop button | icon morph: scale + rotate cross-fade; colour tween `divider` → `primary` when text exists | `AnimatedSwitcher` + `AnimatedContainer` | `fast`, `emphasized` | instant |
| Composer height | grows / shrinks with line count | `AnimatedSize` | `fast`, `signature` | instant |
| App-bar subtitle | "ready" ↔ "typing…" swap | `FlipValue(flipKey: isStreaming)` | `flip` | instant |
| Jump-to-latest button | appears when scrolled up > threshold; scale + fade | reuse `ScrollToTopFab` if its icon/offset fit a reversed list, else a small feature widget with the same pattern | `fast` | instant |
| Handoff banner | slides down from the top of the composer area | `AnimatedAccordion` / `AnimatedSize` | `medium` | instant |
| FAQ block rows | expand / collapse | `AnimatedAccordion` | existing | instant |
| Thread / history loading | shimmering skeleton bubbles / rows | `Skeletonized` + `SkeletonBone` (new `AssistantThreadSkeleton`, `AssistantHistorySkeleton`) | `shimmer` | solid (built-in) |
| History list first page | rows stagger in | `StaggerEntrance` (maxIndex 10) | 30 ms | static |
| Snackbars / sheets / dialogs | existing helpers | `showJameiaSnackBar` / `showJameiaBottomSheet` / `showJameiaDialog` | existing | existing |

New motion code (and nothing else):
- `AssistantBubbleEntrance`, `AssistantStreamingCaret` and the Home-button pulse live in the
  assistant / home widgets.
- `ShakeX` goes to `core/motion/` with a widget test and an export in `motion_widgets.dart`.

Do not add Lottie / GIF assets or packages (`pubspec.yaml` is out of scope).

---

## REQUIREMENTS

- **Clean Architecture** per CLAUDE.md §1–§4, build order §0.2, templates §5 + `layer-templates.md`.
  The data flow is Widget → Cubit → UseCase → Repository → DataSource → `ApiConsumer` /
  `EventStreamClient`.
- **Core: one-shot POST stream.** `EventStreamClient` gains
  `Stream<ServerSentEvent> send(String path, {Object? data})`. Keep `connect` (GET) **byte-identical**:
  notifications depend on it and its tests must pass unchanged.
  - `POST` over the shared Dio (Bearer, refresh, guest header, `Accept-Language`, debug trace all
    apply), `ResponseType.stream`, `Accept: text/event-stream`.
  - **No reconnect and no replay.** A 401 replay by `AuthInterceptor` and a 429 retry happen before
    the server accepts the message, so they are safe.
  - The stream completes when the server closes.
  - A mid-stream break → one `NetworkException` error, then done.
  - A one-shot idle watchdog (named constant, e.g. 60 s with no bytes) → `RequestTimeoutException`.
  - A non-2xx response: read the (stream) body, decode the envelope, and throw the typed
    `AppException` through `ApiExceptionMapper` with `code` (L8). Unit-test 400
    `VALIDATION_ERROR`, 401, 429, 5xx.
  - Cancelling the subscription cancels the request.
  - Tests go in `test/core/network/event_stream_client_test.dart`.
- **Domain (pure Dart):**
  - `AssistantBlock`: a **sealed** class with one subclass per kind (§API SPEC table).
  - `AssistantStreamEvent`: sealed (`started`, `userMessage`, `textDelta`, `toolStarted`,
    `toolFinished`, `block`, `completed`, `failed`).
  - `AssistantLiveTurn` with a pure `apply(event)` fold. This is the business logic of the stream:
    canonical order L4, tool set, failed / stopped states. It is unit-tested exhaustively.
  - `AssistantThread` (conversation + messages): `replaceLive(message)`,
    `replaceCartAction(actionId, blocks)`, `withFeedback(messageId, value)`,
    `latestSuggestionsMessageId`.
  - `AssistantPrompt.validate` (trim, 1..2000).
  - `AssistantRichText.parse(text)`: paragraphs, `-`/`*`/`1.` lists, `**bold**`. It is a pure parser
    run in the cubit / entity, never in `build`. Links render as plain text (the project has no
    `url_launcher`).
  - `AssistantErrorCode` constants for in-band `error.code` strings (`RESOURCE_NOT_FOUND`,
    `INTERNAL_ERROR`); branching on in-band codes is domain logic. `ApiStatus` is still not
    importable in domain/presentation (§12 gap): do not work around it.
- **Use cases** (one per operation, `Params extends Equatable` in the same file):
  - `GetAssistantAvailabilityUseCase`
  - `GetAssistantConversationsUseCase` (page, limit)
  - `GetAssistantConversationUseCase` (id)
  - `SendAssistantMessageUseCase` (`StreamUseCase<AssistantStreamEvent, SendAssistantMessageParams>`)
  - `ConfirmAssistantActionUseCase`
  - `RequestAssistantHandoffUseCase`
  - `RateAssistantMessageUseCase`
- **DTOs:**
  - Key constants, `is` checks, `ApiPayload.asMap(results, route)`.
  - `ParsingException` on a missing `_id` / `conversationId` / `actionId`.
  - Unknown enum values → `other`.
  - A malformed block, list row or stream frame is logged under the model's name and **skipped**:
    one bad card never drops the message, and one bad frame never kills the turn.
  - Frames are parsed with `.expand(_parseFrame)` (0 or 1 event per frame).
- **Reuse, never re-declare:**
  - core: `ProductModel` / `CatalogProductEntity` / `CatalogProductMapper`,
    `CategoryModel` / `CatalogCategoryEntity`, `BrandModel` / `BrandEntity`,
    `RecipeSummaryModel` / `RecipeSummaryEntity`, `OrderStatus` + `OrderMapper.orderStatusOf`,
    `JsonRead`;
  - widgets: `CatalogProductCard`, `CatalogRecipeCard`, `JameiaImage`, `AppButton`,
    `AppOutlineButton`, `TagChip`, `PriceText`, `ErrorView`, `EmptyStateView`, `SignedOutView`,
    `BrandedRefresh`, `AppLoader`, `Skeletonized` / `SkeletonBone`, `AnimatedAccordion`.
- **Shared ENTITIES move to core; DTOs stay in their feature's `data/`** (CLAUDE.md §4: only
  entities cross layers, and "shared" means a second real consumer exists). Each move is
  behaviour-preserving, keeps the owner's tests green, and is **done or reviewed by the owning
  session** (check `ListAgents`; on 2026-09-24 cart / checkout / orders belonged to keeta-clone-17):
  - **Cart: move nothing.** `features/cart/data/models/*` (incl. `cart_mirror_model.dart`, the
    persisted `cart.mirror.v1` contract of the offline-first mirror) and `cart_mapper.dart` stay
    private to cart. The assistant parses only what its card shows into its own
    `AssistantCartSnapshot`. The real cart state always comes from `CartCubit.refresh()`. If a
    cart entity accessor is missing, ask the cart owner for it.
  - **Delivery slots:** move `DeliverySlotEntity` + `DeliverySlotDayEntity` **together** to
    `core/domain/entities/` (the assistant is the second consumer). `DeliverySlotDayModel` + its
    mapper stay in checkout's `data/`. The assistant maps the block with its own small DTO onto
    the core entities.
  - **Offers:** move `OfferEntity` (+ `OfferTriggerType`) to core, unifying with the existing core
    `OfferRewardType` (`offer_reward_entity.dart`). If the two unions differ, stop and report
    instead of guessing. `OfferModel` / `OfferMapper` stay in marketing. The assistant maps its
    block with its own DTO onto the core entity.
  - An assistant DTO for a block may parse **only the fields its card renders**; nested product /
    category / brand / recipe rows reuse the core models listed above.
- **State:** one immutable Equatable state per cubit + `SafeCubitMixin`.
  - `AssistantChatState`: `status`, `thread`, `liveTurn?`, `isStreaming`, `failure?` (transient) +
    `failedAction`, `confirmingActionIds`, `ratingMessageIds`, `isHandingOff`, `cartRevision`.
    The composer text lives in the widget's `TextEditingController` (UI state), not in the cubit.
  - `AssistantHistoryState` mirrors `NotificationsState`.
  - `AssistantAvailabilityState`: `status`, `allowGuests`.
- **Cubits:** use cases only, `required this._x` constructor injection.
  - `AssistantChatCubit` owns the stream subscription and cancels it in `close()`.
  - The cart refresh happens through the page listener on `cartRevision` (a cubit never calls
    another cubit).
- **DI:** `assistant_injection_container.dart` → `initAssistantFeature()` (idempotent), called from
  `_initFeatures()`.
  - Datasource / repository / use cases → `registerLazySingleton`.
  - `AssistantChatCubit` / `AssistantHistoryCubit` → `registerFactory`.
  - `AssistantAvailabilityCubit` is built by `AppGlobalCubits` and provided in `app.dart`. Add it
    to the CLAUDE.md §4 app-global list (home and account read it through `BlocSelector`).
- **Routes:**
  - `Routes.assistant` = `/assistant` (`JameiaSlideUpTransitionPage`, extra `AssistantChatArgs?` in
    `config/routes/route_args/`).
  - `Routes.assistantHistory` = `/assistant/history` (`JameiaTransitionPage`).
  - Both go in `feature_routes/assistant_routes.dart` + `app_router.dart`, with
    `test/app_router_test.dart` coverage.
- **i18n.** Every key goes in **both** `assets/i18n/en.json` and `ar.json` under `assistant.*`:
  - titles, subtitles, welcome, starters (label + prompt), composer, send / stop / stopped,
    thinking, tool labels (L17 + generic), action states, estimated total, view cart;
  - errors, chat ended / new chat, handoff dialog + banner, copy / copied, jump to latest, history
    empty, status chips, slot prompt template, delivery info labels, semantics labels.
  - **Insertion trap:** other sessions append keys concurrently. Re-read both files right before
    editing, and insert by tracking brace depth from the `"assistant": {` block header, never by a
    string match that could land in another block.
- **Mock API:** new `.claude/skills/jameia-api-verify/scripts/mock_api/assistant.js`, plus ONE
  require / dispatch line in `server.js` (re-read `server.js` first; another session edits it).
  - All 6 routes, guest vs Bearer ownership.
  - Word-by-word deltas at ~10 ms, a `: connected` comment, and a heartbeat comment every 15 s.
  - Keyword-scripted replies that produce **every** block kind + an unknown `future_card` + tool
    events.
  - Confirm → `cart_summary` + `cart_action{status: confirmed}`; a second confirm → 404.
  - Handoff → ticket.
  - Admin knobs: `/__admin/assistant/{fail-persist (L7 terminal error after blocks),
    error-frame, drop-mid-stream, slow (N ms before first token), closed (next send returns a new
    conversationId), disabled, guests-off (401 AUTHENTICATION_REQUIRED), rate-limit (429),
    validation}`.
- **Record:**
  - `docs/api_integration.md` §6.1 row + `references/backend-contract.md` status (assistant → on
    the API, with L1–L20 as contract notes);
  - CLAUDE.md §1 feature list, §3.2 "On the API today", §4 app-global cubit list, and remove the
    §12 "`EventStreamClient` is `GET` only" gap;
  - the `jameia-api-streaming` skill "Limits" section (document `send`).

---

## PERFORMANCE REQUIREMENTS (gated by `flutter-performance-reviewer`)

- **Delta coalescing.** The cubit buffers `text_delta`s and emits at most once per
  `AssistantChatCubit.streamFlushInterval` (named constant, 50 ms), plus an immediate flush on
  `block`, `tool_*`, `message_end` and `error`.
  - Target: ≤ 20 emits/s while streaming, whatever the delta rate (L3). Add a cubit test that
    feeds 100 deltas in 100 ms and asserts the emit count.
  - Rich-text parsing runs on flush (≤ 8000 chars), never in `build`.
- **Narrow rebuilds:**
  - The live turn is its own widget under `BlocSelector<…, AssistantLiveTurn?>`. History bubbles
    select their own message.
  - The composer, app-bar subtitle, cart badge and handoff banner each select their single value.
  - A delta rebuilds **only** the live bubble, never the list or the composer.
- **List:**
  - One `ListView.builder` / `CustomScrollView` with `reverse: true` (newest at the bottom, sticks
    to the bottom while streaming).
  - `findChildIndexCallback` + `ValueKey(message.id)`.
  - `RepaintBoundary` per item.
  - The viewport must **not jump** while the user reads older messages during a stream (stick to
    the bottom only when already within the threshold of it).
- **Rails:** horizontal `ListView.builder` with a fixed extent from `CatalogProductCard.cellHeight`
  (text-scale aware).
- **Images:** `JameiaImage` with `memCacheWidth/Height` = `context.cacheCapFor(displaySize)`; no
  full 600 px decodes for 130 dp cards.
- **No platform views in the list:** `locations` render as tiles, not an inline `GoogleMap`.
- **Network:**
  - chat open = at most 1 request (`limit=1`) for a new chat, 1 for a resumed thread;
  - no polling; availability memoized per run;
  - history paged at 20; no refetch of a thread after `message_end` (the hydrated message is the
    truth);
  - confirm / feedback / handoff each guarded against double fire;
  - cart refresh = one `GET /v1/cart` per confirmed action.
- **Lifecycle:** the stream subscription and the caret / pulse controllers are cancelled / disposed.
  Nothing keeps running after the page pops (verify with DevTools; no `setState` after dispose).
- `const` constructors everywhere possible. Entities and states are Equatable, and no identical state
  is emitted.

---

## UI GUIDELINES

- **One widget per file** (private ones too), ~120–150 lines max, no `Widget _buildX()` helpers.
  Sub-folders: `widgets/chat/`, `widgets/composer/`, `widgets/blocks/` (one file per block kind +
  a `AssistantBlockView` switch on the sealed type), `widgets/welcome/`, `widgets/history/`.
- **Pages** compose, provide cubits (`sl<AssistantChatCubit>()..open(args)`), switch on state,
  listen (`cartRevision` → `CartCubit.refresh()`, failures → snackbar, `LocalizationCubit` →
  reload) and navigate. No parsing, ordering or validation in widgets.
- **Bubbles:**
  - User: end-aligned, `primary` background, `brandForeground` text, radius `SuiRadius.bubble`
    with a small tail corner on the end side (`BorderRadiusDirectional`).
  - Assistant: start-aligned, white, `AppShadows.low`, full width minus a start inset (cards need
    the width).
  - Max bubble width ~80% on phones; clamp content width with `ContentClamp` on tablets.
- **Tokens only.** No inline numbers except `0` / `double.infinity`. Tap targets ≥
  `SuiSize.minTouchTarget` (48).
- **Accessibility:**
  - every icon button has a translated `Semantics` / `tooltip`;
  - the finished assistant message is a `Semantics(liveRegion: true)`. The live, streaming bubble
    is not (it would spam the screen reader);
  - the thinking / tool line has a label.
- **Navigation** via `Routes` + GoRouter only; route extras are primitives or args classes (never
  DTOs). Sheets, dialogs and snackbars via the `showJameia*` helpers.
- Test at 320 dp width, text scale 1.3, Arabic (RTL), and with reduced motion on.

---

## ARCHITECTURE GUIDELINES (gated by `flutter-architecture-auditor` + `flutter-clean-code-reviewer`)

```
lib/src/features/assistant/
├── assistant_injection_container.dart
├── data/
│   ├── datasources/assistant_remote_data_source.dart   # ApiConsumer + EventStreamClient; METHOD /v1/path doc per method; memoized init read
│   ├── models/        # conversation, conversations page, message, block (+ per-kind small models), stream event, action result, handoff ticket, availability
│   ├── mappers/       # toEntity()/toEntities(); reuse core product/category/brand/recipe/order-status mappers
│   └── repositories/assistant_repository_impl.dart     # with BaseRepositoryMixin: execute(...) / guardStream(...)
├── domain/
│   ├── entities/      # sealed AssistantBlock, sealed AssistantStreamEvent, AssistantMessageEntity, AssistantConversationEntity,
│   │                  # AssistantThread, AssistantLiveTurn, AssistantConversationsFeed, AssistantOrderSummary, AssistantCartSnapshot, AssistantPrompt,
│   │                  # AssistantRichText, AssistantAvailability, AssistantActionResult, AssistantHandoffTicket, AssistantErrorCode
│   ├── repositories/assistant_repository.dart          # Either for request/response, Stream<AssistantStreamEvent> for send
│   └── usecases/      # the 7 use cases above
└── presentation/
    ├── cubit/         # assistant_availability_{cubit,state}, assistant_chat_{cubit,state}, assistant_history_{cubit,state}
    ├── pages/         # assistant_chat_page.dart, assistant_history_page.dart
    └── widgets/       # chat/ composer/ blocks/ welcome/ history/
```

- **Dependency direction** inward only (§2).
  - The remote datasource depends on `ApiConsumer` + `EventStreamClient` only and returns DTOs.
  - The repository maps DTO → entity inside `execute` / `guardStream`.
  - The domain imports no Flutter, `dio` or `easy_localization`.
- **Cross-feature:**
  - assistant presentation may import only app-global cubits: `CartCubit`, `AuthSessionCubit`,
    `LocalizationCubit`;
  - home / account import only `AssistantAvailabilityCubit`;
  - never another feature's widgets or pages. Navigation goes through `Routes`.
- **Session-bound work:** none needed beyond the existing guest-key handling. Do not add assistant
  logic to `app.dart` other than providing `AssistantAvailabilityCubit`.
- **Hard rules:** no `sl` outside DI / pages, no `print`, no `// ignore:` for `architecture_lints`,
  no new `analysis_options.yaml` excludes, no deleted tests. No edits to `pubspec.yaml`,
  `android/**`, `ios/**`, or `features/support/**`.

---

## EXECUTION ORDER

Work one phase at a time in the main session (no parallel build agents; read-only Explore agents are
fine). Each phase ends green before the next starts.
- **RAM is tight and other sessions run tests.** Message the active sessions before
  `dart analyze` / `flutter test`.
- `flutter test` may be red in areas other sessions own. Report those failures separately; do not
  fix them.

0. **Contract + mock.**
   - Re-read the routes (`openapi_route.js assistant`).
   - Build `mock_api/assistant.js` + knobs.
   - Replay one probe against the mock with `assistant_sse_probe.js` (`BASE=http://127.0.0.1:<port>`;
     a peer often holds :5055 → `MOCK_API_PORT=5056`).
1. **Core stream.** `EventStreamClient.send` + tests. The GET tests are unchanged and green.
2. **Domain.**
   - Entities (sealed blocks / events), `AssistantLiveTurn.apply`, `AssistantThread` operations,
     `AssistantPrompt`, `AssistantRichText`, use cases.
   - Tests: every event order incl. L4 / L5 / L7 / L9, stop, closed-thread switch, parser cases,
     validation bounds 0 / 1 / 2000 / 2001.
3. **Entity moves to core** (slot + offer entities only; the checkout owner does or reviews the slot
   move; see REQUIREMENTS). Owners' tests stay green. No cart file moves.
4. **Data.**
   - DTOs (all 18 kinds + unknown drop + a malformed card skipped), mappers, datasource,
     repository.
   - Tests: DTO / mapper round-trips from the **real live captures already saved** in
     `test/features/assistant/fixtures/live_2026_09_24/` (6 SSE turns incl. the L7 error in EN + AR,
     detail, list, confirm 404; see its README), plus mock fixtures for the kinds the live store
     did not produce, datasource on `FakeHttpClientAdapter` +
     `FakeEventStreamClient`, repository failure mapping incl. stream errors → `Failure`.
5. **Cubits.** Availability, chat, history. `bloc_test` with gated fakes:
   - delta coalescing count;
   - double send ignored;
   - stop cancels;
   - drop mid-stream;
   - pre-stream 400 / 401;
   - L7 path, then a confirm 404 → expired;
   - confirm double tap → 1 call;
   - confirm success bumps `cartRevision`;
   - feedback optimistic + rollback + last-tap-wins;
   - handoff double submit;
   - history stale page dropped;
   - locale reload deferred until the turn ends.
6. **UI + motion.** Widgets per block, welcome, composer, history, entry points, routes, i18n,
   `ShakeX`.
   - Widget tests: page smoke per state; each block renders from a fixture; unknown kind ignored;
     reduced motion (`MediaQuery(disableAnimations: true)`) → no running tickers.
   - Router test for both routes.
7. **Verify on a device / emulator** (`jameia-api-verify` checklist).
   - Against the mock: every knob, reading the `api` / `sse` trace for each call (method, path,
     body, headers: Bearer vs `X-Assistant-Guest`).
   - Then ONE short guest session against the live host: send, products, chips, feedback, history;
     **no handoff**.
   - DevTools performance overlay while streaming: no jank frames on a mid-range device profile.
8. **Docs + status** (REQUIREMENTS → Record).
9. **Reviews.** Run in this order and fix every High / Medium finding before reporting; paste each
   verdict:
   - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-performance-reviewer.md`
   - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-architecture-auditor.md`
   - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-clean-code-reviewer.md`
   - then `pre-pr-guardian` (CLAUDE.md §10)

---

## ACCEPTANCE CRITERIA

- **Entry points:** the Home header button and the Mine row appear only when `/v1/init` says the
  assistant is enabled. Signed out with guests allowed → chat works with `X-Assistant-Guest` and no
  Bearer (trace). Guests off → sign-in prompt → `context.go(Routes.login)`.
- **Streaming:**
  - one `POST /v1/assistant/messages` per send (never re-sent automatically; the trace shows exactly
    one per turn, including on drop / error);
  - the user bubble appears instantly;
  - thinking → tool label → streamed text with caret → cards → chips at `message_end`, with no
    reflow at the swap (L4);
  - ≤ 20 state emits per second while streaming (test).
- **Every block kind** renders from the live / mock fixtures:
  - `delivery_info` with no fields is hidden;
  - an unknown kind is ignored;
  - each tap target opens the right route with the right extra (product slug, order `_id`, recipe
    slug, category / brand args, cart preview).
- **Cart proposal:**
  - Confirm sends one request even on double tap;
  - success → card `confirmed` + `cart_summary` shown + `GET /v1/cart` once + badge updated;
  - 404 → card `expired` + snackbar;
  - no `/v1/cart` mutation is ever sent for a proposal.
- **Failures:**
  - L7 (mock `fail-persist`) → streamed cards kept + inline error + Retry;
  - Stop keeps the partial text;
  - pre-stream 400 / 429 / offline → failed bubble + retry;
  - L9 / closed thread → "Start a new chat" / "New chat started" divider.
- **Chips:** only the latest message's chips are interactive; a tap sends `prompt` and shows `label`.
- **Feedback:** optimistic, toggles off to `null`, rolls back on failure, one request per tap burst.
- **Handoff (mock):** one request, banner with ticket number, status `handed_off`.
- **History:** paginated with all five states, stale page dropped; tap opens the thread; no
  search / delete UI.
- **Motion:** every row of the ANIMATIONS table implemented with the named building blocks and
  tokens. With reduced motion on, nothing animates and no ticker keeps running. RTL mirrors every
  directional slide. Nothing re-animates on scroll or at `message_end`.
- **Checks:**
  - `dart analyze` (repo root, no path) → 0 errors / 0 warnings in touched files, including
    `architecture_lints`;
  - `git status` shows no change under `lib/src/features/cart/**`;
  - `flutter test` → all assistant, core and moved-code tests pass; new tests for every use case,
    mapper, datasource, repository, cubit behaviour and the stream client listed above.
- **i18n:** keys in both `en.json` and `ar.json`, checked in Arabic on device.
- **Reviews:** performance, architecture and clean-code reviewers → no High findings open; verdicts
  pasted.
- **Docs:** CLAUDE.md, `docs/api_integration.md` §6.1, `backend-contract.md`, and the streaming
  skill updated.
- **Report** in the CLAUDE.md §0.9 shape. It must include the backend issues list (API SPEC →
  "Backend issues to report"), any new quirk found, and the optional PDP entry point's status.
