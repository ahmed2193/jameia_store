# Hero motion 2026 — asset manifest (Phase 5)

Date: 2026-09-28. Every asset is original: hand-authored SVG, or frames drawn in SVG and encoded with ffmpeg (two-pass palette). Brand colours only (`AppColors` hex), no text baked into in-app art, no embedded rasters. Wired on 2026-09-29 (backlog row BX-13, tasks I7 / I8 / I13): see "Wiring status" below.

- In-app SVGs: 38 new files, flat in `assets/svg/` (already bundled; no `pubspec.yaml` change). QA: 38/38 pass (viewBox, palette, no text/raster/metadata, < 10 KB; largest 1,499 B). Each was rendered on #F8FAFC and #FFFFFF and checked by eye.
- In-app GIFs: none. Animated art is specified as CustomPainter / primitive specs instead (section "Painter and primitive specs"), because a GIF cannot follow reduced motion, cannot pause off screen and decodes every frame on the CPU.
- Preview GIFs (docs only, never bundled): 37 files in `previews/<screen>/`, 12.22 MB total, largest 1.60 MB, 360 px wide, ≤ 30 fps. Each was checked frame by frame from a contact sheet.

## Update 2026-09-30: the icons and assets pass

Details: [`docs/assets/hero_icons_assets_2026.md`](../assets/hero_icons_assets_2026.md). Rows below this section still describe the state of 2026-09-29.

- **SVGs folded into the icon font.** The 5 mono SVGs are now glyphs in the `HeroIcons` font, and the SVG files are deleted:

  | Old SVG | New glyph |
  |---|---|
  | `tab_account` | `account` / `person` |
  | `assistant_ai` | `assistant` |
  | `recipe_pot` | `recipe` |
  | `product_options` | `options` |
  | `category_all` | `categoryAll` |

- **Last mono SVGs folded (R1).** `shared_clock`, `address_label_*`, `checkout_cash`, `checkout_code_tag`, `rewards_badge`, `status_offline` are deleted; they are the glyphs `clock`, `home` / `office` / `people` / `pin`, `cash`, `tag`, `medal`, `offline` (snack success → `checkCircleFill`). `status_success.svg` stays for the live map only. `HeroSvgGlyph.mono` is gone.
- **Icon names.** Every `HeroIcons.*` name and Material icon in the tables below is a pre-2026-09-30 name. Today's `HeroIcons` is our own font, and `tool/icons/concepts.tsv` maps each old name to its new one (for example `confirmReceipt` → `ordersDone`, `customerService` → `support`, `location` → `pinFill`).
- **Rasters extracted from the reference APK are gone:**

  | Old | Replaced by |
  |---|---|
  | `globalRider` | `HeroIcon(delivery)` |
  | `popupClose` | Hero close glyph on a dark disc |
  | Login social PNGs | Official brand marks (`assets/images/brands/`, `assets/svg/brand_*.svg`) |

- **Palette fixes.** `checkout_points`, `checkout_wallet` and `offer_voucher` now use only `AppColors` hexes.

## Wiring status (2026-09-29)

All 48 files in `assets/svg/` (38 new + 10 older) have a `HeroAssets` constant and a user in `lib/`
(guarded by `test/core/design/hero_assets_svg_test.dart`). Drawn glyphs go through `HeroSvgGlyph.mono`
(tinted) / `.art` (plates and stickers, never tinted); state plates through `StateArt`. No device run yet.

| Asset(s) | Wired to |
|---|---|
| `state_error`, `state_offline`, `state_signed_out` | `HeroStateView` (.error / .offline / .signedOut), `ErrorView`, `FailureView` |
| `image_placeholder` | `HeroImagePlaceholder` -> every `HeroImage` / `HeroNetworkImage` |
| `empty_shelf` | brands, categories, recipes, home empty, product listing empty |
| `empty_addresses` / `empty_ledger` / `empty_notifications` | address list / wallet + loyalty / notifications |
| `empty_coupons` | offers empty, every My coupons tab, cart deals empty |
| `empty_basket` | cart empty, checkout empty |
| `state_unavailable` | rewards, assistant off, Pro unavailable |
| `state_not_found` | content page, PDP not found, recipe not found, `PlaceholderPage` |
| `state_search_empty` | support help-topics no results |
| `state_success` | order rating thanks (`TrackingRateThanks`, compact) |
| `status_offline`, `status_success` | snack tone glyphs (`HeroSnackTone.offline` / `.success`) |
| `tab_account` | shell Mine tab, Mine guest avatar, notification "account", servings glyph |
| `pro_crown`, `pro_welcome` | Mine Pro row, cart nudge, home Pro banners, Pro member card, notification; Pro success sheet |
| `assistant_ai`, `recipe_pot`, `product_options`, `category_all` | Mine assistant row + home header disc + chat steps + buddy thoughts; recipe step; "choose options" add controls; "All" entry of the category rail |
| `shared_clock` | stale age pill, checkout ETA + timing sheet, cart ETA, recipe meta, chat steps |
| `address_label_home/office/gathering/other` | address rows, label chips, tracking destination |
| `cart_basket`, `cart_basket_full` | every basket bar badge, home min-order bar |
| `map_pin` | address-edit centre marker |
| `delivery_code_handover` | delivery code tips card (RTL-mirrored) |
| `rewards_badge` | rewards card backdrop |
| `offer_percent` and the `offer_*` plates | offers disc, cart deals, checkout vouchers, notification "offer" (`OfferPlate`) |
| `assistant_prop_bubble` / `_mic` / `_handoff` | assistant history empty / mic blocked dialog / handoff dialog + support card (`AssistantPropScene`) |
| `assistant_hold_to_talk` | composer hold-hint tooltip |

Not wired (no home or out of scope): edit-profile avatar placeholder (no avatar slot), support hub
topic glyphs, wallet / loyalty ledger kind glyphs, the 12 dp PRO pill crown, Mine stat tiles, Pro
member hero / paywall (painted), assistant store-off label, coupon_body / tracking late-note clocks,
search no-results and address-edit search-miss / out-of-area / permission-denied states (those views
do not exist), P4 / P8 painter specs. Dropped in I15b: the PNG constants with no user (`globalCart`,
`globalCartFull`, `labelHome/Office/Gathering/Other`, `mineScanQrCode`, `shopRed/EmptyHeart`), their PNGs and pubspec rows.

## Per-screen decisions (all 44 pages + shared surfaces)

Decision: **created** means the screen wires at least one new file. **Kept** means the current art is
right, or is re-mapped to existing files only. **Not needed** means no asset file is required, and a
painter spec or plain code covers it. "HeroIcons.x" means the existing icon-font glyph. P1-P8 are the
painter or primitive specs in §3.3.

