# Moving a legacy offline feature onto the API

Most features still read `JameiaRepository` / local persistence **and** predate the contract in
`CLAUDE.md` (§12): cubit → repository without use cases, repository impl with a hand-written
`try/catch → Left(CacheFailure)`, state with `String? error`, entities with `double` money and
pre-formatted strings. `features/orders` is the typical case. These rules decide what you do
when the recipe in `SKILL.md` meets such a feature.

## 1. Scope: the vertical slice of the operations you integrate

- You own every file you **modify**. A legacy file you touch is migrated to the contract
  (`CLAUDE.md` §12 "migrate it when you own the file"); files you do not touch stay as they are
  and go into your report under "Risks / open issues".
- Concretely, for the operations you integrate (say `getOrders` + `cancelOrder`):
  - repository impl → `with BaseRepositoryMixin`, **all** its methods through `execute`
    (mechanical, the file is yours now);
  - one use case per integrated operation; the cubit calls those. Other operations of the
    same cubit that still hit the repository directly are listed as remaining debt — unless
    converting them is a pure pass-through, then do it;
  - state: `Failure? failure` (transient) instead of `String? error`; add `isSignedOut`;
  - no cubit self-loading in its constructor **and** `..load()` in the page — pick the page.
- Two steps, in this order, each verified by itself:
  1. **behavior-preserving refactor** of the slice (still offline) — `CLAUDE.md` §0.4 applies:
     same screens, texts, navigation; tests written now pin the behavior;
  2. **swap the datasource** to the API — this is a requirement change (real data, loading /
     error / signed-out states appear); say so in the report under "Behavior changes".
- "0 warnings in the touched area" = no `architecture_lints` warning left in the files you
  modified or created. Pre-existing warnings in untouched files are not yours to fix now.
- No tests exist for most legacy features. Write them for the slice in step 1 (cubit +
  repository), then extend in step 2 (DTO, datasource, failure mapping) — `jameia-api-testing`.

## 2. Which entity

- Never extend a per-feature duplicate of a shared entity (`features/orders/domain/entities/order.dart`
  re-declares `OrderItemEntity` / `RiderEntity`; checkout and support carry their own order
  copies). Map the API DTO to the **core** entity (`core/domain/entities/`, e.g.
  `JameiaOrderEntity`), extending it when the API has a field the app needs.
- The API entity rules hold: money `int` fils, status as an **enum with an `other` case**,
  `DateTime` instead of pre-formatted date strings, no invented data (fake ETA / rider hashed
  from the id). Widgets that consumed a `double` read an `…Kd` getter; date / status text is
  resolved in the widget (`Formatters`, `.tr()`), not stored in the entity.
- Screens that still use the legacy entity keep working through a small mapper **in the data
  layer** only if they are outside your slice; otherwise migrate them — never two entity types
  for the same thing in one screen flow.

## 3. Never mix id spaces

An API list returns Mongo ids. Every screen reachable **from that list by id** (details,
tracking, invoice, review, refund, reorder) must read the API too, or every tap ends in
"not found" against the offline catalogue. So migrate a list together with everything that
opens from it — or keep the whole flow offline until you can. Step 5 of the recipe ("behavior
the API cannot serve yet stays local") applies to independent operations only, never to a
detail lookup keyed by an id the list produced.

## 4. When the contract does not fit the API

- An aggregate contract (`getOrders() → OrdersView{active, history}`) over a paginated flat
  route: look for a filter first (`openapi_route.js` shows the query params). With a filter →
  one paged request per bucket, each with its own `page` / `hasMore`. Without → page the flat
  list and bucket it in the view entity; `hasMore` belongs to the flat list, and both tabs load
  more from the same cursor. Never fake per-tab pagination on the client.
- Changing a repository contract is allowed when the API forces it; do it deliberately: new
  params class, updated use case, updated cubit tests, and a line in the report.

## 5. Mutations (cancel, reorder, review …)

- Return what the API returns: the updated object → replace the row from it (`feed.replace`,
  like `NotificationsCubit.markRead`); nothing useful → `Either<Failure, Unit>`. No `bool`.
- **Optimistic only when the inverse is trivial and harmless** (mark read, toggle favourite).
  Irreversible or money-related actions (cancel an order, pay, delete an address, redeem
  points) **wait for the server**: an in-flight flag in state disables the button, success
  updates the row from the reply, failure leaves the row untouched and surfaces
  `failure.localizedMessage`. A swallowed `Left` with success UI is the legacy bug to remove.
- Record which call failed (`failedAction` enum, see `NotificationsState`) when the page must
  tell a full-screen error from a toast.
- Business refusals ("not cancellable any more") arrive as `ServerFailure` with a backend
  `code` and a localized message: show the message. Branching on the code is blocked today
  (`references/patterns.md` §10).

## 6. Screens that outlive a session change

Tabs of the shell live in an `IndexedStack`; their cubits are page-scoped, so `app.dart`
cannot reach them, yet they hold per-customer data.

- Today this is safe because every auth transition uses `go` (login replaces the stack, the
  shell is rebuilt after OTP). Keep it that way: **never `push` to login**.
- A screen that can stay mounted across a session change anyway (it sits beside a login
  sheet, a desktop layout …) listens to the app-global cubit in its **page**:
  `BlocListener<AuthSessionCubit, AuthSessionState>(listenWhen: (p, c) => p.isSignedIn != c.isSignedIn, listener: (context, _) => context.read<XCubit>().load())`.
  The cubit itself still never checks the session (`patterns.md` §6).
- App-global per-customer state (cart, badges) is reset from `app.dart`'s listener; a new
  app-global cubit gets a factory in `config/di/app_global_cubits.dart` and a provider in `app.dart`.

## 7. Tooling you are allowed to touch

Extending the mock API (`.claude/skills/jameia-api-verify/scripts/mock_api/server.js`) with the
routes of your feature is part of an integration task — additive only (new routes / knobs,
never changing existing replies), dependency-free, same envelope helpers. The same holds for
`references/backend-contract.md` (status table) and `docs/api_integration.md` §6.1. These are
the only shared files outside your feature that an API task edits without being told to;
`EndPoints`, `ApiStatus` additions are one-line appends in core and also expected.

## 8. Report

Besides the `CLAUDE.md` §0.9 shape: which operations are on the API now, which stay offline and
why, which legacy files you migrated, which you left (with the lint counts if you looked), and
every behavior change the real data introduced.
