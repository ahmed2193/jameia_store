# Hero design system

The look of **every screen** of the app. It follows Hero's design language (flat surfaces,
type-led hierarchy, one bold action colour, pill actions, underlined links) with **Hero's own
colours** (logo green + yellow).

**Scope.** App-wide since the consistency pass of 2026-10-01: every pushed page, sheet,
dialog, state, list footer and form field uses the components of §5. The older family
(`EmptyStateView`, `ErrorView`, `AppOutlineButton`, `SummaryRow`, `PriceText`, `TagChip`) is
deleted; per-feature app bars, dialogs and sheet headers were folded into the shared ones.

Approved exceptions (keep them, do not "fix" them):

- **Checkout sheets** keep their Keeta frame (`CheckoutSheetFrame`: floating ✕, no handle).
- **Sign-in** pages are brand sheet pages (`BrandSheetScaffold`), not title-bar pages.
- **Home** keeps its header, shelves and popups (the home redesign), and the **Pro paywall**
  its own bottom bar.

## 1. Principles

1. **Flat and honest.** Solid fills and photos. No gradients, glows, neon or glass.
2. **Type does the work.** Heavy headings, regular copy, grey meta.
3. **One colour for action.** Brand green fills the one primary action per screen and
   shows active states. Everything else is ink on white.
4. **Pills for actions and tags; underlined text links.**
5. **White space.** 16 dp gutter, 24 dp between sections, 16 dp inside cards.
6. **Motion that answers the customer.** Things move because the customer did something
   or because something changed for them — never on their own in a loop (§6).

## 2. Colour roles (`AppColors`)

| Role | Token | Use |
|---|---|---|
| Brand | `primary` #22C55E | primary CTA fill, switches, progress |
| Brand pressed | `primaryDark` #16A34A | selected radio / star, focused brand outline |
| Brand deep | `brandDeep` #15803D | brand text on white (AA): deals, discounts, "Free" |
| Brand wash | `brandLightBg` #DCFCE7 | tinted card, soft tag |
| Ink | `primaryText` | titles, body, icons, selected chip fill |
| Meta | `secondaryText` #808080 | meta lines, captions |
| Hairline | `divider` #EBEBEB | 1 dp borders and dividers |
| Muted | `smallBackground` | unselected fills, skeleton bones |
| Red text | `errorDeep` #BD2400 | red TEXT (AA); `error` stays for icons |

## 3. Type roles (`AppTextStyles`)

| Role | Size / weight | Use |
|---|---|---|
| `sectionTitle` | 20 bold | a page's lead heading |
| `groupTitle` | 18 bold | section / sheet / dialog title, bar totals |
| `barTitle` | 18 medium | title bar |
| `itemTitle` | 16 regular | list row, card title, body copy |
| `itemTitleStrong` | 16 medium | emphasised row, secondary button |
| `meta` | 14 regular grey | meta lines, helper text |
| `label` | 14 medium | links, chips, small buttons, summary values |
| `tag` | 12 bold | tags and badges |

Money, points and codes: `HeroMoneyText` / `AppTextStyles.tabular`, one left-to-right run.

## 4. Shape, spacing, elevation

- Radius: `AppRadius.pill` (buttons, chips) · `AppRadius.media` 16 (cards) ·
  `AppRadius.card` 12 (inputs, thumbnails) · `AppRadius.chip` 6 (tags) · `AppRadius.sheet` 24.
- Spacing: `AppSpacing.gutter` 16 · `AppSpacing.section` 24 · 16 inside cards.
- Elevation: flat. Cards have a hairline. Title bar `AppShadows.barBottom`; bottom action bar
  `AppShadows.barTop`.
- Tap targets ≥ 44 dp. Directional icons mirror in RTL.

## 5. Components (`core/widgets/`)