| # | Screen / surface | Decision | Asset file(s) | Reason |
|---|---|---|---|---|
| 1 | Mine (tab) | created | `tab_account` (guest avatar in a `#DCFCE7` disc), `pro_crown`, `assistant_ai`; scan button → HeroIcons.confirmReceipt; wallet / points / coupon / gift rows → `checkout_wallet`, `checkout_points`, `checkout_ticket`, `offer_gift` (kept) | Grey Material person, mismatched QR PNG (extracted from the reference APK), Material menu glyphs next to unused brand SVGs |
| 2 | Wallet | created | `empty_ledger`, `state_signed_out`, `state_offline`, `state_error`; kinds → `checkout_wallet`, `cart_basket`, HeroIcons.orders | Empty slot has no art, signed-out is a lock glyph, the brand wallet is unused |
| 3 | Loyalty points | created | `empty_ledger`, `state_signed_out`; rules → `checkout_points`, `cart_basket`, HeroIcons.delivery; bonus → `status_success`, `tab_account` | A new member sees no art; Material rule and bonus glyphs |
| 4 | Loyalty rewards | created | `rewards_badge` (tinted per tier, locked → `disabledText` plus a code lock), `state_unavailable`, `state_signed_out` | All tiers share one faded Material gift; "programme unavailable" has no art; sign-in uses a red error icon |
| 5 | Settings | kept | Material set | The audit says nothing critical is missing; a log-out illustration is optional and declined (dialogs stay light) |
| 6 | About | kept | `appLogo` PNG; social tiles stay Material | Real social logos are trademarks: they must come from each owner's brand kit, not be drawn here (§6) |
| 7 | Delivery code | created | `delivery_code_handover`; scan glyph → HeroIcons.confirmReceipt | The concept ("the rider asks for this code") needs explaining |
| 8 | Edit profile | created | `tab_account` (avatar placeholder disc), `state_signed_out`, `state_offline`, `state_error` | No avatar placeholder; shared state gaps. A completion celebration is optional (ring check in code) |
| 9 | Splash | kept | all painted | The audit found no gaps |
| 10 | Main shell | created | `tab_account`; Search tab → HeroIcons.search; history segment → HeroIcons.orders | Mixed icon families in one bar |
| 11 | Login | kept | painted backdrop, lockup and mark; session-expired → HeroIcons.info | Painted art is good. Social PNGs and the flag emoji are **not drawn here** (trademark and official flag colours, §6) |
| 12 | OTP verify | kept | "Code sent" → HeroIcons.phone in a `#DCFCE7` disc; success = the existing `LoaderDoneMark` | Existing glyphs cover it; a new SMS icon would duplicate `phone` |
| 13 | Address list | created | `empty_addresses`, `address_label_home/office/gathering/other`, `state_signed_out`, `state_offline`, `state_error`; delete dialog → HeroIcons.delete | Empty book is a grey pin; the label PNGs come from the reference APK (originality) |
| 14 | Address edit (map) | created | `map_pin`, `address_label_*`, `state_search_empty` (search miss), `state_unavailable` (out of area), `empty_addresses` (permission denied); **P4** locating pulse | Painted `Container` pin; no locating, denied, out-of-area or no-results art. The map-loading placeholder is a `smallBackground` fill, no asset |
| 15 | Assistant buddy layer | created | `assistant_ai`, `product_options` (thought "choose"), `recipe_pot` (thought "meals"); other topics → HeroIcons.search / chat / help / cart, `checkout_code_tag`, `address_label_home`; **P1** moods | assistant.md §5 rows 1, 2, 14 |
| 16 | Assistant chat | created | `assistant_prop_handoff`, `assistant_prop_mic`, `assistant_hold_to_talk`, `state_signed_out`, `state_unavailable` (store off), `state_offline`; tool glyphs → `recipe_pot`, `shared_clock`, HeroIcons.search / cart / delivery / help / location, `checkout_code_tag`; **P1** | assistant.md §5 rows 1, 3-7, 10-11 |
| 17 | Assistant history | created | `assistant_prop_bubble`, `state_signed_out`; chips → HeroIcons.customerService, `status_success` | §5 rows 5, 8, 9 |
| 18 | Assistant tour sheet | not needed | **P2** (GroceryDoodle cleaner and bulb; coffee exists); the step-1 wave = the mascot's painted wave | §5 rows 12-13. Painted doodles match the existing tiles better than SVG would |
| 19 | Cart preview | created | `empty_basket`, `cart_basket`, `cart_basket_full`, `status_offline` (sync banner), `pro_crown`, `empty_coupons` (deals empty), `state_error`; coupon / points / express / gift → existing SVGs | Material empty plate, Material glyphs next to existing brand SVGs |
| 20 | Cart tab | created | as block 19, plus the history pill → HeroIcons.orders | Same, plus mixed pill glyphs |
| 21 | Checkout | created | `empty_basket`, `state_signed_out`, `state_error`, `state_unavailable` (branch sheet empty); bar fact → HeroIcons.delivery (directional); timing → `shared_clock` (ASAP / scheduled), `checkout_express_bolt` | Material `delivery_dining`, no empty or branch art |
| 22 | Checkout vouchers | created | `offer_percent`, `empty_coupons`, `status_success` ("unlocked"); ticket kinds → `offer_delivery/gift/voucher` | Every ticket shares one glyph; no "no offers" art |
| 23 | History coupons | created | `empty_coupons`, `state_error` | Material glyph in a disc |
| 24 | My coupons | created | `empty_coupons` (same art for every tab, the copy changes per tab), `state_error`; glyphs → `checkout_ticket` | Material empty plates; summary hero art is not needed (code glow is enough) |
| 25 | Home | created | `empty_shelf`, `state_offline`, `state_error`, `cart_basket` (min-order), `pro_crown`, `image_placeholder`, `status_success` (first add); ETA → HeroIcons.delivery; assistant disc → the painted mascot (kept) | Bare Material empty, Material Pro and bag glyphs. Day-part and occasion glyphs: not needed (§6) |
| 26 | Search | created | `state_search_empty`, `state_offline`, `status_offline` (inline "needs a connection") | No "no matches" art. Discover first-run art: not needed |
| 27 | Content (CMS) | created | `state_not_found` (empty page) | Bare Material `article_outlined`. Per-kind header art: not needed (text pages) |
| 28 | Offers | created | `offer_percent`, `empty_coupons`; 🔥 emoji → HeroIcons.flame; kinds → `offer_*` | No percent plate, no empty art, the emoji renders differently per OS |
| 29 | Notifications | created | `empty_notifications`, `state_signed_out`; 11 kinds re-mapped → `pro_crown`, `checkout_*`, `offer_*`, HeroIcons.orders / delivery / notice | No inbox-empty or signed-out art; mixed families |
| 30 | Order invoice | created | `status_success` (paid), `state_signed_out`; payment → `checkout_cash/wallet`, loyalty → `checkout_points`, header → painted HeroMark | Text-only payment; Material star |
| 31 | Order review | created | `state_success` (sent / already reviewed), `image_placeholder`; stars → HeroIcons.star | No thank-you art; Material thumbnail placeholder |
| 32 | Order tracking | created | `state_success` (delivered), `state_not_found`, `address_label_*` (destination); stages → HeroIcons.orders / cart / confirmReceipt / delivery / close in 56 dp discs (**P8**); driver → HeroIcons.delivery | No stage or delivered art; Material rider and pin |
| 33 | Orders (list) | created | `empty_basket` (empty plus "Start shopping"), `image_placeholder`, `state_signed_out`, `status_success` (reorder added); status tags → stage glyphs (P8) | Grey receipt with no way forward |
| 34 | Customer-service hub | created | `state_offline`, `state_error`; 6 topics → HeroIcons.orders / delivery / help, `checkout_cash`, `checkout_ticket`, `tab_account` | One glyph for 6 topics; no failure art. A hub header illustration is not needed |
| 35 | Help topics | created | `state_search_empty` (no results), `assistant_prop_handoff` ("still need help", used alone) | Grey help glyph; the agent card is only a glyph |
| 36 | Rider chat | kept | avatar → HeroIcons.delivery in a `#DCFCE7` disc (replaces the grey circle; `globalRider` PNG retired) | The thread is scripted. Read ticks, a typing indicator or an empty-thread asset would **fake** a state. Revisit when the thread is real (**P5** deferred) |
| 37 | PDP image viewer | created | `image_placeholder` | Flat grey pre-load. A zoom coach-mark is not needed (zoom is the standard gesture) |
| 38 | Product detail | created | `state_not_found`, `image_placeholder`, `status_success` (added), `product_options`; "no reviews" → HeroIcons.star inline; low / out of stock → HeroIcons.alert | Material not-found and placeholder |
| 39 | Recipe detail | created | `state_not_found`, `image_placeholder`, `shared_clock` (time), `tab_account` (servings), `status_success` (ingredients added) | Material soup glyph; text-only meta |
| 40 | Recipes (list) | created | `empty_shelf`, `image_placeholder`, `shared_clock`, `state_offline`, `state_error` | Material soup glyph, grey thumbnails |
| 41 | Pro membership | created | `pro_welcome`, `pro_crown`, `state_unavailable`; perks → `checkout_express_bolt`, `checkout_voucher_disc`, `checkout_points`; lapsed → `pro_crown` | Material crown everywhere; no welcome or unavailable art |
| 42 | Brands | created | `empty_shelf`, `image_placeholder` (logo loading); the letter fallback is kept | No "no brands" art; flat grey logo tile |
| 43 | Categories | created | `category_all`, `image_placeholder`, `empty_shelf` | "All" can look like an artwork-less category; generic glyph |
| 44 | Category | created | as block 43 | Same root cause |
| 45 | Product listing | created | `empty_shelf` (no products / filters too narrow), `image_placeholder`, `product_options`; collection hero → HeroIcons.flame, `offer_percent`, `rewards_badge` | Material empty; emoji-only hero. The out-of-stock text wash stays (text carries it) |
| 46 | Sheets and dialogs | created | `pro_welcome` (welcome sheet), `shared_clock`, `checkout_express_bolt`, `checkout_ticket`, HeroIcons.delete, `assistant_prop_handoff` / `_mic` next to the painted mascot | Material discs; the timing set did not match |
| 47 | Snack bars | created | `status_success`, `status_offline`; info → HeroIcons.info, error → HeroIcons.alert | No tone glyph set (B3-03) |
| 48 | Connectivity banner | created | `status_offline`, `status_success` (back online) | Material pair |
| 49 | Stale notices | created | `shared_clock` (age pill), `status_offline` (inline note) | Should match the banner pair |
| 50 | Locale veil | not needed | — | A solid veil is the point |
| 51 | Tab bar and cart bar | created | `tab_account`, `cart_basket`, `cart_basket_full` | Mixed families; basket PNGs extracted from the reference APK |
| 52 | Route map (PlaceholderPage) | created | `state_not_found` | Material `construction_rounded` |
| 53 | Loaders | not needed | **P3** `LoaderFailMark` (B3-05); the 2.29 MB GIF is removed (BX-06) | Painted dots are complete |
| 54 | Skeletons | not needed | — | Bones are drawn |
| 55 | State views | created | the `state_*` set plus a new `art:` slot on `HeroStateView` / `EmptyStateView`; checking → AppLoader dots (kept) | Every state is a bare Material icon |
| 56 | Product cards / shelves / steppers | created | `image_placeholder`, `product_options` (replaces `tune_rounded`) | Flat grey tile, ambiguous options glyph |
| 57 | Add-to-cart path | created | `cart_basket`, `cart_basket_full`, `empty_basket` | Raster baskets from the reference APK; no shared empty-basket glyph |
| 58 | Ambient brand widgets | kept | all painted | The audit says nothing is missing |
| 59 | Images | created | `image_placeholder` (B3-06) | Material `image_outlined` |

