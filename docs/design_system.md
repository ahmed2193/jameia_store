# JameiaMart design system (search, cart, checkout, orders)

The look of the **search** screens and the **cart → checkout → orders** flow. It follows
talabat's design language (flat surfaces, type-led hierarchy, one bold action colour, pill
actions, underlined links) with **JameiaMart's own colours** (logo green + yellow).

**Scope.** Only search and the cart / checkout / orders flow use this look today. The rest of
the app keeps its current widgets until an app-wide pass is approved. That is why two
families live side by side for now:

| New look (`core/widgets/`) | Older widget still used elsewhere |
|---|---|
| `JameiaStateView` (+ `.error`, `.signedOut`) | `EmptyStateView`, `ErrorView`, `SignedOutView` |
| `JameiaSecondaryButton` | `AppOutlineButton` |
| `JameiaSectionHeader`, `JameiaTextLink` | `SectionHeader` |
| `JameiaSummaryLine` + `JameiaMoneyText` | `SummaryRow`, `PriceText` |
| `JameiaTag` | `TagChip` |

When the app-wide pass is approved, swap the older widgets for the new ones and delete them.
Do not add new users of the older column.

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

Money, points and codes: `JameiaMoneyText` / `AppTextStyles.tabular`, one left-to-right run.

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
| Secondary pill (`compact` 44 dp for card actions) | `JameiaSecondaryButton` |
| Underlined link (`navigates: false` for in-page actions) | `JameiaTextLink` |
| Title bar (back only when the route can pop) | `JameiaTitleBar` |
| Section heading + link / trailing | `JameiaSectionHeader` |
| Row / grouped rows on a hairline card | `JameiaListRow` / `JameiaListCard` |
| Choice row with a trailing radio | `OptionRow` + `JameiaRadioMark` |
| Card (white hairline / muted / brand …) | `JameiaSurfaceCard` |
| Tag | `JameiaTag` |
| Money / breakdown line | `JameiaMoneyText` / `JameiaSummaryLine` |
| Pinned bottom bar | `JameiaBottomBar` |
| Sheet top (handle, title, ✕) | `JameiaSheetHeader` (+ its `shape`, white background) |
| Field look | `JameiaInputDecoration.outlined` |
| Empty / error / signed-out | `JameiaStateView` |

## 6. Motion

Everything goes through `MotionGuard` (reduced motion → the same end state, instantly) and
`AppMotion` tokens. Motion is **event-driven**: it plays once because the customer acted or
because a value or state changed while it was on screen.

Welcome: press feedback; colour cross-fades on selection; `FadeThroughSwitcher` between
loading, content and error; `RollingNumber` when a total or a quantity changes; rows that
grow in and fold away when added or removed; progress bars that fill to their new value; a
short pop and a haptic when a choice lands (radio, star, coupon applied); one celebration
when an order is placed; a status headline that cross-fades when the status moves.

Not allowed: ambient loops on a settled screen (floating, glowing, shining, pulsing
forever), count-ups on open, cascades on every rebuild, confetti anywhere but the order-placed
moment. Animated rows and totals sit in a `RepaintBoundary`.

## 7. Screen recipe

1. `Scaffold(backgroundColor: AppColors.white)` + `JameiaTitleBar` (pushed pages).
2. Content in 16 dp gutters; sections introduced by `JameiaSectionHeader`.
3. Rows on `JameiaListCard`; facts on `JameiaSurfaceCard`.
4. One primary action, pinned in `JameiaBottomBar` when it is the goal of the screen.
5. States: skeleton or `AppLoader` → content → `JameiaStateView`, swapped with
   `FadeThroughSwitcher` keyed by a status bucket (never by data that changes while shown).
6. Every string `.tr()` in en + ar, money LTR, RTL mirrored, text scale 1.3 without overflow.