| Component | Widget |
|---|---|
| Primary pill (52 dp in bottom bars) | `AppButton` |
| Secondary pill (`compact` 44 dp for card actions) | `HeroSecondaryButton` |
| Underlined link (`navigates: false` for in-page actions) | `HeroTextLink` |
| Title bar (back only when the route can pop; `subtitle`, `titleLeading` avatar, `bottom` tab strip) | `HeroTitleBar` |
| Icon action in a title bar (48 dp, tooltip, disabled when `onPressed` is null) | `HeroBarAction` |
| Section heading + link / trailing | `HeroSectionHeader` |
| Row / grouped rows on a hairline card | `HeroListRow` / `HeroListCard` |
| Choice row with a trailing radio | `OptionRow` + `HeroRadioMark` |
| Card (white hairline / muted / brand …) | `HeroSurfaceCard` |
| Tag / order status | `HeroTag` / `OrderStatusChip` |
| Money / breakdown line | `HeroMoneyText` / `HeroSummaryLine` |
| Pinned bottom bar | `HeroBottomBar` |
| Confirmation (art or icon plate, title, message, stacked pills; `destructive` = deep red) | `showHeroConfirmDialog` → `bool` (`HeroConfirmDialog`) |
| Bottom sheet (white, 24 dp top corners by default) | `showHeroBottomSheet` |
| Sheet top (handle, title, subtitle, leading, ✕) | `HeroSheetHeader`; handle alone: `HeroSheetHandle` |
| Field look | `HeroInputDecoration.outlined`; a field with more than a `TextField` inside (code, picker, stepper): `HeroFieldShell` |
| Field label | `AppTextStyles.label` above the field; the refusal one `meta` line in `errorDeep` under it |
| End of a paged list (dots ↔ compact "Try again") | `NextPageSentinel` + `LoadMoreFooter` |
| Empty / error / signed-out / not found | `HeroStateView` (`FailureView` for a failed read) |
| A failed load, told by what went wrong | `HeroStateView.failure` / `FailureView`: the `StateIssue` (offline, store out of reach, timeout, server trouble, maintenance, too many tries, signed out, no access, not found, unreadable data, anything else) picks its own moving plate (`assets/svg/state_*.svg`, built by `tool/issue_art`), its title and words |

## 6. Motion

Everything goes through `MotionGuard` (reduced motion → the same end state, instantly) and
`AppMotion` tokens. Motion is **event-driven**: it plays once because the customer acted or
because a value or state changed while it was on screen.

Welcome: press feedback; colour cross-fades on selection; `FadeThroughSwitcher` between
loading, content and error; `RollingNumber` when a total or a quantity changes; rows that
grow in and fold away when added or removed; progress bars that fill to their new value; a
short pop and a haptic when a choice lands (radio, star, coupon applied); one celebration
when an order is placed; a status headline that cross-fades when the status moves.

Ambient motion (floating, glowing, sheen, rotating lines, the shelf glide) is a budget, not a
loop: it runs through `AmbientLoop` / `RotatingLine` only while on screen, in the foreground,
not under reduced motion, and stops after `AppMotion.ambientBudget` (5 s) per appearance.

One press language: cards, tiles, chips and pills = `PressScale` (0.97; round icon controls
0.92, `AppMotion.pressedScaleSmall`), silent unless the tap is a commit or a pick; list rows =
`PressRow` (a dip plus the flat brand tint); only the innermost press under a finger dips.
Segmented controls (`HeroSegmentedControl`, coupons tabs, Pro plans, cart / history) share
`SegmentedThumbTrack` (one thumb on `AppMotion.thumbSlide`, one selection haptic per change).

The shared components carry their own motion, so every screen moves the same way:
confirmation dialogs pop in on `AppSprings.snappy` from `AppMotion.dialogPopBegin` (0.8) and
leave by fading; sheet headers rise in with their content (`EntranceCascadeItem.single`, the ✕
pops); `HeroStateView` settles its art, then the words and the action rise a step apart (an
issue plate then acts its issue out, two laps at most inside the ambient budget, still under
reduced motion: `StateArtMotions`); a
title-bar title or subtitle that changes while shown flips (`FlipValue`); a field's outline
cross-fades on focus and refusal; a list footer swaps dots ↔ retry with `FadeThroughSwitcher`.
Reduced motion: the same end states, with fades or cuts only.

Not allowed: endless loops, count-ups on open (a count-up is only for a value the customer
just earned), cascades on every rebuild (`EntranceCascade` opens once per screen life),
confetti anywhere but a moment the customer earned (order placed, first add, Pro welcome).
Animated rows and totals sit in a `RepaintBoundary`. The system: `docs/motion/motion_design_system_2026.md`.

## 7. Screen recipe

1. `Scaffold(backgroundColor: AppColors.white)` + `HeroTitleBar` (pushed pages).
2. Content in 16 dp gutters; sections introduced by `HeroSectionHeader`.
3. Rows on `HeroListCard`; facts on `HeroSurfaceCard`.
4. One primary action, pinned in `HeroBottomBar` when it is the goal of the screen.
5. States: skeleton or `AppLoader` → content → `HeroStateView`, swapped with
   `FadeThroughSwitcher` keyed by a status bucket (never by data that changes while shown).
6. Every string `.tr()` in en + ar, money LTR, RTL mirrored, text scale 1.3 without overflow.
7. Asks before a destructive or paid action with `showHeroConfirmDialog`; an optimistic delete
   with Undo says so in its message (never "cannot be restored").
8. A signed-out screen signs in through `SignInFlow.open` (the state's `.signedOut` does it):
   once signed in — or "Continue as guest" — the customer lands back on that page or tab.
9. Nothing on screen leads nowhere: an entry whose backend is not built is hidden, not
   shown with fake data (invite friends, favourites, a support unread count).