**Counts:** created 48 · kept 7 (blocks 5, 6, 9, 11, 12, 36, 58) · not needed 4 (18, 50, 53, 54) · total 59.
The 44 pages alone: 38 created, 6 kept, 0 not needed. Shared surfaces plus the tour: 10 created, 1 kept,
4 not needed.

---


## In-app SVGs — batch A (sticker illustrations + assistant props)


19 files in `assets/svg/` (flat, new; no other repo file touched). All pass `render/svg_check.js`
(viewBox = width/height, no text/image/metadata/style/filter/gradient, every hex in asset_plan §1.3,
≤ 1 decimal on coordinates, < 10 KB). Checks: `render/check_A/<name>.png` (#F8FAFC) and
`<name>_w.png` (#FFFFFF) at 360 px; contact sheets `render/check_A/_sheet.png` / `_sheet_w.png`
(true relative dp: stickers 160×120, props 96, hint 64).

**Light-bg check (applies to every row):** the meaningful shape carries the G3 ink outline `#0B2E13`
(14.85:1 on #FFFFFF, 14.19:1 on #F8FAFC). Light fills (`#22C55E`, `#F99022`, `#FBBF24`, `#FFEA52`,
`#F3EDE5`) sit only inside ink. Backdrop discs, `#C2C2C2` dashes / lost-signal arcs and gloss are
decorative (exempt, §1.4). Rendered on both backgrounds and inspected.

**Made:** hand-authored SVG, checked with resvg render (`render/render_A.js`, kit.js).
**Reduced motion (every row):** the file is static. The widget's pattern-17 entrance (fade + scale
0.9 → 1, `medium`, once) is skipped under `MotionGuard.reduced` and the art shows static.

| File | Screen(s) (App. A block) | Purpose (UX problem) | Light-bg | RTL | Reduced motion | Bytes | Made | Backlog |
|---|---|---|---|---|---|---|---|---|
| `state_offline.svg` | every `HeroStateView.offline` / `FailureView` offline: 2, 8, 13, 16, 25, 26, 34, 40, 55 | "Paused, your data is safe" instead of a bare Material wifi glyph | pass: ink bag + ink inner arc + `#1F2937` badge (14.68:1) | none | static | 999 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `state_error.svg` | `HeroStateView.error` everywhere, cart deals-sheet error, 23, 24 | "A hiccup, try again", not red blame | pass: ink outline; `#F0390E` badge 3.96:1 + ink ring | none | static | 1137 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `state_signed_out.svg` | 2, 3, 4, 8, 13, 16, 17, 21, 29, 30, 33, Mine guest header (1, at 120×90) | One shared sign-in invitation replacing lock / red error / grey looks | pass: ink bag + ink padlock | none | static | 1006 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `state_not_found.svg` | 27, 32, 38, 39, 52 | Shared "this isn't here" (empty open box) instead of soup / article / construction glyphs | pass: ink box + ink puffs | none | static | 724 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `state_search_empty.svg` | 26, 35, 14 (address search miss) | "No matches" state that did not exist | pass: ink lens + `#15803D` handle (5.02:1) in ink | none (magnifiers never mirror) | static | 708 | hand-authored SVG, resvg | BX-13 |
| `state_unavailable.svg` | 4, 41, 16 (store off), 21 (no branch open), 14 (out of area) | "Not open for this here / now": shop with blank closed sign + moon | pass: ink shop, awning, sign | none | static | 1499 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `state_success.svg` | 31 (review sent), 32 (delivered), 8 (optional) | Resting success state, not only a toast | pass: ink bag; `#15803D` badge 5.02:1 | none | static (draw-on check is the widget's, pattern 19) | 1333 | hand-authored SVG, resvg | BX-13 + B2-04 |
| `empty_basket.svg` | 19, 20, 21, 33, 57 | Branded empty basket replacing grey Material plates | pass: ink basket, `#15803D` rim | none | static | 712 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `empty_ledger.svg` | 2 (wallet empty), 3 (points empty) | Fills the empty `EmptyStateView` slot; matches `checkout_wallet` / `checkout_points` | pass: ink wallet + coin | none (clasp side has no meaning) | static | 905 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `empty_notifications.svg` | 29 | Inbox-empty "all caught up" | pass: ink bell; `#15803D` check badge | none | static (bell never swings) | 820 | hand-authored SVG, resvg | BX-13 |
| `empty_addresses.svg` | 13 (empty book), 14 (location permission denied) | Replaces the 56 dp grey pin; gives permission-denied art | pass: ink map + ink pin; `#15803D` route 5.02:1 | none | static | 1214 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `empty_coupons.svg` | 19 / 20 deals sheet, 22, 23, 24 (every tab), 28 | "No offers" art replacing glyph-in-disc empties | pass: ink tickets; `#6A2F00` perforation 10.4:1 | none | static | 1068 | hand-authored SVG, resvg | BX-13 |
| `empty_shelf.svg` | 25, 40, 42, 43, 44, 45 | Catalogue-family empty (bare shelf, blank tag, one orange) | pass: ink boards, uprights, tag | none | static | 1117 | hand-authored SVG, resvg | BX-13 + B1-04 |
| `pro_welcome.svg` | 41 (welcome hero), 46 (Pro-welcome sheet) | Welcome-moment art replacing a Material crown in a gradient disc | pass: ink bag + crown; `#4F46E5` badge 6.29:1, bolt `#D4F53C` 5.07:1 on it | none | static; the page's crown float is pattern 22 (stops at `ambientBudget`) | 1479 | hand-authored SVG, resvg | BX-13 |
| `delivery_code_handover.svg` | 7 | Explains "the rider asks for this code at the door" (door → bag → phone with 4 code dots, no digits) | pass: ink door, bag, phone; code dots `#15803D` 5.02:1 on white screen | **directional** → `SvgPicture.asset(..., matchTextDirection: true)` | static | 1101 | hand-authored SVG, resvg | BX-13 |
| `assistant_prop_bubble.svg` (96) | 17 (empty history, mascot `warm`) | Replaces grey `forum`; "nothing said yet" bubble beside the mascot | pass: ink bubble | **directional** (tail points at the mascot) → `matchTextDirection: true` | static | 626 | hand-authored SVG, resvg | BX-13 |
| `assistant_prop_mic.svg` (96) | 16 (mic-blocked dialog), 46 (mascot `curious`) | "Allow the mic", not an error: mic + amber lock badge | pass: ink mic + ink lock | none | static | 677 | hand-authored SVG, resvg | BX-13 |
| `assistant_prop_handoff.svg` (96) | 16 (handoff dialog / banner / card, mascot `handingOver` P1), 35 ("still need help", alone), 46 | A human agent that reaches toward the mascot | pass: ink figure; `#1963CC` shirt 5.68:1 | **directional** (hand reaches toward the mascot) → `matchTextDirection: true` | static | 955 | hand-authored SVG, resvg | BX-13 |
| `assistant_hold_to_talk.svg` (64) | 16 (composer first-use hint) | Hold → slide up to lock gesture explained visually (tooltip text stays i18n) | pass: ink disc, lock, finger; `#15803D` arrow 5.02:1 | none (vertical) | static; otherwise the widget nudges the arrow up 4 dp once (`medium`, `signature`) | 988 | hand-authored SVG, resvg | BX-13 + B1-13 |

Largest file: `state_unavailable.svg`, 1499 B (sticker target < 5 KB). Total 19,068 B.

### Deviations from the §3.1 coordinates (all made after looking at the render)

- `state_offline`: the wifi mark sits **above** the handle (centre (80,26), radii 7 / 13 / 19, dot r 2.6).
  At (80,42) with r 8/16/24 the dot and inner arc sat inside the handle and read as clutter.
- `state_error`: the tipped bag is shifted `translate(-6 -4)` before `rotate(18 80 96)` so the handle
  clears the "!" badge.
- `state_success`: badge centre (114,34) instead of (112,34) to clear the handle; purple confetti at (88,14).
- `state_not_found`: flaps hinged on the opening's sides and made larger (read as an open box, not ears).
- `state_unavailable`: shop body y 46-96, door y 64, sign y 66 hung from a nail at (80,59) so the nail and
  strings sit on the wall below the scallops (at y 52 they hid under the awning).
- `empty_ledger`: coin at (68,34) so the star is not hidden by the flap.
- `empty_shelf`: short string added so the tag hangs visibly from the upper board.
- `pro_welcome`: crown raised to sit on the handle top (y 7-35); at y 18-47 it covered the handle.
- `delivery_code_handover`: small bag at scale 0.5 with ink 5 inside the group (renders 2.5, same weight).
- `assistant_prop_bubble` / `_mic`: gloss drawn in `#E8F1FD` (white gloss on a white fill is invisible);
  bubble sparkle at (86,9) to clear the bubble corner.
- `assistant_prop_handoff`: head at (60,38) and torso top at 54 so the neck joins; the arm is a blue sleeve
  from the shoulder plus a skin hand disc (a bare skin bar read as detached).
- `assistant_hold_to_talk`: fingertip drawn as a finger (rounded rect entering from the bottom-trailing
  edge, with a nail) — the 12×16 ellipse read as an egg; arrow and lock moved down 4-5 units so the lock
  shackle fits inside 64.

Family check (`_sheet.png`): same G3 ink weight (3 on stickers, 2.5 on props, 2 on the hint), same G1
shadow and G2 disc on every sticker, G5 badges at one size, G6 sparkles in one colour pair. Reads as one set.


## In-app SVGs — batch B (mono icons + colour plates)


19 files in `assets/svg/` (flat, new; no other repo file touched). All pass `render/svg_check.js`
(viewBox = width/height, no text/image/metadata/style/filter/gradient, every hex in asset_plan §1.3,
≤ 1 decimal on coordinates, < 10 KB). Checks: `render/check_B/<name>.png` (#F8FAFC) and
`<name>_w.png` (#FFFFFF) at 360 px (`render/render_B.js`); contact sheet `render/check_B/_sheet.png`
(3×) and `_sheet_1x.png` (1×) from `render/sheet_B.js`: both backgrounds; the 13 mono icons at 24 dp
next to HeroIcons search / cart / orders (font glyphs, 24 dp), once in `#111827` and once tinted
`#16A34A`; plates at their dp sizes; `image_placeholder` at 36 % of a 96 dp and a 64 dp `#F1F5F9`
tile; `rewards_badge` at 48 dp tinted `#15803D` / `#4F46E5` / `#C2C2C2`.

**Mono icons (12 × 24 + `rewards_badge` 48):** one colour `#111827`, stroke 1.7 (badge: 3 on 48,
same weight at display size), round caps and joins, live area 2-22. Solid details (dots, stars,
sparkles, leaf) in `#111827` with a thin same-colour stroke (0.6-1.2) to round the tips. The widget
tints with `ColorFilter.mode(c, BlendMode.srcIn)`.
**Light-bg check (mono):** `#111827` is 17.74:1 on #FFFFFF / 16.96:1 on #F8FAFC. The tint rule (§1.4)
was rendered: `#16A34A` reads at 3.30 / 3.15:1 ✓; `#22C55E` only where a text label carries the
meaning (tab bar, chips).
**Made:** hand-authored SVG, checked with resvg render (kit.js).
**Reduced motion (every row):** the file is static; any entrance or state tween belongs to the widget
and is skipped under `MotionGuard.reduced`.
**RTL:** no batch-B file is directional (symmetric objects, clocks, "%", pin, check), so none is wired
with `matchTextDirection`.

| File | Screen(s) (App. A block) | Purpose (UX problem) | Light-bg | RTL | Reduced motion | Bytes | Made | Backlog |
|---|---|---|---|---|---|---|---|---|
| `status_success.svg` | 47, 48 (back online), 3, 17, 22, 25, 30, 33, 38, 39 | Hero success glyph instead of the Material check | pass: mono, tint ≥ 3:1 rule | none | static | 278 | hand-authored SVG, resvg | B3-03, BX-13 |
| `status_offline.svg` | 47, 48, 49, 19 (sync banner), 26 (inline) | One offline glyph for 4 Material `wifi_off` / `cloud_off` uses | pass: mono, tint ≥ 3:1 rule | none | static | 376 | hand-authored SVG, resvg | B3-03, BX-13 |
| `shared_clock.svg` | 49 (stale age), 21 / 46 (ASAP, scheduled), 39 / 40 (recipe time), 16 (delivery clock) | Timing glyph matching the Hero set, not `schedule_rounded` | pass: mono | none (clocks never mirror) | static | 272 | hand-authored SVG, resvg | BX-13 |
| `address_label_home.svg` | 13, 14, 32, 15 (thought "home") | Replaces the label PNG extracted from the reference APK | pass: mono | none | static | 372 | hand-authored SVG, resvg | BX-13 |
| `address_label_office.svg` | 13, 14, 32 | Same (office) | pass: mono | none | static | 475 | hand-authored SVG, resvg | BX-13 |
| `address_label_gathering.svg` | 13, 14, 32 | Same (diwaniya / gathering) | pass: mono | none | static | 431 | hand-authored SVG, resvg | BX-13 |
| `address_label_other.svg` | 13, 14, 32 | Same (other: pin + sparkle) | pass: mono | none | static | 431 | hand-authored SVG, resvg | BX-13 |
| `tab_account.svg` | 10 / 51 (tab), 1 (guest avatar), 8, 39 (servings), 34, 3 | Hero person glyph in the HeroIcons bar | pass: mono; `#22C55E` only beside the tab label | none | static | 306 | hand-authored SVG, resvg | BX-13 |
| `assistant_ai.svg` | 1 (Mine row), 15, 16 (store-off label, launcher sheet) | Mascot gumdrop + sparkle instead of bare `auto_awesome` | pass: mono | none | static | 741 | hand-authored SVG, resvg | BX-13 |
| `recipe_pot.svg` | 15 (thought "meals"), 16 (tool "recipe") | Glyph for text-only tool rows | pass: mono | none | static | 420 | hand-authored SVG, resvg | BX-13 |
| `product_options.svg` | 38, 45, 56 ("choose options"), 15 (thought "choose") | Three jar sizes instead of the ambiguous `tune_rounded` | pass: mono | none | static | 429 | hand-authored SVG, resvg | BX-13 |
| `category_all.svg` | 43, 44 ("All" in rail and chips) | "All" gets its own artwork, not an empty category tile | pass: mono | none | static | 427 | hand-authored SVG, resvg | BX-13 |
| `pro_crown.svg` (24 plate) | 1, 19, 25, 29, 41 | Pro crown plate replacing `workspace_premium` | pass: plate `#4F46E5` 6.29 / 6.01:1; crown `#FBBF24` on plate 3.77:1 | none | static | 413 | hand-authored SVG, resvg | BX-13 |
| `offer_percent.svg` (24 plate) | 22, 28, 45 | Percent-off plate beside `offer_*` | pass: plate `#F0390E` 3.96 / 3.79:1; white "%" on plate | none ("%" never mirrors) | static | 385 | hand-authored SVG, resvg | BX-13 |
| `cart_basket.svg` (32) | 51, 57, 19, 20, 25, 2, 3 | Replaces the extracted `globalCart` PNG | pass: ink `#0B2E13` 14.85 / 14.19:1; `#22C55E` only inside ink | none | static | 504 | hand-authored SVG, resvg | BX-13 |
| `cart_basket_full.svg` (32) | 51, 57 | Replaces the extracted `globalCartFull` PNG | pass: ink outline on basket and produce | none | static | 755 | hand-authored SVG, resvg | BX-13 |
| `map_pin.svg` (40×48) | 14 | Real pin art instead of a painted `Container`; no shadow (the widget paints the ground shadow so the pin can lift) | pass: ink 2.4 `#0B2E13`; `#22C55E` inside ink | none | static (lift + P4 pulse are the widget's) | 340 | hand-authored SVG, resvg | BX-13 + B1-12 |
| `image_placeholder.svg` (48) | 59, 56, 25, 31, 33, 37-45 | Quiet Hero-bag outline for the image tile (widget draws `#F1F5F9`, SVG at 36 % of the shorter side) | decorative, exempt (`#C2C2C2`; product name carries meaning) | none | static | 396 | hand-authored SVG, resvg | B3-06 |
| `rewards_badge.svg` (48 mono) | 4 (per tier, tier tint; locked = `#C2C2C2` + code lock), 45 | One medal glyph per tier instead of one faded gift | pass when tinted ≥ 3:1 (§1.4); locked grey relies on the lock + label | none | static | 494 | hand-authored SVG, resvg | BX-13 |

**Deviations from the §3.2 compositions (after looking at the renders):**
- `status_offline`: the two arcs are split around the slash (a 2.3-unit gap each side) and the tiny
  leading stub of the outer arc is dropped; drawn straight through, the slash and arcs merged into a
  knot at 24 dp. Tint-safe (no white knockout).
- `address_label_gathering`: side heads at (5.4, 9.6) r 1.8, centre head (12, 8.8) r 2.2, whole
  figure raised 1.5; the side shoulders stop where the centre person starts (at the spec positions the
  three heads touched and the shoulder arcs crossed).
- `product_options`: a short cap line over each box, so the three bottom-aligned boxes read as jar
  sizes, not a signal-strength bar chart.
- `image_placeholder`: the §1.1 bag mapped into 48 at scale 0.6 about (80, 64.5) → (24, 24), written as
  plain coordinates (no transform), stroke 2.2.
- `rewards_badge`: 5-point star outer r 6, inner r 2.5.

**Weight check (`_sheet.png`):** at 24 dp the mono set sits next to HeroIcons search / cart / orders
with the same visual weight (the font glyphs fill slightly more of the em box); the `#16A34A` row
stays legible on both backgrounds. Plates match the existing `offer_gift` plate (rx 6, flat fill,
white or amber glyph).


## Preview GIFs (docs only)


37 GIFs in `previews/<screen>/` (27 pattern previews + 5 before/after pairs). Never bundled
(outside `assets/`, not in pubspec). Nothing else in the repo was touched. Total **12.22 MB**; largest
`orders/p05_list_entrance.gif` 1.60 MB (all ≤ 2 MB). All 360 px wide, looping, ≤ 30 fps (24 fps when the loop is longer than 4 s).

**How they were made.** One generator, `render/previews/gen.js` (shared scene helpers: phone frame, status
bar, app bar, bottom nav, product card, stepper, loader disc, sheet, dialog, snack, fruit stickers, rolling
digits; one scene function per preview), drawn as SVG per frame, rasterised with resvg at 720 px
(`render/kit.js`), encoded with a two-pass ffmpeg palette (`palettegen stats_mode=diff` →
`paletteuse dither=none:diff_mode=rectangle`, scaled to 360). Timing is pure maths on the D2-D5 tokens
(`kit.ease.*`, `kit.spring` with AppSprings snappy ζ.6 k800 / calm ζ.9 k700). Widget-test capture (plan §5)
was not used: the brief for this batch forbids flutter runs/tests, so these are **faithful re-drawings, not
screenshots**; primitives that don't exist yet are labelled "proposed" in their caption.

**Art.** Original only: fruit stickers drawn for this batch, the Hero bag (no cape, no letter), and the new
`assets/svg` files embedded as paths (empty_basket, state_error, delivery_code_handover, image_placeholder,
status_offline/success, shared_clock, map_pin, cart_basket, tab_account, address_label_*, pro_crown,
offer_percent, recipe_pot, rewards_badge, assistant_ai, assistant_prop_mic). Colours are AppColors only.
No other app's screens or logos are imitated.

**Layout.** Every pattern GIF = normal pass → 400 ms gap → reduced-motion pass (dark `reduced` pill).
Caption strip (NotoSans): line 1 pattern name + green stage tag, line 2 the tokens (or the reduced
behaviour). Directional patterns render **LTR | RTL side by side** (176 + 8 + 176 px); the RTL panel is
the mirrored layout with real Arabic strings (NotoSansArabicUI), numbers kept LTR. Before/after pairs are
two files each (no reduced pass: BA1-BA3 *are* the reduced-motion case).

**Checked.** Each GIF's contact sheet (every Nth frame, N = frames/48) was read frame by frame for start
pose → motion → settle, and re-rendered after fixes (flight thumbnail visibility, predictive-back reach,
confetti spread, BA1 reply off-screen, BA2 fit, caption glyphs →/≤ missing from the bundled NotoSans
replaced by ›/<=, caption/tag overlap).

| File | Screen(s) / pattern | Purpose (what it shows) | Frames · fps · length · size · px | RTL shown? | Reduced motion | Checked (sheet) | Backlog / pattern |
|---|---|---|---|---|---|---|---|
| [`previews/home/p01_press_feedback.gif`](previews/home/p01_press_feedback.gif) | home (product card, icon button) | PressScale 0.97 / 0.92, in microPop 100, out fast 150 sig | 125 f · 24 fps · 5.2 s · 99 KB · 360×240 | no | no scale; pressed tint only | ✓ `render/previews/sheets/p01.png` | §4 #1 · D22 · PressScale |
| [`previews/home/p02_add_to_cart.gif`](previews/home/p02_add_to_cart.gif) | home → cart tab badge | PopSwitcher (snappy) + FlyToCart (slow 400 sig) + badge ChangeBump/roll on land | 139 f · 24 fps · 5.8 s · 97 KB · 360×447 | yes (stepper grows from the end corner, flight mirrors) | no flight; badge TintFlash 150 + count | ✓ `render/previews/sheets/p02.png` | §4 #2 · D16 · FlyToCart / CountBadge |
| [`previews/cart_preview/p03_qty_stepper.gif`](previews/cart_preview/p03_qty_stepper.gif) | cart_preview stepper | RollingNumber (medium 250 sig) up/down + BlockedTapShake at the stock limit | 168 f · 24 fps · 7.0 s · 107 KB · 360×200 | no | 150 cross-fade, no shake | ✓ `render/previews/sheets/p03.png` | §4 #3 · D20 · RollingNumber / BlockedTapShake |
| [`previews/checkout/p04_value_change.gif`](previews/checkout/p04_value_change.gif) | checkout summary | first paint static; total rolls only changed digits; FlipValue slot label; CountUpText for earned points (slow 400 emph) | 163 f · 24 fps · 6.8 s · 36 KB · 360×220 | no | 150 cross-fades | ✓ `render/previews/sheets/p04.png` | §4 #4 · D20 · FlipValue / CountUpText |
| [`previews/orders/p05_list_entrance.gif`](previews/orders/p05_list_entrance.gif) | orders list | EntranceCascade 30 ms x max 6, fade + 8 dp, medium; no replay on scroll-back | 156 f · 24 fps · 6.5 s · 1642 KB · 360×640 | no | one 150 fade for the list | ✓ `render/previews/sheets/p05.png` | §4 #5 · D17 · EntranceCascade |
| [`previews/product_listing/p06_skeleton_to_content.gif`](previews/product_listing/p06_skeleton_to_content.gif) | product_listing grid | skeleton: 150 delay, shimmer 1100 from the start edge, 150 cross-fade to content (slow and fast data) | 149 f · 24 fps · 6.2 s · 245 KB · 360×400 | yes (sweep starts at the start edge) | static skeleton, instant swap | ✓ `render/previews/sheets/p06.png` | §4 #6 · D17/D18 · Skeletonized |
| [`previews/order_invoice/p07_loader_delay.gif`](previews/order_invoice/p07_loader_delay.gif) | order_invoice loader | loaderDelay 150 (fast load shows nothing); disc in 150 + calm 0.9→1; orbit 1200; out 150 | 187 f · 24 fps · 7.8 s · 166 KB · 360×286 | yes (orbit turns CCW) | delay kept; dots breathe (0.4↔1, 600) | ✓ `render/previews/sheets/p07.png` | §4 #7 · D18 · AppLoader |
| [`previews/mine/p08_page_push.gif`](previews/mine/p08_page_push.gif) | mine → wallet | HeroTransitionPage as shared axis X: 30 dp + fade, page 300 sig; back reverses | 120 f · 24 fps · 5.0 s · 449 KB · 360×447 | yes (X direction flips) | 150 cross-fade | ✓ `render/previews/sheets/p08.png` | §4 #8 · D8 · HeroTransitionPage (proposed) |
| [`previews/main_shell/p09_tab_switch.gif`](previews/main_shell/p09_tab_switch.gif) | main_shell tabs | incoming tab fades fast 150, outgoing cuts; icon 1→1.12; home mark morph 250 | 115 f · 24 fps · 4.8 s · 223 KB · 360×640 | no | instant swap | ✓ `render/previews/sheets/p09.png` | §4 #9 · D11 (proposed) |
| [`previews/product_detail/p10_modal_slide_up.gif`](previews/product_detail/p10_modal_slide_up.gif) | home → product_detail | HeroSlideUpTransitionPage: in page 300 sig, out medium 250 exit | 125 f · 24 fps · 5.2 s · 533 KB · 360×640 | no | 150 fade in / out | ✓ `render/previews/sheets/p10.png` | §4 #10 · D9 · HeroSlideUpTransitionPage |
| [`previews/splash/p11_fade_through.gif`](previews/splash/p11_fade_through.gif) | splash → shell, sign-out → login | HeroFadeThroughPage: out over first 30 %, in with 0.92 settle, page 300 | 130 f · 24 fps · 5.4 s · 400 KB · 360×640 | no | 150 cross-fade | ✓ `render/previews/sheets/p11.png` | §4 #11 · D10 · HeroFadeThroughPage |
| [`previews/wallet/p12_predictive_back.gif`](previews/wallet/p12_predictive_back.gif) | wallet (predictive back) | edge drag: scale 1→0.9 + shift (w/20−8); release below threshold settles (calm); past threshold commits with pop 300 | 154 f · 24 fps · 6.4 s · 1516 KB · 360×447 | yes (back edge = leading edge, right in RTL) | tracking (shift) kept, no scale, 150 fade on commit | ✓ `render/previews/sheets/p12.png` | §4 #12 · D11 · predictive back (proposed; manifest flag needs approval) |
| [`previews/checkout/p13_bottom_sheet.gif`](previews/checkout/p13_bottom_sheet.gif) | checkout delivery-time sheet | sheet in page 300 sig + scrim; content cross-fades in the same sheet (150); 1:1 drag, fling out medium 250 exit; large sheet slow 400 | 221 f · 24 fps · 9.2 s · 952 KB · 360×640 | no | 150 fade, no slide (drag still tracks) | ✓ `render/previews/sheets/p13.png` | §4 #13 · D12 · showHeroBottomSheet |
| [`previews/address_list/p14_dialog.gif`](previews/address_list/p14_dialog.gif) | address_list delete | dialog fade + 1.1→1 (medium 250 sig), out fast 150 exit; row leaves (ListItemTransition 250) | 134 f · 24 fps · 5.6 s · 385 KB · 360×640 | no | 150 fades; row collapses instantly | ✓ `render/previews/sheets/p14.png` | §4 #14 · D12 · showHeroDialog / ListItemTransition |
| [`previews/cart_preview/p15_snack_bar.gif`](previews/cart_preview/p15_snack_bar.gif) | cart_preview sync snack | snack rises + fades in (medium 250), dwell 4000 (snackDwell), replacement cross-fades 150, out fast 150 exit; status_offline / status_success glyphs | 451 f · 24 fps · 18.8 s · 117 KB · 360×640 | no | fades only, same dwell | ✓ `render/previews/sheets/p15.png` | §4 #15 · D12 · showHeroSnackBar |
| [`previews/home/p16_connectivity_banner.gif`](previews/home/p16_connectivity_banner.gif) | home connectivity banner | CollapseReveal 250 + stale note 150; age text changes with no motion; back online TintFlash, collapse 150 | 187 f · 24 fps · 7.8 s · 420 KB · 360×640 | no | fades only (no height tween) | ✓ `render/previews/sheets/p16.png` | §4 #16 · ConnectivityBar / StaleDataNotice |
| [`previews/orders/p17_empty_state.gif`](previews/orders/p17_empty_state.gif) | orders empty state | empty_basket fades + 0.9→1 once (medium 250 sig); text and button static; no loop | 101 f · 24 fps · 4.2 s · 34 KB · 360×640 | no | static art from frame 0 | ✓ `render/previews/sheets/p17.png` | §4 #17 · EmptyStateView (batch A art) |
| [`previews/checkout/p18_error_retry_shake.gif`](previews/checkout/p18_error_retry_shake.gif) | checkout invalid tap + error view | slot row ShakeX 250 + error border + inline reason (150); error view → Retry → cross-fade 150 to the loader | 168 f · 24 fps · 7.0 s · 225 KB · 360×480 | no | colour + text only, no shake | ✓ `render/previews/sheets/p18.png` | §4 #18 · ShakeX / ErrorView (state_error art) |
| [`previews/checkout/p19_success.gif`](previews/checkout/p19_success.gif) | checkout → tracking | busy overlay ≥500 → check drawOn 700 → successHold 400 → fade through 300 + ConfettiBurst 1400 (≤60 pieces) | 190 f · 24 fps · 7.9 s · 493 KB · 360×640 | no | check shown whole, no confetti, 150 fade | ✓ `render/previews/sheets/p19.png` | §4 #19 · CubitBusyOverlay / Confetti* (delivery_code_handover art) |
| [`previews/help_topics/p20_expand_collapse.gif`](previews/help_topics/p20_expand_collapse.gif) | help_topics FAQ | CollapseReveal open 250 sig + chevron 180°; close 150 exit, content stays drawn while closing | 120 f · 24 fps · 5.0 s · 172 KB · 360×480 | no | instant height, 150 fade | ✓ `render/previews/sheets/p20.png` | §4 #20 · D14 · CollapseReveal |
| [`previews/home/p21_carousel.gif`](previews/home/p21_carousel.gif) | home banner carousel | dwell carousel 3000, slide page 300 sig, dots update; touch pauses the timer; manual drag 1:1 then settle; resume | 298 f · 24 fps · 12.4 s · 342 KB · 360×198 | yes (slide follows Directionality) | no auto-advance; manual swipe only | ✓ `render/previews/sheets/p21.png` | §4 #21 · carousel token |
| [`previews/pro_membership/p22_ambient_loops.gif`](previews/pro_membership/p22_ambient_loops.gif) | pro_membership hero | crown FloatLoop ±4 dp (floatLoop 3200) + LightSweep from the start edge (sheen 3600, 2 passes); everything stops at ambientBudget 5000 | 206 f · 24 fps · 8.6 s · 371 KB · 360×330 | yes (sweep starts at the start edge) | still frame throughout | ✓ `render/previews/sheets/p22.png` | §4 #22 · D19 · AmbientLoop (proposed) / LightSweep |
| [`previews/settings/p23_locale_veil.gif`](previews/settings/p23_locale_veil.gif) | settings language | thumb moves (calm), LocaleSwapVeil in 150, layout rebuilds under it, veil out 250 showing the mirrored layout | 106 f · 24 fps · 4.4 s · 181 KB · 360×640 | no (panel shows EN → AR) | instant swap | ✓ `render/previews/sheets/p23.png` | §4 #23 · LocaleSwapVeil |
| [`previews/orders/p24_pull_to_refresh.gif`](previews/orders/p24_pull_to_refresh.gif) | orders pull to refresh | disc follows the drag 1:1, arms at the threshold (bump), settles calm, orbit 1200; done: shrink 150, list updates | 178 f · 24 fps · 7.4 s · 972 KB · 360×480 | no | tracking kept; dots breathe; instant settle | ✓ `render/previews/sheets/p24.png` | §4 #24 · BrandedRefresh |
| [`previews/product_listing/p25_image_fade_in.gif`](previews/product_listing/p25_image_fade_in.gif) | product_listing images | image_placeholder tiles; each image fades in fast 150 sig on decode; scroll back: cached images appear instantly | 151 f · 24 fps · 6.3 s · 258 KB · 360×360 | no | instant on decode | ✓ `render/previews/sheets/p25.png` | §4 #25 · HeroNetworkImage (batch B art) |
| [`previews/recipe_detail/p26_scroll_header.gif`](previews/recipe_detail/p26_scroll_header.gif) | recipe_detail header | header collapses 1:1 with parallax 0.5; toolbar title fades across the collapse range; divider (no shadow) at the end | 192 f · 24 fps · 8.0 s · 1337 KB · 360×640 | no | collapse kept, parallax off | ✓ `render/previews/sheets/p26.png` | §4 #26 · scroll-linked header |
| [`previews/cart_tab/p27_segmented_switch.gif`](previews/cart_tab/p27_segmented_switch.gif) | cart_tab basket switch | segmented thumb calm spring; chip tint 150; radio dot springs in (snappy), old fades out | 158 f · 24 fps · 6.6 s · 178 KB · 360×198 | yes (thumb follows Directionality) | instant thumb, 150 colour | ✓ `render/previews/sheets/p27.png` | §4 #27 · AppSprings.calm |
| [`previews/assistant_chat/bx01_scroll_reduced_before.gif`](previews/assistant_chat/bx01_scroll_reduced_before.gif) | assistant_chat · BEFORE | reduced on, list scrolled up, reply arrives: animateTo(Duration.zero) throws; the list stays put | 45 f · 30 fps · 1.5 s · 34 KB · 360×640 | no | this IS the reduced-motion case (bug) | ✓ `render/previews/sheets/ba1b.png` | §4 BA1 · appD BX-01 |
| [`previews/assistant_chat/bx01_scroll_reduced_after.gif`](previews/assistant_chat/bx01_scroll_reduced_after.gif) | assistant_chat · AFTER | reduced on: MotionGuard.scrollTo jumps to the new reply instantly (proposed API) | 45 f · 30 fps · 1.5 s · 50 KB · 360×640 | no | this IS the reduced-motion case (fix) | ✓ `render/previews/sheets/ba1a.png` | §4 BA1 · appD BX-01 |
| [`previews/order_invoice/b2-06_loader_reduced_before.gif`](previews/order_invoice/b2-06_loader_reduced_before.gif) | order_invoice · BEFORE | reduced on: disc at full size from frame 0 (fast load flashes it), snaps off, static dots | 72 f · 30 fps · 2.4 s · 25 KB · 360×360 | no | reduced case (bug) | ✓ `render/previews/sheets/ba2b.png` | §4 BA2 · appD B2-06 |
| [`previews/order_invoice/b2-06_loader_reduced_after.gif`](previews/order_invoice/b2-06_loader_reduced_after.gif) | order_invoice · AFTER | reduced on: 150 delay kept (fast load shows nothing), disc at end value, dots breathe 600, fade 150 | 72 f · 30 fps · 2.4 s · 71 KB · 360×360 | no | reduced case (fix) | ✓ `render/previews/sheets/ba2a.png` | §4 BA2 · appD B2-06 |
| [`previews/address_edit/b1-12_camera_reduced_before.gif`](previews/address_edit/b1-12_camera_reduced_before.gif) | address_edit · BEFORE | reduced on, "use my location": camera flies ~700 (pan + zoom), ring pulses; schematic painted map (no Google tiles) | 54 f · 30 fps · 1.8 s · 180 KB · 360×640 | no | reduced case (bug) | ✓ `render/previews/sheets/ba3b.png` | §4 BA3 · appD B1-12 |
| [`previews/address_edit/b1-12_camera_reduced_after.gif`](previews/address_edit/b1-12_camera_reduced_after.gif) | address_edit · AFTER | reduced on: instant camera move, static ring | 54 f · 30 fps · 1.8 s · 39 KB · 360×640 | no | reduced case (fix) | ✓ `render/previews/sheets/ba3a.png` | §4 BA3 · appD B1-12 |
| [`previews/cart_preview/b2-01_stepper_before.gif`](previews/cart_preview/b2-01_stepper_before.gif) | cart_preview stepper · BEFORE | +/− swap digits instantly; no press state | 72 f · 30 fps · 2.4 s · 31 KB · 360×200 | no | n/a (before/after of the normal pass) | ✓ `render/previews/sheets/ba4b.png` | §4 BA4 · appD B2-01 |
| [`previews/cart_preview/b2-01_stepper_after.gif`](previews/cart_preview/b2-01_stepper_after.gif) | cart_preview stepper · AFTER | press 0.92 (100 in / 150 out) + digits roll 250 up / down | 72 f · 30 fps · 2.4 s · 45 KB · 360×200 | no | reduced: 150 cross-fade, no press scale (see p03) | ✓ `render/previews/sheets/ba4a.png` | §4 BA4 · appD B2-01 |
| [`previews/home/bx09_add_to_stepper_before.gif`](previews/home/bx09_add_to_stepper_before.gif) | home add → stepper · BEFORE | raw AnimatedSwitcher scales from 0; also animates on first build | 72 f · 30 fps · 2.4 s · 40 KB · 360×240 | no | n/a | ✓ `render/previews/sheets/ba5b.png` | §4 BA5 · appD BX-09 |
| [`previews/home/bx09_add_to_stepper_after.gif`](previews/home/bx09_add_to_stepper_after.gif) | home add → stepper · AFTER | PopSwitcher (snappy) from 0.85 + fade; static on first build | 72 f · 30 fps · 2.4 s · 42 KB · 360×240 | no | reduced: 150 cross-fade (see p02) | ✓ `render/previews/sheets/ba5a.png` | §4 BA5 · appD BX-09 |

### Deviations from the storyboard (asset_plan §4)

- **Canvas heights.** RTL screen previews are 360×447 (two 176 px phone panels keep the 390:844 phone
  aspect), not 360×640; RTL component previews are 198-400 px tall for the same reason.
- **p06 fast-data case** also runs the shimmer from 150 ms (D18: the 150 ms delay always applies) instead
  of "static until 600".
- **p15** keeps the real 4 s dwell for both snacks (18.8 s loop, 451 frames, 117 KB).
- **p09 / p08 / p12 / p22 / BA1** show proposed behaviour (tab fade, shared axis X, predictive back,
  AmbientLoop budget, MotionGuard.scrollTo); captions say "proposed" where the primitive doesn't exist yet.
- **BA2** shows a fast (120 ms) and a slow load in each file so the frame-0 flash is visible.
- Method: SVG re-drawing instead of the plan's temporary widget tests (see "How they were made").


## Painter and primitive specs (no asset file; no in-app GIF)

**In-app GIF decision: none.** D1 forbids Lottie, Rive and GIF. Every animated need below is ongoing
state or brand motion that must follow `MotionGuard`, pause off screen and stop at `ambientBudget`. A GIF
can do none of those and decodes on the CPU. The only GIF in the bundle (`hero_design_loading.gif`,
2.29 MB, unused) was removed by BX-06 (done).

| Id | Spec | Why a painter, not an SVG or GIF | RM | Wire |
|---|---|---|---|---|
| P1 | `AssistantMascotMood` gains `thinking` (`look: Offset(0.35,-0.45)`, `twinkle: 0.6`, `sway: 0.2`), `oops` (`surprise: 0.5`, `squash: 0.15`, `look: Offset(0,0.3)`) and `handingOver` (`happy: 0.6`, `look: Offset(±1,0)` toward the prop, sign taken from `Directionality`) | The mascot is painted; its moods are pose parameters (§5 row 3) | The pose is shown without the tween | B1-13, BX-13 |
| P2 | `GroceryDoodle.cleaner` (spray bottle: body `accentSkyLight` with `link` trigger and nozzle, `white` label band) and `GroceryDoodle.bulb` (glass `accent4` with `accent3` filament, base `secondaryText` bands); `coffee` exists | Tour tiles are doodle tiles; SVG would clash with the painted set (§5 row 13) | Static | BX-13 |
| P3 | `LoaderFailMark`: the partner of `LoaderDoneMark`. Two strokes of an ×, drawn on in sequence over `drawOn` (700), colour `error`, held for `successHold`, stroke width equal to the done mark's | Busy overlay "couldn't finish" (B3-05) | The × appears without the draw | B3-05 |
| P4 | Map locating pulse: a ring from the pin foot, r 8 → 28 dp, opacity 0.35 → 0, period `loaderOrbit` (1200), `linear`. It runs **only while locating** (real progress) and stops on a fix or a denial | An ongoing, real state | A static ring at 0.35 plus `AppLoader.inline` | BX-13 (with B1-12) |
| P5 | Rider-chat typing dots | **Deferred.** The thread is scripted; showing typing would fake a state | — | none |
| P6 | Checking connection = the existing `AppLoader` dots | Already the brand's "waiting" sign; a second glyph would compete | Breathe (D18) | none |
| P7 | Home first add = `status_success` in the pill plus the existing `ConfettiBurst` | Existing primitives | No confetti | B2-07 |
| P8 | Order-stage disc: the HeroIcons glyph (orders / cart / confirmReceipt / delivery / close) at 28 dp in a 56 dp disc tinted per stage. Add `HeroIcons.deliveryDirectional` (`IconData(0xe039, matchTextDirection: true)`) because custom-font IconData does not auto-flip | The stage set already exists in the icon font | Stage change = FadeThroughSwitcher `fast` | BX-13 |

---


## Style guide

### 1.1 Families and grids

| Family | viewBox | Display size | Stroke | Fill vs line | Colour |
|---|---|---|---|---|---|
| **Mono line icon** | `0 0 24 24`, live area 2-22 | 16-28 dp (props up to 96 dp) | `1.7`, `stroke-linecap="round"`, `stroke-linejoin="round"` | Line. Solid dots (r 0.9-1.2) and one small solid accent (star, sparkle) are allowed | **One colour only: `#111827`** (primaryText). The widget tints it with `ColorFilter.mode(c, BlendMode.srcIn)` |
| **Colour plate** | `0 0 24 24` (the basket is 32, the pin is 40×48) | 20-32 dp | `1.4-1.8` where outlined | Flat fills with the colour baked in, like `offer_*.svg` | Palette tokens from §1.3 |
| **Sticker illustration** | `0 0 160 120` | 160×120 dp in full-screen states, 120×90 dp in sheets and cards | Ink outline `3`, round caps and joins | Flat fills plus an ink outline, the same "sticker" look as the painted assistant mascot (ink = `stickerOutline`) | Palette tokens from §1.3. At most 3 hue families plus ink and white |
| **Assistant prop** | `0 0 96 96` (hint: `0 0 64 64`) | 72-96 dp, next to the painted mascot | Ink outline `2.5` (hint: `2`) | Like the stickers | Like the stickers |

**Corner radii.** Icon rects: `rx 2` when the rect is ≥ 8 units wide, `rx 1-1.5` when smaller. Plates:
`rx 6` on 24 (matches `offer_*.svg`). Illustration rects: `rx 3-8`. The bag silhouette follows
`HeroMark` (top corner 4, bottom corner 8, in 100-unit terms).

**Shared illustration parts** (reuse these values in every sticker so the set reads as one family):

- **G1 contact shadow:** `<ellipse cx="80" cy="106" rx="46" ry="6" fill="#000000" fill-opacity="0.08"/>`
  (same idea as the `GroceryDoodlePainting` shadow).
- **G2 backdrop disc:** `<circle cx="80" cy="58" r="44" fill="{tone tint}"/>`. Tone tints:
  brand `#DCFCE7`, error `#FFF5F2`, offline `#EBEBEB`, neutral `#E8F1FD`, warm `#FFFDE0`, pro `#F3EEFF`.
- **G3 ink:** `stroke="#0B2E13" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"`.
- **G4 gloss:** a white ellipse, `fill-opacity="0.38"`, about 14×6, turned −30°, at the top-leading area
  of the main object. It copies the mascot's gloss (`_glossAlpha 0.38`).
- **G5 status badge:** `<circle cx="116" cy="30" r="13" fill="{tone}"/>` with G3 ink, and the symbol in
  white at stroke 3. Tone fills: success `#15803D`, error `#F0390E`, offline `#1F2937`, pro `#4F46E5`,
  lock `#FBBF24` (symbol in ink).
- **G6 sparkle:** a 4-point star, 8 units across, fill `#FFEA52`, stroke `#F99022` width 1.5. This is
  the mascot's own sparkle colours (`accent4` fill, `accent3` ink).
- **Hero bag** (the brand bag without cape and without the "h", so no new logo is invented):
  body `M63 50H97Q101 50 101.4 54L104 90Q104.6 96 98.6 96H61.4Q55.4 96 56 90L58.6 54Q59 50 63 50Z`
  and handle `M71 50V45A9 12 0 0 1 89 45V50` (G3 ink, `fill="none"`). Body fill is set per illustration.

### 1.2 Hard rules (apply to every file)

- There is no `<text>`, no letters or digits, and no Arabic or Latin words. Symbols (check, "!", "%",
  slash) are drawn as paths. Words come from i18n keys drawn by the widget.
- There is no `<image>`, no base64, no `<metadata>`, no `sodipodi:` or `inkscape:` attributes, no
  `<style>` or CSS classes, no `<filter>` and no gradients. Allowed: `fill-opacity` and `opacity`.
- The root element is `<svg xmlns="http://www.w3.org/2000/svg" width=".." height=".." viewBox="..">`.
  `width` and `height` equal the viewBox size, as in the existing files. Coordinates use at most 1
  decimal place.
- Size budget: < 10 KB hard limit. Targets: icons < 1.2 KB, plates < 1.5 KB, stickers < 5 KB.
- File names follow `<screen_or_area>_<what>.svg` in snake_case, flat in `assets/svg/` (already bundled,
  no pubspec change). Area prefixes: `state_`, `empty_`, `status_`, `shared_`, `address_`, `assistant_`,
  `cart_`, `pro_`, `offer_`, `tab_`, `recipe_`, `product_`, `category_`, `map_`, `image_`, `rewards_`,
  `delivery_`.
- **Original work only.** Nothing is traced from Talabat, Glovo, Keeta, Uber or any other app. No other
  brand's logo appears. The bag motif is the Hero mark's own bag.
- **RTL.** A file that shows direction (a flow from start to end, or a tail pointing at the mascot) is
  marked **directional**. It is wired with `SvgPicture.asset(..., matchTextDirection: true)`, so no
  mirrored copy is needed. Clocks, "%", magnifiers, vertical arrows and symmetric objects never mirror.
- **Reduced motion.** Every SVG is static. Entrance motion belongs to the widget: pattern 17 (fade plus
  scale 0.9 → 1 at `medium`, once). Under reduced motion the art is shown static.

### 1.3 Allowed palette (exact `AppColors` hex, no new hues)

Contrast is measured against `#FFFFFF` and against `#F8FAFC` (mediumBackground), computed with the WCAG
formula (a WCAG 2.2 relative-luminance check run during Phase 5).

| Token | Hex | vs #FFF | vs #F8FAFC | Use in art |
|---|---|---|---|---|
| stickerOutline | `#0B2E13` | 14.85 | 14.19 | **Ink outline for all stickers and props** (same as the mascot ink) |
| primaryText | `#111827` | 17.74 | 16.96 | **The only colour in mono icons**; phone and screen bodies |
| brandDeep | `#15803D` | 5.02 | 4.79 | Success badge, leaves, handles, meaningful green |
| primaryDark | `#16A34A` | 3.30 | 3.15 | Lowest green allowed alone for a meaningful mark |
| primary | `#22C55E` | 2.28 ✗ | 2.18 ✗ | Main object fill, **only inside an ink outline** |
| martGreen | `#16B364` | 2.74 ✗ | 2.62 ✗ | Only inside an outline |
| brandDarkBg | `#4ADE80` | 1.74 | 1.67 | Decorative only |
| brandLightBg | `#DCFCE7` | 1.10 | 1.05 | Brand backdrop disc, panels |
| brandWash | `#F0FDF4` | 1.05 | 1.00 | Decorative only |
| white | `#FFFFFF` | — | — | Fills, gloss (0.38), symbols on badges |
| black | `#000000` | — | — | **Shadow only**, `fill-opacity` ≤ 0.14 |
| offlineSurface | `#1F2937` | 14.68 | 14.03 | Offline badge |
| secondaryText | `#808080` | 3.95 | 3.77 | Quiet meaningful lines |
| disabledText | `#C2C2C2` | 1.78 | 1.70 | Decorative lines, placeholder (exempt, §1.4) |
| divider | `#EBEBEB` | 1.19 | 1.14 | Offline backdrop, box interior |
| smallBackground | `#F1F5F9` | 1.10 | 1.05 | Placeholder tile (drawn by the widget) |
| accent1 | `#FF5324` | 3.22 | 3.08 | Map pin fill, confetti bits |
| accent1Dark / error | `#F0390E` | 3.96 | 3.79 | Error badge, offer "%" plate |
| accent1Light | `#FFF5F2` | — | — | Error backdrop (decorative) |
| errorDeep | `#BD2400` | 6.15 | 5.88 | Reserve |
| accent3 | `#F99022` | 2.32 ✗ | 2.22 ✗ | Fruit, shelf boards (inside an outline); sparkle ink |
| accent3Dark | `#E07D12` | 2.95 ✗ | 2.82 ✗ | Wallet flap (inside an outline) |
| accent4 | `#FFEA52` | 1.22 | 1.17 | Sparkle fill, bell, lemon |
| accent4Light | `#FFFDE0` | — | — | Warm backdrop |
| proAmber | `#FBBF24` | 1.67 | 1.60 | Crown, wallet, lock, ticket (inside an outline) |
| promotionTagLightBg | `#FFF6B0` | 1.10 | 1.05 | Back ticket |
| voucherBrown | `#6A2F00` | 10.40 | 9.94 | Ticket perforation |
| proIndigo | `#4F46E5` | 6.29 | 6.01 | Pro plate, Pro badge |
| accentViolet | `#7C3AED` | 5.70 | 5.45 | Confetti bit |
| accentVioletLight | `#F3EEFF` | 1.14 | 1.09 | Pro backdrop |
| proFuchsia | `#A21CAF` | 6.32 | 6.04 | Crown jewels |
| proLime | `#D4F53C` | 1.24 | 1.19 | Bolt on indigo (5.07:1 on `#4F46E5`) |
| accentSkyLight | `#E8F1FD` | 1.14 | 1.09 | Neutral backdrop, lens |
| link | `#1963CC` | 5.68 | 5.43 | Support person's shirt |
| collectionCream | `#F3EDE5` | 1.16 | 1.11 | Cardboard, door, skin tone (inside an outline) |

Any hex outside this table fails validation (§5, `svg_check.js`).

### 1.4 Contrast rule

A **meaningful shape**, the thing the picture is about, must reach **≥ 3:1** against both `#FFFFFF`
and `#F8FAFC` through its outline or its own fill. Stickers get this from the G3 ink outline (14:1). A
light fill (`primary`, `accent3`, `proAmber`, `accent4`) is only allowed **inside** an ink outline.

Mono icons are drawn in `#111827`. When the widget tints one and **the glyph alone carries the
meaning**, the tint must be ≥ 3:1. That means `primaryDark` or darker, never `primary`, because
`#22C55E` is only 2.28:1. `primary` is fine when a text label beside it carries the meaning (tab bar,
chips).

Plates: either the plate or the glyph on it reaches 3:1 (see §3.0 for the existing plates that fail).
`image_placeholder` is **decorative**: the product name carries the meaning. It is exempt and stays
quiet (`#C2C2C2`).

---


## Findings and open decisions (not done)

1. **Extracted reference-app art is still in the bundle.** `globalCart`, `globalCartFull`, `globalRider`,
   the 4 `label*` PNGs and `mineScanQrCode` are replaced by this plan (the unused ones and the heart PNGs were deleted in I15b). **Still extracted:** `globalRider`,
   `popupClose`, and the whole HeroIcons font. This plan maps the order
   stages and tool glyphs onto HeroIcons for consistency. If the user wants zero reliance on extracted
   glyphs, add 5 stage icons plus a font replacement (a separate decision).
2. **Social sign-in logos and About social tiles** are trademarks. They are not drawn here; the user
   supplies them from the Google, Apple and Meta brand kits.
3. **Kuwait flag** (login) needs its official colours, which are outside AppColors. It is not drawn.
   The emoji stays unless the user approves a flag-colour exception.
4. **Palette drift** in 3 existing SVGs (§3.0). The fix is optional and needs approval (it changes
   visible colour slightly).
5. **Not needed, by choice:** day-part greeting glyphs (§5 row 15, optional), home occasion-tile
   glyphs (the backend image is the art), per-kind CMS headers, a PDP zoom coach-mark, a log-out
   dialog illustration, a Discover first-run illustration, and rider-chat ticks / typing / empty thread
   (scripted thread, P5).
6. **BX-13 needs these code hooks:** an `art:` slot on `HeroStateView` / `EmptyStateView`; the
   `AssistantStateArt` widget; `HeroIcons.deliveryDirectional`; a `HeroNetworkImage` placeholder
   (B3-06); snack tone glyphs (B3-03); and a `HeroAssets` constant per file.

