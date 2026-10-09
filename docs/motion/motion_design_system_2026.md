# Hero 2026 Motion & Interaction System

Date: 2026-09-28. Status: research, audit and design (this task changed no code); built afterwards, see "Implementation status" below. Items tagged **[BEHAVIOUR CHANGE]** or ⚠ need the user's approval before they are built (full list: Appendix D).

Companion documents: [research_log_2026.md](research_log_2026.md) (Phase 1 sources, finding IDs `[Rxx-yy]`) · [asset_manifest.md](asset_manifest.md) (Phase 5 icons, illustrations and preview GIFs in `previews/`).

How to read the citations: `[Rxx-yy]` = research finding (research log) · `PB-nn` = performance issue (Appendix B) · `CC-nn` = clean-code issue (Appendix C) · `B1-nn` / `B2-nn` / `B3-nn` / `BX-nn` = backlog row (Appendix D) · `[INFERENCE]` = our reasoning, no source. The audit is static: no debug build was running, so every fact comes from reading the code (file:line as of 2026-09-27/28).

## Implementation status (2026-09-29)

Everything below this section is the design as written on 2026-09-28 (section 0 describes the code BEFORE
the work). The 16 approved items were built one task at a time (I1-I13), then a leftovers sweep (I15a) and a
final QA pass (I15b). `dart analyze` went from 20 warnings to 5 (the 5 left are the §12 `BuildContext` debt in
`SettingCubit` / `LocalizationCubit`, not motion), and tests from 2698 passing + 6 failing to 3090 passing, 0
failing. The code is the truth: `docs/hero_motion_reference.md` maps the shipped names. Not yet run on a device
(no emulator pass): predictive back, the iOS swipe, viewer pull velocity, shelf rhythm, Pro sweeps, per-word fade,
120 Hz halo, SVG plate weights, the map pin, the hold-hint card, the reduced-motion loader breathe.

**Shipped, by backlog id**
- Foundation (I1): retune / retire / add `AppMotion` tokens (BX-10), springs folded into the token story,
  `MotionGuard.reduced / off / ambientAllowed / scrollTo / pageTo` (BX-01, B2-06 delayed loader, B1-03 float period),
  `Haptics` intent helpers + persisted Vibration mute (Settings).
- Cheap wins (I2): B1-05 haptics taxonomy (0 raw `HapticFeedback`), B1-12 map camera gated, B1-15 no fake change on
  open, BX-06 loader GIF removed, BX-04 `SecondClock` countdowns, BX-11 `FlyToCartTargets` split.
- Navigation (I3): B2-02 page-type map, shared-axis X forward push (`HeroTransitionPage`; `HeroSharedAxisPage` gone),
  B1-09 shell fade-through arrival (`ShellArrival`), B1-10 tab fade (`ShellTabStack`), predictive back + iOS swipe,
  B2-08 PDP viewer drag-to-dismiss + `PoppableStateFrame`, B1-20 RTL mirroring.
- Ambient (I4): B1-02 `AmbientLoop` + `OnScreenGate` (`GlowPulse`, `HomeLoop` retired; `FloatLoop.glow`), BX-02
  `BrandBackdrop` split, BX-03 shelf rest / pause, shell session re-key fix (`ShellSessionKeyed`).
- Values / cart (I5): B1-01 `RollingNumber` / `RollingNumberText`, B2-01 steppers, B1-11 `CountBadge`, BX-09
  `PopSwitcher`, B2-07 `CatalogCartGestures` + flight parity.
- Entrance / switchers (I6): B1-07 + B1-08 `EntranceCascade` (once per scope; `StaggerEntrance`, `HomeReveal`,
  `ListingReveal`, `ShelfArrivalScope` deleted), B1-06 `FadeThroughSwitcher`, BX-07 `SizeFadeTransition` /
  `CollapseReveal` (`AnimatedAccordion` retired) + `InlineFieldError`, B2-05.
- States (I7): B1-04 `FailureView` / freshness / signed-out (`SignedOutView` deleted), B3-01 shaped skeletons,
  B3-06 `HeroImagePlaceholder`, B1-18 disabled-submit feedback.
- Feedback (I8): B3-03 snack tones + action (`showHeroSnackBarOn`), B3-05 busy failure mark, B2-04 success moments
  (`SuccessBeat`), B3-04 `LocaleSwapVeilHost`, dialog exit (`HeroDialogRoute`), one sheet at a time.
- Feel (I9): B1-16 one press language (`PressScale`, `PressRow`, no stacked presses; `HomePressable` gone), B2-09
  `SegmentedThumbTrack`, BX-08 `VerticalSwapTransition` + budgeted `RotatingLine`, B2-03 `MotionBeat` /
  `DeferredValue` / `AfterArrival` sequencing.
- Assistant (I10 + I11, B1-13): buddy policy (30-minute visit, greeting + 1 follow-up, yields to touch / scroll, wake
  window, motion gate), thought bubble word reveal, tour plays once, chat stream reveal, reply shell without dots,
  chips, proposal flights instead of confetti, thumbs, handoff, voice hold / lock / cancel.
- Screens (I12): B1-14 splash overlaps the Home load (`HomeLaunchPrefetch`, confetti inside the clock), B1-17
  optimistic address delete + Undo, B1-19 About honest, B3-02 brand sheet at once, BX-05 favourites count off the
  2 MB parse.
- Assets (I13, BX-13): all 48 SVGs wired (`HeroSvgGlyph`, `StateArt`, `OfferPlate`, ...); see `asset_manifest.md`.
- Docs (I14, BX-12): `hero_motion_reference.md` rewritten, CLAUDE.md rows, this section.
- Leftovers (I15a): orders reorder flight (`CatalogCartGestures.added`), orders `AnimatedSize` x4 -> `SizeFadeSwitcher` /
  `StaleDataNotice`, stage fill on `AppMotion.drawOn`; support hub / help topics / search discover / category tree
  states; shimmer waits `loaderDelay` (`Skeletonized`); `HomeFrame` keeps the home header across states;
  `SliverStateFade` on the listing; `PdpLateBlock`; Mine header press (`PressScale.onPressChanged`);
  `SecondClockFollower` shared by `HomeCountdownText` and `CountdownDigits`; chat gate reads the composer's typing
  flag (`AssistantTypingScope`); address delete refused after leaving told via `showActionFailureSnackBarOn`; sign-in
  during the launch restore re-keys the shell; order help failure mark; the buddy's hop waits for confetti too.
- Final QA (I15b): the reduced-motion loader breathe (approved with the token retune): under iOS Reduce Motion
  (`reduced && !off`) the loader dots stop orbiting and breathe their opacity 0.4 <-> 1 over `AppMotion.breathe`
  each way (`BrandedDotPainter.opacity` / `breatheOf`; every `AppLoader`, `LoaderDisc`, `BusyOverlay`,
  `BrandedLoader` and the `BrandedRefresh` disc); motion off stays still. Unused APK PNGs and their `HeroAssets`
  constants / pubspec rows removed; 5 stale tests and 1 flaky one fixed.

**Not done, and why**
- `reduced && !off` REPLACE is done per primitive (routes, cascade, rolling glyphs, badges, snacks, dialog, skeleton,
  loaders); `MotionGuard.duration` itself still makes the rest instant (flipping it would change every call site).
- Address delete under `CubitBusyOverlay`: deliberately replaced by an optimistic delete + Undo (approved), like the cart.
- Customer "Not now" on an assistant proposal and its Undo (I11): the live API has only `POST /v1/assistant/actions/{id}/confirm`,
  no reject / undo route. Proposal Confirm colour tween and the loader-after-delay label keep: `AppButton` is core and app-wide.
- Stale-data note on Address list / Edit profile (I7): their device copies carry no timestamp (data-layer change).
- Sheet predictive-back shrink (I8 / I9): the framework sheet route has no hook; needs a custom sheet route.
- OTP -> shell + returnTo push are still two moves when the shell was not in the stack (needs go_router multi-page `go`).
- 28 / 34 dp stepper touch targets (a layout ruling); PDP "+" at stock has no reason line (no room in the pill);
  recipe detail has no on-screen cart, so its adds have no flight (a UI decision).
- Flight thumbnail cache-key mismatch (PB-13): needs CDN size bucketing for every image URL + a device check.
- Assistant: oops / handing-over painter moods reuse existing poses; the voice lock padlock pop is visible about one
  frame (a design choice); the tour scenes still rebuild per frame (PB-07; each demo is behind a `RepaintBoundary`
  and plays once per opening, a rewrite needs a device profile); the buddy wake runs on a Timer, not `AmbientLoop`.
- Collection tabs / category rail: a pinned header's height push stays a snap (the rail fades in); home skeleton ->
  feed is not a true cross-fade (slivers cannot overlap; the feed's cascade / `SliverStateFade` covers it).
- Assets (I13): 12 slots have no sensible home (avatar placeholder, support topic glyphs, ledger kinds, ...).
- LightSweep move to a motion catalogue file: left in `core/widgets`.

## 0. Baseline: what Hero's motion layer does today

Static code read, 2026-09-27. No app running. Paths are under `lib/src/` unless noted. Counts = files outside `core/motion` that use the name.

### 1. Tokens: `core/motion/motion.dart` (`AppMotion`)
- **Durations [FACT, M3 `m3_sys_motion_duration_*` per the comments]:** fast 150 · medium 250 · page 300 · popup 350 · slow 400 · sheetLarge 500. **[FACT, "Mach CSS"]:** microPop 100 · staggerStep 30 · breathe 600 · shineSweep 2000 · glowPulse 5000 (from the website). **[INFERENCE]:** flip 280 · shimmer 1100 · floatLoop 3200 · drawOn 700 · countUp 700 · confetti 1400 · sheen 3600 · loaderOrbit 1200 · loaderDelay 150 · busyMinVisible 500 · carousel 3000 (INFERENCE in `motion.dart:39`, FACT in `docs/hero_motion_reference.md:203`) · 8 splash tokens (`motion.dart:117-141`). imageFade 500 has no tag.
- **Curves:** signature `Cubic(0,0,.2,1)` [FACT legacy_decelerate] · exit `Cubic(.4,0,1,1)` [FACT] · emphasizedDecelerate `Cubic(.1,.7,.1,1)` [FACT] · machEaseInOut `Cubic(.42,0,.58,1)` [FACT] · standard = alias of signature [INFERENCE, departs from M3 standard] · emphasized = `Curves.easeOutBack` [INFERENCE] · decelerate = `Curves.decelerate` (no tag). Scalars: dialogScaleBegin 1.1, popScale 0→1, pageSlideBegin `Offset(0,1)`.
- **Springs are outside AppMotion:** `AppSprings.snappy` (ζ .6, ~320 ms), `.calm` (ζ .9, ~210 ms), `.successHold` 400 ms (`core/motion/spring_curve.dart:64-80`). The doc comment names `AppMotion.springSnappy/springCalm`, which do not exist (`spring_curve.dart:13-14`).
- **Use:** signature 107 refs, fast 73, medium 69, emphasizedDecelerate 50, exit 38. popup, imageFade, dialogScaleBegin and pageSlide* have ≤1 ref each.
- **Provenance:** "decompiled Hero apk `com.sankuai.sailor.afooddelivery`" (`motion.dart:8-9`) is Keeta's package id; the repo-wide rename changed the prose. The navigation files cite "1Day decoded anim" and `MOTION_AND_NAVIGATION.md`, which is not in the repo.

### 2. MotionGuard (`motion.dart:198-215`)
- `reduced()` = `MediaQuery.disableAnimationsOf` (the OS flag) only. `duration()` → zero, `curve()` → linear. There is no in-app setting.
- **Gates:** every core primitive, all 5 page types, the sheet and dialog presenters, the loaders (dots stand still), `Skeletonized` (`SolidColorEffect`), and FlyToCart / confetti (skipped).
- **Does not gate:** haptics (by design, `core/motion/haptics.dart:10-12`); `SecondClock` countdowns (by design); `FadeThroughSwitcher`, which still cross-fades for 150 ms (`fade_through_switcher.dart:32`); Material defaults (SnackBar, the `InkSparkle` ripple at `config/theme/app_theme.dart:56`, TabBar).
- **Screen reader:** 8 feature files add their own `MediaQuery.accessibleNavigationOf` check (home_slides_carousel:53, home_search_hint:64, home_category_grid:80, home_reveal:75, listing_reveal:40, pro_brand_marquee:76, assistant_buddy_greeting:147, assistant_buddy_layer:195).

### 3. Haptics (`core/motion/haptics.dart`)
- **Kinds:** tap = lightImpact, selection = selectionClick, success = mediumImpact, warning = heavyImpact. `Haptics.enabled` (the global mute) has 0 refs, so nothing wires it.
- **Adoption:** 88 calls in 62 files (selection 34, tap 23, success 16, warning 13, fire 2). `PressScale` also fires `HapticKind.tap` on every tap it owns (`press_scale.dart:26,56`; 8 `haptic: null` opt-outs), and ChangeBump, BlockedTapShake (warning) and BrandedRefresh (armed → selection) fire too.
- **Bypasses the policy:** 7 raw `HapticFeedback` calls on add-to-cart paths: `home_product_tile.dart:101,116`, `recipe_detail_view.dart:39`, `recipe_ingredient_tile.dart:108,124`, `listing_product_tile.dart:55,68`.

### 4. Primitive families (`core/motion/`, 36 files)
- **Micro-feedback:** PressScale 70 (0.96, fast) · PopScale 40 (0→1, medium, easeOutBack) · PopSwitcher 11 (snappy spring) · ChangeBump 10 (1.15 peak) · ShakeX 8 + BlockedTapShake 2 (decaying sine, medium) · TintFlash 1 (breathe wash).
- **Value change:** FlipValue 10 (flip 280) · RollingNumber 6 (per-glyph roll, LTR, tabular) · CountUpText 7 (countUp 700).
- **Entrance:** StaggerEntrance 16 (a Timer per item, 30 ms hardcoded at `stagger_entrance.dart:20`, cap 10) · EntranceCascade/Item 2/3 (first frame only, Interval, cap 6) · ScrollReveal 14 (slow, emphasizedDecelerate) · ListItemTransition 1. Feature-local versions: `home_reveal.dart`, `listing_reveal.dart`, `auth_cascade_item.dart`.
- **Switchers / reveal:** FadeThroughSwitcher 26 (page; old child out over the first 35 %; new child scales .92→1) · SizeFadeSwitcher 3 · CollapseReveal 23 · `core/widgets/animated_accordion.dart` 3 (same job as CollapseReveal).
- **Loops / ambient:** FloatLoop 7 (3.2 s, forever unless `count`) · IdleLoop 2 (the mark's cape) · GlowPulse 3 (5 s, forever) · `core/widgets/light_sweep.dart` in 11 feature files (sheen 3.6 s; Timer rest) · RotatingLine 1 (`checkout_bar_line`) · SecondClock/Scope (one timer per page) · BrandBackdrop turn 70 s / breath 13 s (`core/widgets/brand_backdrop_painter.dart:29-30`) · 4 home auto-advance timers on `AppMotion.carousel`.
- **Celebration:** ConfettiBurst in 5 files (rewards, Pro outcome, home first add, assistant celebration, assistant onboarding) · ConfettiOverlay 1 (checkout, order placed) · the splash has its own `splash_confetti_painting`.
- **Cart:** FlyToCart 16 (slow 400, bezier lifted 120 px, 56 px thumb, target stack for the PDP) + the shell badge's PopScale (`features/shell/.../shell_nav_badge.dart:20`).
- **Other:** LocaleSwapVeil (veil fades in over fast, out over medium) · `core/widgets/ready_wipe.dart` 2 (drawOn + band).

### 5. Page transitions (`core/navigation/`, used in `config/routes/feature_routes/*`)
- **HeroTransitionPage** (standard push): slides UP 100 %→0 + fade; push over page/signature, pop over medium/exit. About 40 routes: account ×7, address ×2, assistant history, cart preview, coupons ×2, marketing ×2, notifications, recipes ×2, search shop, shell/home/search/orders/mine, shop ×4, splash, Pro, support ×3, error page.
- **HeroSlideUpTransitionPage:** the same slide-up with signature on both legs. Routes: PDP, PDP image viewer, assistant chat.
- **HeroSharedAxisPage:** 30 px on the X axis + fade, mirrored in RTL. Routes: checkout, vouchers, order tracking / review / invoice. Its doc says login→OTP and Mine→Settings (`hero_shared_axis_page.dart:6-9`).
- **HeroCrossFadePage:** login, OTP. **HeroFadeThroughPage** (fade + 0.96 zoom): splash→shell only. The `navigation.dart` barrel exports neither shared-axis nor cross-fade.
- **Tabs:** an `IndexedStack` with an instant cut; the icon scales to 1.12 (`features/shell/.../shell_nav_item.dart:35,56`). **Not present:** predictive back (`AndroidManifest` has no `enableOnBackInvokedCallback`). There is one `Hero()` (`pdp_photo.dart:39`).

### 6. Sheets, dialogs and snack bars (`core/navigation/navigation.dart`)
- **`showHeroBottomSheet`** (:21, 16 files): `sheetAnimationStyle` in over page (300) or sheetLarge (500), out over medium; signature / exit. **`showHeroDialog`** (:50, 10 files): fade + scale 1.1→1 over medium, `Curves.decelerate`, barrier `Colors.black54`.
- **`showHeroSnackBar`** (35 files): the default Material SnackBar after `hideCurrentSnackBar`. No raw `showModalBottomSheet`, `showDialog` or `ScaffoldMessenger` exists outside `core/navigation`.

### 7. Loaders, skeletons and state views (`core/widgets/`)
- **AppLoader (26):** `DelayedLoaderDisc` waits 150 ms, then fades in with a snappy spring .7→1. It shows a white 96 dp disc with the `BrandedDotPainter` two-dot orbit (1.2 s, code-drawn). `.inline` shows the bare dots; `BrandedLoader` puts the dots on a brand fill.
- **BusyOverlay / CubitBusyOverlay (4/13):** the scrim comes in over slow and leaves over fast, stays at least 500 ms, and blocks back; `done` turns into the `LoaderDoneMark` tick. **BrandedRefresh (19):** `RefreshIndicator.noSpinner` + `RefreshDiscHeader` with the dots.
- **Skeletonized (11):** skeletonizer shimmer at 1100 ms, 6 hand-built layouts. Two loading patterns exist side by side: skeleton vs AppLoader.
- **FailureView** → `HeroStateView.checking` (loader plate) / `.offline` (PopScale on mount) / ErrorView. EmptyStateView and ErrorView pop their icon on mount; HeroStateView's default / error / signedOut do not. StaleAgePill fades over fast; the connectivity bar uses AnimatedContainer + CollapseReveal.

### 8. Assets
- **Icons and files:** the HeroIcon font (27 glyphs, `core/design/hero_icons.dart`) is used in 42 files, against 485 Material `Icons.*` refs. There are 10 SVGs (`assets/svg`: 3 offer, 7 checkout) and 15 PNGs (APK extracts + `market_image.png`). State views use a Material icon on a plate; no state view has an illustration.
- **Painted in code:** HeroMark bag + cape and HeroMarkIdle (the cape ripple), the HeroGlyphs wordmarks (hero / هيرو), 12 GroceryDoodles, and the splash (23 files, 3 variants).
- **GIF:** `assets/animations/hero_design_loading.gif` (2,287,862 B) has 0 refs in lib/, test/ or tool/ but is still bundled by `pubspec.yaml:116` (the comment there still says "brand loader GIF"). No Lottie or Rive.

### 9. Most visible gaps and inconsistencies (facts only)
1. **Every standard push slides up from the bottom**, like a modal, including the tab routes. HeroTransitionPage and HeroSlideUpTransitionPage differ only in the pop curve. The shared-axis doc names routes it is not used on.
2. **Docs drift.** `docs/hero_motion_reference.md` still says the app has no haptics (:173-175, :210). It also names a Lottie splash with `splashZoomBegin`/`splashKenBurns` (:126), a `spin` token (:201), `shader_transition.dart` (:185), `BrandMoment` (:151) and `lib/core/motion` (:5). None of these exist.
3. **Several parallel implementations of one job:** entrance (4 core + 3 feature-local); expand/collapse (CollapseReveal vs AnimatedAccordion); countdown (SecondClock vs CountdownChip's own `Timer.periodic`, `core/widgets/countdown_chip.dart:46`); ticker (RotatingLine vs `home_announcement_ticker.dart:68` and `home_search_hint.dart:71`). The confetti recipe is copied (`confetti_burst.dart:39-64` = `confetti_painter.dart:26-52`).
4. **Endless ambient loops.** `docs/design_system.md` §6 bans ambient loops and allows confetti only when an order is placed, but it covers only search / cart / checkout / orders. Outside that scope: LightSweep ×11, FloatLoop ×7, GlowPulse ×3, BrandBackdrop, and ConfettiBurst ×5.
5. **Stopping off-screen work is done three ways:** TickerMode (the core primitives), `Visibility.of` (`cart_view.dart:68`, `orders_page.dart:101`, mine_*), and HomeRevealScope + VisibilityDetector (home). The SDK's `IndexedStack` does not turn TickerMode off for hidden tabs (`C:/src/flutter/.../widgets/indexed_stack.dart:104-109`).
6. **Accessibility:** reduced motion follows the OS flag only, the screen-reader check is ad hoc in 8 files, the haptic mute is not wired, and 7 raw HapticFeedback calls bypass the policy.
7. **Timing values outside AppMotion:** AppSprings; core/widgets durations (`brand_backdrop.dart:35` 900 ms, `brand_sheet_scaffold.dart:69` 120 ms, `collection_hero_emoji.dart:29` 900 ms); the 30 ms literal in StaggerEntrance; 129 raw `Duration(` in features (many are cache TTLs or timers); 10 raw `Curves.*`; 31 feature files with their own AnimationController (assistant 13, home 6).
8. **Raster cost:** an `Opacity` widget rebuilt every frame in FlyToCart (`fly_to_cart.dart:195`) and GlowPulse (`glow_pulse.dart:83`), plus others (26 `Opacity(` in total), while the core switchers use FadeTransition. There is no real BackdropFilter (the only hit is a comment, `glow_pulse.dart:8`).


## 1. The most important animation / UI trends in 2026

**Trend 1 — Springs replace duration+easing curves as the primary motion system.**
Major platforms now specify motion as a spring (mass/stiffness/damping or duration+bounce) instead of a duration+easing-curve pair. Material 3 Expressive splits springs into two families: spatial springs that can overshoot (position, size, shape, rotation) and effects springs that never overshoot (colour, opacity) [R01-01][R01-02], with per-scheme numeric values published for both a calmer "standard" and a livelier "expressive" scheme [R01-04][R01-05]. SwiftUI's default animation primitive is now `.spring(duration:bounce:)`, with a bounce range of −1 to 1 and about 0.15 read as "brisk" and above 0.4 read as "too exaggerated for a UI element" per Apple's own WWDC guidance [R02-06][R08-35]. Flutter caught up by porting the same duration+bounce spring API and by fixing a discontinuity bug in its underdamped-spring formula [R03-15][R03-16], and the ecosystem has since mapped the M3 spring tokens onto Flutter's `SpringDescription` [R03-20]. Sources: 2023-06 to 2026-05-05.

**Trend 2 — Predictive back becomes the default, gesture-driven page-pop everywhere.**
Android made predictive back (the surface follows the finger, and the gesture can be cancelled mid-drag) the default behaviour for apps targeting SDK 36, replacing the old instant pop [R01-19][R09-07]. The exact numbers are published down to the pixel: exit scales from 100% to 90%, fades at 35% progress, an 8dp edge margin, and a shift formula of (width/20 − 8)dp [R01-17][R09-08]. Flutter shipped a matching `PredictiveBackPageTransitionsBuilder` that mirrors these numbers and carries the gesture's release velocity into a spring [R03-12][R03-17]. This is the best-documented topic in the whole research set (coverage_matrix.md, topic 6) — but no commerce app in scope (Glovo, Talabat, Keeta, Uber, Deliveroo, DoorDash, Instacart, Careem, Noon) publishes its own back-gesture spec; whatever they actually do is **observable-only** (confirmed as an explicit search gap, coverage_matrix.md gap #1). Sources: 2024-10-24 to 2026-09-22.

**Trend 3 — Shape-morphing becomes a state-change idiom, not just decoration.**
Instead of cross-fading between two static shapes, current systems continuously morph one shape into another to signal a state change. Material 3 Expressive ships a shape-morph library where any of its shapes can morph into any other, used on buttons (round → square on press) [R01-07][R01-34] and on button groups (the pressed button widens, neighbours give way) [R01-08]. Apple's SF Symbols 7 does the equivalent for icons: "Magic Replace" swaps an icon's interior while keeping its outer enclosure, so it reads as one continuous shape rather than two icons cross-fading [R02-21], and each SF Symbol animation effect (Bounce, Scale, Pulse, Wiggle, Breathe, Rotate) is documented to carry one specific meaning, not to be mixed [R02-20]. Sources: undated (M3 shape-morph tokens) to 2025-07-28 (SF Symbols 7).

**Trend 4 — iOS 26 "Liquid Glass" layering — documented as behaviour, not as numbers, and criticised on cost.**
Apple's iOS 26 system chrome (toolbars, sheets, menus) now sits on "one functional glass layer" that reacts to touch — glow spreads from the fingertip, controls morph between contexts, sheets grow out of the control that opened them [R02-07][R02-09][R02-10][R02-12]. This is described only in prose: no duration, curve or spring number for any Liquid Glass motion has been published anywhere, confirmed across three separate verification passes (coverage_matrix.md gap #7) — **flag: observable/behaviour-only, any concrete number for it would be a guess.** It also has a measured cost: Liquid Glass measured at 15W/40% GPU versus 8W/20% GPU with the effect off, which is why Apple later shipped a Clear/Tinted toggle [R02-29], and an expert review already calls its self-animating controls "delight [that] turns into distraction on the tenth, twentieth, or hundredth time" [R08-08]. Sources: 2025-06 to 2026-05-08.

**Trend 5 — AI assistants are growing their own motion language, built around ambient glow instead of a spinner.**
Several AI assistants now use a full-screen or edge glow as their "thinking" indicator instead of a small spinner. Gemini's "Neural Expressive" language makes the whole upper half of the screen glow in a colour-cycling gradient while it works [R06-18][R06-19], with the gradient itself carrying meaning (sharp leading edge, diffuse tail, direction mirrors the action) [R06-20]; Siri shows a glowing light around the screen edge while active [R06-22]; Claude's voice mode pulses an orb while listening or speaking [R06-25]. The pattern is real but thinly documented at the vendor level: Gemini's own numbers come from hands-on/observed reporting, not a published spec [R06-19][R06-21], and the ChatGPT, Claude and Copilot examples are known only through press coverage or user reports because those vendors' pages return HTTP 403 to fetching or simply don't publish a motion spec (coverage_matrix.md gap #8) — **flag: largely observable/press-only, not vendor-documented with numbers.** Sources: 2024-06-10 to 2026-07-29.

**Trend 6 — Streaming text gets its own reveal choreography, decoupled from the network.**
Chat UIs now separate "how fast tokens arrive" from "how fast text appears" on purpose. Vercel's AI SDK buffers incoming network chunks and reveals them at a steady pace (about 5ms per character) so a bursty connection doesn't look jumpy [R06-01], and Streamdown fades in only the newly added words while already-rendered text stays static so nothing re-flashes [R06-02]. A Flutter package already ships two named presets that copy specific vendor feels — "ChatGPT" (15ms/char with fade) and "Claude" (80ms/word with fade) — and turns off per-character fade for RTL text specifically [R06-04]. Rebuilds are throttled (about 50ms, capping UI updates near 20/s) independently of how fast the underlying stream runs [R06-05]. Sources: 2025-08-18 to 2026-09-04.

**Trend 7 — Agentic AI adds a "confirm before it acts" motion layer.**
As assistants gain the ability to act (fill a cart, place an order), a consistent trust pattern has emerged: preview the intended action, let the user approve or edit it, and give a way back out. Apple's own generative-AI guidance says to "ask for confirmation before performing a significant action on someone's behalf" and never auto-purchase [R06-11]; Instacart's assistant "does not finalize anything without explicit action" [R06-13]; Amazon's Alexa for Shopping keeps auto-buy behind a free 24-hour cancellation window [R06-14]. An expert-authored pattern catalogue reports concrete adoption numbers for this shape — intent previews accepted without edits over 85% of the time, undo used under 5% of the time [R06-30] — **flag: single non-platform expert source, treat these percentages as directional, not canonical.** Sources: 2025-06-09 to 2026-09-09.

**Trend 8 — Reduced-motion / accessibility is now checked and labelled at the platform level, but delivery apps still ignore it.**
Apple's App Store now scores apps on an "Accessibility Nutrition Label" that names Reduced Motion explicitly, distinguishing decorative motion (must stop) from meaningful motion (must be substituted, not deleted) [R02-27], and WCAG 2.3.3 requires interaction-triggered motion to be switchable off unless essential [R07-01]. Yet none of the six delivery apps checked (talabat, Glovo, Keeta, noon, Careem, HungerStation) declare any accessibility feature — Reduced Motion included — on their own App Store listing, confirmed by reading the store pages directly [R04-21]. Separately, Flutter's `disableAnimations` flag never reads iOS's Reduce Motion setting at all — confirmed in the engine source, only fixed by a PR merged 2026-01-08 — flagged as the single most consequential correctness finding in the whole corpus [R03-24][R07-10]. Sources: 2025-03-07 to 2026-09-28.

**Trend 9 — Progress for long-running tasks moves out of the app, into system-owned live views.**
Delivery tracking is moving off custom in-app progress bars and onto system surfaces the app doesn't fully control. Apple's Live Activities cap themselves at a 2-second animation and own the transition themselves — custom animation modifiers are ignored, views just fade in/out [R05-17][R05-19] — while Uber's own Rider Live Activity uses a deliberately non-linear curve where the last 20% of the bar represents the last 2 minutes, which the team reports cut driver cancellations by 2.26% [R05-16]. Android 16 ships the equivalent as `Notification.ProgressStyle`, with segments for phases, points for milestones, and a tracker icon that can be coloured to match the vehicle [R01-32][R05-21], and Uber Eats already ships its own order tracking this way on Android, shown at I/O 2025 and live by February 2026 [R05-22] — **flag: that last fact is press/observed, not from Uber's own documentation.** Sources: 2024-07-25 to 2026-09-23.

**Trend 10 — Motion decisions are now made against a real frame-and-GPU budget, not just a feel.**
With Impeller now Flutter's default renderer, the framework's own guidance treats several common motion techniques as measured cost items rather than free choices: animating the `Opacity` widget directly rebuilds every frame (use `FadeTransition`/`AnimatedOpacity` or colour alpha instead) [R03-03][R10-06]; `BackdropFilter` blur is "the most expensive common effect" unless grouped — one team measured 11.2ms ungrouped versus 3.9ms grouped for the same blur [R03-06][R10-09]; `saveLayer` is named as "particularly disruptive on mobile GPUs" [R10-05]. This isn't purely theoretical: Impeller's Vulkan path shows real regressions on some Adreno GPUs during ordinary page-push transitions, with stalls of 26–166ms observed against open issues [R03-08] — **flag: observed from open bug reports, not a vendor-published benchmark.** Sources: 2025-02-12 to 2026-09-26.

**Trend 11 — Skeleton/shimmer has replaced the spinner as the default "it's not stuck" signal, inside published wait-length thresholds.**
Research and shipped code agree on the same shape: show nothing under about 1 second, show a skeleton or spinner for 2–10 seconds, and only use a determinate progress bar past 10 seconds [R08-11][R08-13]. Two production storefronts confirm the shimmer itself is a cheap, looping gradient sweep — Uber Eats runs a 2-second viewport-wide linear shimmer so every placeholder sweeps in phase [R05-06], Instacart runs a 1.1-second transform-based shimmer [R05-07] — and guidance adds an anti-flicker rule of its own: a short show-delay plus a minimum visible time, so a fast response never causes a one-frame flash of loading state [R08-12]. Sources: 2023-06-04 to 2026-09-28.

---

## 2. Examples

Where a row's Confidence is "observed" or "inferred", the pattern was read off shipped code, a press report or a teardown — no written motion spec exists for it. Rows marked **observable-only** mean the feature is confirmed to exist but nothing beyond a screen recording would show its actual motion.

| Pattern | App / product | Screen | What it does | Evidence ID | Confidence |
|---|---|---|---|---|---|
| Spring physics as default | Material 3 Expressive (Android/Compose) | all M3 components | spatial springs move position/size/shape; effects springs move colour/opacity only, never overshoot | R01-02 | documented |
| Spring physics as default | SwiftUI | any view, via `.spring(duration:bounce:)` | duration+bounce spring replaces curve+duration as the default animation call | R02-06 | documented |
| Spring physics as default | Flutter | any custom animation, `SpringDescription.withDurationAndBounce` | ports the SwiftUI duration+bounce API into Flutter's physics system | R03-15 | documented |
| Predictive back | Android 16 (system) | back gesture, all opted-in apps | previous screen scales/fades as the user drags back, can be cancelled mid-gesture | R09-08 | documented |
| Predictive back | Flutter (Material) | any route on Android 14+ | surface follows the finger, min scale 0.90, commits at 400ms | R03-12 | documented |
| Predictive back | Talabat / Glovo / Keeta (delivery apps) | back gesture, all screens | no motion spec published anywhere for these apps | — | **observable-only** |
| Shape morph | Material 3 Expressive | button press, FAB menu, split button | shape morphs corner radius/geometry as state changes, e.g. round → square on press | R01-07 | documented(source) |
| Shape morph | SF Symbols 7 (iOS 26) | icons across system apps | "Magic Replace" morphs an icon's interior while keeping a shared enclosure | R02-21 | documented |
| Liquid Glass layering | iOS 26 (system bars, sheets, menus) | toolbar, sheets, menus | one functional glass layer, no glass-on-glass, 35% dim layer | R02-07 | documented (no timing numbers given) |
| Liquid Glass cost | macOS/iOS Liquid Glass | any glass surface | measured 15W/40% GPU vs 8W/20% GPU with glass off | R02-29 | observed |
| AI thinking-state glow | Gemini app (Neural Expressive) | prompt/response screen | upper half of screen glows in a colour-cycling gradient while processing, replacing a spinner | R06-19 | observed(hands-on) |
| AI thinking-state glow | Siri (iOS 18.1+) | anywhere Siri activates | glowing light wraps the screen edge while active | R06-22 | documented+observed |
| AI voice UI | Gemini Live | voice mode | waveform housed in a centred pill, with mute and close | R06-24 | documented+observed |
| AI voice UI | Claude mobile | voice mode | orb glow pulses while listening/speaking, push-to-talk, ~5s silence auto-sends | R06-25 | observed(user reports) |
| AI voice UI | ChatGPT | voice mode | voice moved into the chat thread with a live transcript; full-screen orb now optional | R06-23 | documented(press only — vendor pages return 403) |
| AI opt-in mascot | Microsoft Copilot ("Mico") | voice sessions only | optional character shown only in voice sessions, not across the app | R06-17 | documented(press) |
| Streaming text reveal | Vercel AI SDK / Upstash chat demo | any chat UI | buffers network chunks, reveals at ~5ms/char steady pace | R06-01 | documented |
| Streaming text reveal | flutter_streaming_text_markdown (pub.dev pkg) | Flutter chat UI | "ChatGPT" preset 15ms/char, "Claude" preset 80ms/word; per-char fade off for RTL | R06-04 | documented |
| Agentic trust: review-first cart | Instacart AI assistant (Clementine) | cart-build flow | assistant builds a cart but does not finalize without explicit user action | R06-13 | documented(company) |
| Agentic trust: cancel window | Amazon Alexa for Shopping (Rufus) | auto-buy flow | auto-buy carries a free 24h cancellation window | R06-14 | documented(company) |
| System-owned live progress | Uber Rider app | trip tracking, iOS Live Activity | non-linear progress curve, last 20% of bar = last 2 minutes; server-debounced | R05-16 | documented |
| System-owned live progress | Uber Eats (Android) | order-tracking notification | ships as an Android Live Update, shown at I/O 2025, live by Feb 2026 | R05-22 | observed(press) |
| Skeleton/shimmer loading | Uber Eats web (production) | home page | viewport-wide 2s linear shimmer, every placeholder sweeps in phase | R05-06 | observed(live CSS) |
| Skeleton/shimmer loading | Instacart web storefront (production) | storefront | transform-based 1.1s shimmer, translate3d −75% to 75% | R05-07 | observed(live CSS) |
| Skeleton/shimmer loading | talabat | home / listing / checkout | skeleton loading, order-confirmation animation, collapsing headers described, no numbers given | R04-15 | observed(low-credibility teardown) |
| Performance-first motion | Flutter (Impeller) | backdrop-filter blur (frosted bars/sheets) | `BackdropGroup` shares one blur op: 11.2ms ungrouped vs 3.9ms grouped, same effect | R03-06 | documented |
| Performance-first motion (negative) | Flutter on Adreno GPUs (Snapdragon) | page-push transitions | Vulkan regressions cause 4–12 stalls of 26–166ms each during the transition | R03-08 | observed(open issues) |
| In-place add-to-cart feedback | Amazon Shopping iOS | search results | button becomes "1 in cart" with minus/plus at the point of the tap | R05-32 | observed(design critique) |
| Persistent cart tracker | Instacart Storefront native apps | every shopping screen | floating cart bar above bottom nav tracks progress toward up to 3 incentives | R05-30 | documented |
| Illustration motion via Lottie | Deliveroo consumer order tracker | order tracking | per-stage illustrated tracker animations, GIF→Lottie migration, 81% smaller files | R05-14 | documented |

---

## 3. Patterns worth adopting, and why

Cost columns are short: **perf** = frame/GPU/battery load, **cognitive** = load on the user's attention, **a11y** = what a reduced-motion / assistive-tech user needs from it.

| Pattern | UX problem solved | Evidence IDs | Cost (perf · cognitive · a11y) | Hero token/primitive (§9 (decision summary)) |
|---|---|---|---|---|
| Spring physics for spatial motion only (never opacity/colour) | continuity, feedback | R01-02, R03-15, R03-20, R08-35 | perf: low, native and interruptible · cognitive: low, feels physically consistent · a11y: needs a reduced-motion swap | `AppSprings.snappy` ζ.6 k800, `AppSprings.calm` ζ.9 k700 (decision #5) |
| Duration ladder scaled to element size/reach | perceived speed, orientation | R08-04, R08-05, R09-26, R04-22 | perf: low · cognitive: low, predictable · a11y: feeds `MotionGuard` scaling | `AppMotion` microPop 100 / fast 150 / medium 250 / page 300 / slow 400 ceiling (decision #2) |
| Predictive back / interruptible gesture-driven pop | continuity, orientation | R09-07, R09-08, R03-12, R03-13 | perf: moderate, needs manifest flag + route support · cognitive: low, reduces "where am I" confusion · a11y: gesture-based, no seizure risk | predictive back + iOS swipe on all page types (decision #11, pending approval) |
| Shared-axis push for forward navigation, mirrored in RTL | orientation, continuity | R09-01, R02-02 | perf: moderate · cognitive: low · a11y: fine under fade-replace | `HeroTransitionPage` as shared axis X, 30dp + fade, page 300 (decision #8) |
| Fade-through for unrelated top-level destinations | orientation | R09-02, R09-04 | perf: low · cognitive: low, avoids a false spatial relationship · a11y: fine | `HeroFadeThroughPage`, 0.92 settle (decision #10) |
| Numeric roll/count with direction-from-delta | state change, attention | R02-19, R08-27, R08-28 | perf: low, digit-level tween · cognitive: low, prevents change blindness · a11y: paired with the value text, not the only signal | `RollingNumber` (decision #13, #20) |
| Optimistic, in-place add-to-cart with a persistent badge (not a transient overlay) | feedback, state change | R08-20, R05-32, R05-30 | perf: low · cognitive: low, stays readable · a11y: avoids the toast problems in R08-21 | `PopSwitcher` → `FlyToCart` → badge `ChangeBump` + roll on land (decision #16) |
| Skeleton for known-structure content only, cross-fades to real content, gated by wait length | perceived speed | R08-11, R08-12, R08-17, R05-06 | perf: bounded, a cheap gradient sweep, not per-frame rebuild · cognitive: low · a11y: never the only "not stuck" signal (paired with real content arriving) | skeleton→content fast cross-fade, `loaderDelay` 150 rule (decision #17, #18) |
| List entrance cascade, first load only, capped item count | attention, delight without becoming noise | R08-07, R08-08 (repetition risk) | perf: bounded (max 6 staggered items) · cognitive: avoids "distraction on the tenth time" · a11y: needs the WCAG 2.2.2 rest+pause | `EntranceCascade`, 30ms × max 6 (decision #4, #17, #23) |
| Ambient/decorative loops bounded and gated off-screen/hidden/reduced | attention without fatigue | R06-35, R07-03, R08-09 | perf: high if left unbounded (battery, hidden-tab ticker leaks) · cognitive: low once bounded · a11y: satisfies WCAG 2.2.2 | `ambientBudget` 5000, `OnScreen` gate, `AmbientLoop` engine (decision #14, #19) |
| Reduced motion = replace, not delete (fade instead of slide/zoom; loops breathe, don't freeze) | a11y continuity | R02-26, R07-05, R08-16, R07-11 | perf: neutral · cognitive: keeps meaning intact · a11y: fixes the iOS `reduceMotion` gap in R03-24 | `MotionGuard` reduced = REPLACE, off = instant (decision #7) |
| Haptics tied to outcome semantics, fired at the visual contact moment, one per gesture | feedback, delight without buzz fatigue | R01-27, R02-22, R07-31, R08-33 | perf: negligible · cognitive: must stay rare on frequent actions (R07-29) · a11y: stays optional, respects the system setting (R07-30) | `Haptics` intent helpers, selection/tap/success/warning taxonomy (decision #21) |
| Loading indicator show-delay + minimum-visible time | perceived speed, anti-flicker | R08-12 | perf: trivial · cognitive: avoids a one-frame flash reading as jank · a11y: n/a | `loaderDelay` 150, `busyMinVisible` 500 (decision #3, #18) |

---

## 4. Patterns to avoid, and why

| Pattern | Why (cognitive load / a11y / performance / brand) | Evidence IDs | What Hero does instead |
|---|---|---|---|
| Duplicate, per-feature motion primitives (one-off loop/press/reveal widgets per screen) | brand/consistency: a shared system measurably beats local re-implementation ("3x faster dev, 4x fewer visual parity issues, 50% less code"); a small deliberate token scale avoids choice pile-up | R05-27, R05-36, R04-14 | 9 per-feature primitives merged into shared ones: `HomeLoop`→`AmbientLoop`, `HomePressable`→`PressScale`, `HomeReveal*`/`ListingReveal*`→`EntranceCascade`, `StaggerEntrance`→`EntranceCascade`, `LedgerRowEntrance`→`EntranceCascadeItem` (decision #14) |
| Looping/ambient motion with no stop condition | a11y: WCAG 2.2.2 requires pause/stop/hide past 5s · performance/battery: hidden-tab tickers keep animating and draining battery if not muted | R06-35, R07-03, R10-18, R10-19 | `ambientBudget` 5000ms hard stop, `OnScreen` gate, `TickerMode(false)` on hidden tabs (decision #11, #14, #19) |
| Auto-advancing carousels / rotating hint text with no pause control | a11y/cognitive load: carousels need a pause/resume control and must pause on hover/focus; "if eyes are drawn to it, it's too much" | R07-23, R08-09 | `heroAutoAdvance` and `searchHintRotate` tokens explicitly retired (decision #6) |
| Relying on Flutter's `disableAnimations` alone for reduced motion | a11y correctness bug: it never reads iOS Reduce Motion at all, confirmed in engine source (HIGH severity) | R03-24, R07-10 | `MotionGuard` checks `disableAnimations` OR iOS `reduceMotion` explicitly, not the flag alone (decision #7) |
| Glass-on-glass / undocumented-cost visual layering (Liquid-Glass-style stacking) | performance: measured 15W/40% GPU vs 8W/20% GPU · brand: no timing numbers published anywhere means it can't be reproduced faithfully, and reviewers already call it distraction after repeated exposure | R02-29, R08-08, coverage_matrix.md gap #7 | no parallel system — extend `AppMotion`/`MotionGuard` only, no new layering system (decision #1) |
| Count-up-from-zero applied broadly / on every screen open | cognitive load: loses its "earned" meaning if used as a generic entrance effect instead of a rare signal | R08-27 (value-change guidance favours quick roll, not a spectacle, for ordinary changes) | `RollingNumber` rolls by delta direction for ordinary changes; `CountUpText` reserved to earned amounts only, never count up from 0 on open (decision #4, #20) |
| Springs on opacity/colour transitions | brand/feel mismatch: effects springs are already tuned to ζ1.0 (no overshoot) specifically because a bouncy colour/opacity change reads as a bug, not delight | R01-02 | opacity and colour never use a spring (decision #5) |
| Unbounded/ungrouped backdrop blur or `saveLayer` stacks in animated sheets | performance: named as "particularly disruptive on mobile GPUs"; one team measured 11.2ms ungrouped vs 3.9ms grouped for the same blur | R10-05, R10-09, R03-06 | at most one `LightSweep` per screen, ≤2 passes; blur/backdrop effects grouped when used (decision #13, #19) |



## 5. The recommended motion direction for Hero

**In one line:** Hero should feel like a calm, quick shop assistant. Things react the moment you touch them, move in the direction you are going, and then keep still.

**What we keep.** The brand stays as it is: the green, the cape amber, the cart button, the two-dot loader, the splash, the category shelf wash and glide, and the assistant buddy. The token layer (`AppMotion`, `MotionGuard`, `Haptics`) is sound, and every controller is already gated for reduced motion (C2 table B). We do not add a second system. We shrink the first one and make each part do one job.

**What changes, in plain words:**
1. **Screens move the way you navigate.**
   - Today about 40 routes rise from the bottom like a sheet, including plain drill-downs and the tab routes (baseline §5, A09 11.1).
   - Going deeper will slide sideways, mirrored in Arabic.
   - Opening something you will close again (product page, image viewer, assistant chat, search) will rise from the bottom.
   - Jumping between unrelated places (splash → home, sign-in → home, tabs) will fade.
   - This is how iOS, Android and Material separate hierarchy from modality [R09-05][R01-16][R09-04][R02-02].
   - Android 16 turns predictive back on by default, so pages must follow the back gesture [R01-19][R09-07][R03-14].
2. **Feedback is immediate and small.**
   - A press shows within 100 ms at a scale of 0.97 [R08-02][R05-08][R08-03].
   - Add-to-cart changes the button in place and flies a thumbnail to the cart.
   - The badge bumps when the thumbnail lands, not before (A07 #6, A10 #11) [R05-32][R08-20].
3. **Numbers roll, they do not count from zero.**
   - Prices, totals and quantities roll their digits in the direction of the change [R02-19][R08-28].
   - A count-up is kept for an amount the user just earned. It never runs again each time a screen opens (A01, A07 #5).
4. **Waiting looks like progress, never like a show.**
   - Known layouts get a skeleton. Unknown ones get the brand loader after 150 ms [R08-12][R08-11].
   - Content that is ready cross-fades in at once.
   - A list cascades only on its first load: at most 6 items, 30 ms apart [R05-10].
   - It never replays on scroll-back and never plays under a page transition (P3-1, P3-2, A01).
5. **Still when idle.**
   - A decorative loop stops after 5 s of total motion, and when it is off screen, on a hidden tab, in the background, or under reduced motion [R07-03][R08-08][R10-19].
   - Loaders and the real "working" states are the only endless motion [R07-04].
   - Today Home keeps animating behind other tabs (P1-1, High).
6. **Delight is rare and earned.**
   - Confetti plays when an order is placed, on the first add of a session (Home, a kept decision), when Pro is subscribed, and when a reward is earned.
   - It plays at most once per moment and is skipped under reduced motion [R08-32][R08-23].
7. **One haptic language.**
   - `selection` for picking and adding, `tap` for committing and removing, `success` for significant completions, `warning` for refusals and destructive confirms, and nothing on navigation [R02-22][R07-29][R01-30].
   - All haptics go through `Haptics` (7 raw calls today, C2 #4). None are fired from a cubit (C2 #5).
8. **Reduced motion means "replace", not "delete".**
   - Movement becomes a short fade, meaning survives, and haptics stay [R02-26][R07-05][R07-08][R07-32].
   - Flutter's `disableAnimations` does not see the iOS Reduce Motion switch, so `MotionGuard` must read both [R07-10][R03-24].

**Numbers to remember:** 100 ms press, 150 ms fades, 250 ms component changes, 300 ms pages and sheets, 400 ms ceiling for anything functional; exits are shorter than entrances [R09-26][R04-22][R08-05].

**No new packages.**
- Flutter ships no M3 Expressive motion, so we own two springs through `SpringDescription` [R09-21][R03-15][R03-20].
- The `animations` package would duplicate code we already have [R03-22].
- Lottie and Rive have only vendor-sourced benefits, and no 2024-26 Flutter benchmark exists [R10-27][R09-30]. Any Rive case for the buddy belongs in the Assistant spec.
- The unused 2.29 MB GIF should go (C2 #14, P3-9). Animated GIFs re-decode on every loop [R10-23].

**Findings on kept decisions** (raised, not changed silently):
- **Category shelf wash and auto-glide.** Every visible tile repaints every frame with no rest (P2-M2). It also holds the engine at full refresh rate while Home sits idle (P3-7). Auto-moving content must stop within 5 s or be pausable [R07-03][R07-23].
  - Keep the look.
  - Add a rest after 5 s, a pause on touch, a stop when off screen or on a hidden tab, and a still frame under reduced motion or with a screen reader.
  - **[BEHAVIOUR CHANGE]**
- **Splash.** It plays for 2.25-3.4 s on every cold start, cannot be skipped, and no data load overlaps it (A02, P3-10). The HIG says "launch instantly" [R02-28].
  - Keep the splash motion.
  - Start the Home load in parallel with it.
  - Consider letting a tap skip it. **[BEHAVIOUR CHANGE]**
- **Assistant buddy.** The layer has no `RepaintBoundary` (P2-H2), and several loops run while it is hidden (A03). → see Assistant spec.
- **No basket bar on Home when the cart has items.** Nothing found in Hero shows a UX problem. Instacart's floating cart [R05-30] is a different product choice, not evidence against ours. Keep it.

---


## 6. Specific ideas for Hero's existing UI

Per screen, from the Phase 2 audit (Appendix A). Each idea names the UX problem, the pattern / primitive / token, the evidence and whether it changes behaviour.


Screens: account ×8, splash, main shell, login, OTP verify, address list, address edit, assistant ×3 +
onboarding (18 total, same set as Appendix A). Each idea: **idea** · UX problem solved ·
pattern/primitive/token · evidence ID · behaviour change (yes → needs approval, folded into
§9 (decision summary) §24's list where it isn't already there; no → same visible shape, safe to ship
as a refactor). For the assistant screens, §9.6 (AI assistant motion spec) already designed these — entries here
point at its section/approval-item number rather than re-deriving.

---

### Mine (tab)
- Unify wallet/points/coupon number motion on one `RollingNumber`-style primitive · problem: 3 disagreeing number primitives on one stats row read as 3 different products · `RollingNumber` (D13) · R08-27, R08-28 · **yes**
- Cap and gate the invite-banner and PRO-pill shine loops with `ambientBudget` + `OnScreen` · problem: both loop forever, including offscreen, and the invite banner loops toward an unbuilt placeholder route · `AmbientLoop`/`OnScreen` gate (D14, D19) · R06-35, R07-03, R08-09 · **yes**
- Give the header/sign-in-pill tap a press state and haptic · problem: the whole header is a button with no press feedback, the guest "Sign in" pill looks tappable but isn't · `PressScale` (D22) · R08-02 · **yes**
- Replace the badge's pop-from-0/cut-at-0 with an enter/exit via `ChangeBump` · problem: 0→N and N→0 have no transition at all · `ChangeBump` (D13) · R08-28 · **yes**
- Add `loaderDelay` before the first paint · problem: a blank first frame reads as a stutter before the cascade · `loaderDelay` (D18) · R08-12 · yes (minor)

### Wallet
- Fix the success-haptic sign check so it only fires when the balance goes up · problem: `success` fires on a balance drop too · Haptics taxonomy (D21) · R07-26 · **yes**
- Size-transition the stale-data pill's insertion instead of an instant push · problem: the list jumps when the pill appears · `SizeFadeSwitcher`/`CollapseReveal` (D13) · R10-22 · yes (minor)
- Sequence the row cascade to start after the `FadeThroughSwitcher` settles, not concurrently · problem: two entrance systems move at once, often under the page slide too · `EntranceCascade` + D17's cascade rule · R09-26 · yes (minor, timing only)
- Tokenise `page*5` / `slow*2.5` / `fast~/5` onto the named duration ladder · problem: drift from the shared token scale · D2/D3 · R05-36 · no (same numbers, just named)

### Loyalty points
- Apply `RollingNumber` to the loyalty balance instead of static text · problem: the same points value animates 4 different ways across Mine/Wallet/Loyalty/Rewards · `RollingNumber` (D13) · R08-27 · **yes**
- Gate the shine + float loops with `OnScreen` + `ambientBudget`, cap at one `LightSweep`/screen · problem: two forever loops on one tile, neither visibility-gated · D14, D19 · R06-35, R08-09 · **yes**
- Fix `FloatLoop`'s doubled-period bug at the core level (affects every consumer, not just this screen) · problem: the gift badge bobs at 6.4s though the primitive's own docs say 3.2s · core `FloatLoop` · n/a (internal correctness) · yes (visibly slower today than intended)

### Loyalty rewards
- Drop count-up-from-0 on every open, roll from the real value like every other balance in the app · problem: a direct violation of "never count up on open," a 700ms wait before the real number is readable · `RollingNumber` (D13, D20) · R08-27 · **yes**
- Cap the ambient-loop budget (the glow plus up to 4 floats) and gate every one offscreen · problem: 5 forever tickers running with no idle frame while the page is open · D14, D19 · R06-35, R07-03 · **yes**
- Reserve confetti for a rare/earned redemption; a routine confirm gets a border-tween + check + badge bump instead · problem: confetti + haptic + snack + chip fire on every ordinary discount apply · same pipeline shape as add-to-cart (D16) · R08-32 · **yes (needs approval)**
- Adopt `FailureView` + `HeroStateView.signedOut` + `DataFreshness` · problem: the offline contract is missing entirely (CLAUDE.md §3.2) · core contract, not a §9 (decision summary) token · n/a (architecture rule) · **yes**
- Reuse `BlockedTapShake` on a locked-card tap, and fix the failed-redeem snack to `showFailureSnackBar` · problem: a locked card is a silent dead tap, and a failed redeem toasts the transport text while the connectivity banner already speaks · `BlockedTapShake` (D13) · R08-24, R08-26 · yes (minor)

### Settings
- Fix the log-out haptic to a single `warning`, drop the extra `tap` right before it · problem: two haptics for one confirmed, destructive action · Haptics taxonomy (D21) · R07-26 · **yes**
- Align the log-out dialog and locale veil to `signature`/`exit` · problem: the only two places in the app still on `decelerate` + a linear fade · D5 · R09-26 (systems agree on paired entrance/exit curves) · no (curve swap, same durations)
- Standardise row press feedback (ripple, matching Settings) across Mine's menu rows too · problem: the same visual row family reacts differently to touch on two screens in the same feature · `PressScale`/`InkWell` convention (D22) · R08-02 · yes (needs approval — touches Mine as well as Settings)

### About
- Retire the every-visit logo pop-with-overshoot; play it once, on the first-ever view · problem: delight decays into distraction with repetition on a static brand mark · `PopScale.onMount` gated to first-run (D13) · R08-08 · **yes**
- Replace the "Rate us" thank-you snack with a real store link, or remove the promise · problem: fake feedback — the snack claims an action that never happens · n/a (correctness, not a motion pattern) · R08-26 · yes (product fix, not a token change)
- Unify copy feedback with Delivery code's inline "Copied" flip instead of a snack · problem: the same action (copy) gives two different kinds of feedback in one feature · `FlipValue` (D13) · R08-21 (inline persists, toast is weaker for a11y) · yes (minor)

### Delivery code
- Suppress the digit flip on first load, only animate a real change · problem: the digits flip as if the code just changed, when it only just finished loading · generalises D20's "never fake a change on open" to any glyph reveal · R08-27 · **yes**
- Add a skeleton for the loading state and a visible error state · problem: the screen fails silently today — no loading language, no error UI at all · `Skeletonized` (D18) · R08-11 · **yes**
- Match Profile's save-success language (haptic + check) instead of a plain snack · problem: a similarly significant save gets a much smaller acknowledgement · D21, `PopScale` check (D13) · R08-23 · yes (minor)

### Edit profile
- Adopt a skeleton for the initial load instead of a loader disc · problem: loading language is inconsistent with Wallet/Loyalty on the same feature · `Skeletonized` (D18) · R08-11 · yes (minor)
- Adopt `FailureView` on the first-load error · problem: the offline contract is missing, same gap as Rewards · core contract · n/a (architecture rule) · **yes**
- Decide and implement RTL mirroring for the completion ring · problem: the ring always sweeps clockwise from 12 o'clock regardless of locale · needs an explicit design decision · R02-02 (spatial consistency, mirror for RTL) · **yes (needs approval)**

### Splash
- Start the Home feed fetch during the intro instead of only after hand-off · problem: nothing overlaps a 2.3-3.4s non-skippable wait; `HomeCubit` isn't created until after splash · matches §9 (decision summary)'s own finding (D23) · R08-15 · **yes (needs approval, already flagged)**
- Cap the confetti run inside the fixed clock so it never freezes mid-burst · problem: confetti visibly cuts at ~65-67% under the fade-through, in every variant · tokenise the burst to fit inside the total (D2/D3) · n/a (bug) · yes (minor, cosmetic fix)
- Decide RTL mirroring of the flight direction, and a skip affordance · problem: no RTL code at all despite an Arabic wordmark; no skip on any cold start · already on §9 (decision summary)'s approval list (D24) · R02-02, R08-01 (attention limit) · **yes (needs approval, already flagged)**

### Main shell
- Give the incoming tab a `fast` fade on switch — §9 (decision summary)'s own answer to this exact question · problem: tab switch is the one hard cut on a screen where the cart pill and coupon tabs both animate · D11 · R09-02 · **yes (needs approval, already flagged)**
- Replace the badge's pop-from-0/cut-at-0 with `ChangeBump` + roll-on-land · problem: enter/exit asymmetry, and one add pops two badges at once when Cart is open · D16 · R08-28 · **yes**
- Make every `go(Routes.shell)` caller arrive on the same page type as a cold start · problem: the shell route gets replaced and every tab resets on sign-in, coupon "use" and the Pro top bar · D10 (`HeroFadeThroughPage`) · n/a (architecture) · **yes (needs approval)**

### Login
- Bound the three idle-form loops (backdrop turn/breath, lockup, waving mark) with `ambientBudget`, and fix the waving mark's missing `running` flag · problem: an idle sign-in form animates forever; one loop keeps scheduling frames even while its card is folded to zero height · `AmbientLoop`/`OnScreen` (D14, D19) · R06-35, R08-09 · **yes**
- Collapse the two stagger systems onto `EntranceCascade`, tokenise the 50ms step to 30ms · problem: two different cascade engines exist side by side in one app · D14, D17 · R05-36 · yes (visible step-timing change)
- Give the valid-check and Continue's grey-revert an animated exit instead of a cut · problem: enter/exit asymmetry on two elements on the same screen · `PopScale`/`ReadyWipe` reverse (D13) · R09-25 (exits shorter, not absent) · yes (minor)

### OTP verify
- Give a disabled Verify tap the same blocked feedback as Login's Continue · problem: OTP is the one step in the sign-in flow with zero feedback on a blocked submit · `ShakeX` + `warning` (D13, D21) · n/a (internal consistency) · **yes**
- Fold the two `returnTo` slides (new shell + Pro page) into one sequence · problem: two vertical sheets rise one frame apart after a Pro-flow verification · part of the shell-arrival unification (D24) · n/a · **yes (needs approval)**
- Flip the countdown digits instead of snapping, matching Home's countdown · `FlipValue` (D13) · R08-28 · yes (minor)

### Address list
- Stop the row stagger replaying on scroll-back/re-mount; cap it to the first screenful · problem: a direct D17 violation, jars during ordinary scrolling and on a delete-triggered rebuild · `EntranceCascade`'s "first load only" rule (D17) · n/a (internal rule) · **yes**
- Switch delete to optimistic — remove at once, reconcile, roll back on failure · problem: a pessimistic, blocking (≥500ms) delete on the one list in the app that isn't optimistic; the cart already is · pattern, not a named primitive · R08-18 · **yes (needs approval — changes the delete flow's risk profile)**
- Fix the destructive-delete-confirm haptic to `warning` · problem: a taxonomy violation — a light `tap` on a destructive confirm · D21 · R07-26 · yes (minor)
- Adopt `FailureView` + `DataFreshness` · problem: the offline contract is missing on a device-copy list · core contract · n/a · **yes**

### Address edit (map)
- Swap the null-origin `AnimatedPositioned` SELECT↔FORM snap for `SizeFadeSwitcher`/`CollapseReveal` · problem: the code's own class doc promises a rise that a Flutter implicit-tween limitation prevents · D13 · n/a (bug) · yes (cosmetic fix, matches documented intent)
- Gate every `animateCamera` call behind `MotionGuard` · problem: the only reduced-motion gap found across all 18 screens — the map ignores the setting entirely · D7 · R07-05 · **yes**
- Unify the tag-chip pattern with Profile's gender chip (tint + spring, `selection` haptic) · problem: two different chip languages two screens apart in the same account/address flow · D13, D21 · n/a (internal consistency) · yes (minor)
- Give Confirm-location a loading state and save success a check + haptic · problem: a dead tap during network work, and a save with no success motion at all, unlike every other save flow in the app · `AppButton(loading:)`, `PopScale` check (D13, D21) · R08-23 · **yes**

### Assistant buddy layer (shell overlay)
- Replace the 30s-after-every-touch ambient scheduler with a bounded wake window · problem: the mascot never truly rests beside shopping content · `BuddyMotionGate`/`ambientBudget` (§9.6 (AI assistant motion spec) §3, D19) · R06-35, R08-09 · **yes (assistant.md approval #5)**
- Default every mascot instance to `alive:false`, matching `AssistantAvatar` · problem: verification found 2 extra ambient mascots (greeting header, hide sheet) blinking out of phase, sometimes two at once under the hide sheet · §9.6 (AI assistant motion spec) §1 "Defaults" · n/a (internal consistency) · **yes (assistant.md approval #5)**
- Cancel the greeting countdown off-stage instead of letting a muted ticker run it out · problem: a greeting can close itself and log as "ignored" purely because the user was on another page, feeding the 7-day back-off unfairly · §9.6 (AI assistant motion spec) §3.4 · WCAG 2.2.1 analogue (R08-21) · **yes (bug fix, assistant.md approval #16)**

### Assistant chat (conversation, stream, composer + voice)
- Replace confetti-on-every-confirm with `FlyToCart` + badge bump, matching an ordinary add · problem: two different "went into the cart" motions on one screen, and confetti isn't rare/earned · §9.6 (AI assistant motion spec) §2.6 · R08-32 · **yes (approval #10)**
- Reveal streamed words with a fast per-word fade instead of 50ms-burst pop-in · problem: bursty word arrival makes the reply visibly "jump" · `AssistantWordReveal` (§9.6 (AI assistant motion spec) §2.3) · R06-01, R06-02 · **yes (approval #17)**
- Fix the voice hold-start haptic from `success` to `selection` · problem: "success" semantics fired for simply starting to record · Haptics taxonomy (D21) · R07-26 · **yes (approval #13)**

### Assistant history
- Swap the plain `switch` state change for `FadeThroughSwitcher`, matching Ledger/Cart · problem: the one assistant screen with an otherwise-correct offline contract still snaps between states · D17 · R09-02 · yes (minor)
- Swap `EmptyStateView` + lock for `HeroStateView.signedOut` · problem: inconsistent with Orders/Checkout's signed-out treatment · core widget swap · n/a · yes (minor)

### Assistant tour (onboarding sheet)
- Play each step's demo once per sheet open, not on every return · problem: swiping back and forth restarts the demos endlessly · §9.6 (AI assistant motion spec) §2.12/§3.4-style "kept" gate · R08-08 · **yes (assistant.md, tour demos)**
- Fix the perch lean to interpolate continuously across the page boundary · problem: the lean visibly flips sign at every half-swipe, confirmed by the arithmetic · n/a (bug fix) · R02-04 (continuously interactive, a gesture is never cancelled mid-way) · yes (bug fix)
- Delay a leaving step's demo reset until it's fully off-screen · problem: the step being swiped away from visibly resets to empty while still half-visible · n/a (bug fix) · n/a · yes (bug fix, PLAUSIBLE)



Screens: cart preview, cart tab, checkout, checkout vouchers, history coupons, my coupons, home,
search, content, offers, notifications, order invoice, order review, order tracking, orders,
customer-service hub, help topics, rider chat, PDP image viewer, product detail, recipe detail,
recipes, Pro membership (23 total, same set as Appendix A). Each idea: **idea** · UX
problem solved · pattern/primitive/token · evidence ID · behaviour change (yes → needs approval,
folded into §9 (decision summary) §24's list where it isn't already there; no → same visible
shape, safe to ship as a refactor). Where an idea repeats a Part-1 candidate's root cause, the
candidate id (`B1-xx`) is cited directly instead of re-deriving the finding.

---

### Cart preview
- Unify money/qty motion on one `RollingNumber` family incl. the grid stepper · problem: 3+ disagreeing number/qty primitives across the cart and the deals-grid stepper read as different products · `RollingNumber` (D13, D20) · R08-27, R08-28 · **yes**
- Size-transition summary/struck-price rows instead of a plain-`if`/snap · problem: rows pop in at full opacity inside an otherwise-eased card, and the bar's struck price snaps next to a rolling total · `SizeFadeSwitcher`/`CollapseReveal` (D13) · R10-22 · yes (minor)
- Gate the Pro-tag and basket-disc pop to real changes only, not every mount · problem: both pop on every cart open including a count drop, with nothing new to announce · `ChangeBump` (D13) · extends D20's "never fake a change" rule · **yes**

### Cart tab
- Give the incoming tab a fast fade paired with the pill-thumb move · problem: tab entry is an instant cut while only the pill thumb animates, and the Cart↔history bodies underneath also snap · D11 (§9 (decision summary)'s own answer) · R09-02 · **yes (needs approval, already flagged)**
- Collapse the three segmented-thumb implementations onto one primitive+token · problem: this screen's `AnimatedAlign`, checkout's spring and coupons' `TabController` all solve the same problem differently · D14 · CC-26 · yes (needs approval — touches 3 screens)
- Give the Cart↔history pill a press state + selection haptic · problem: the one segmented control in the app with no press feedback or haptic at all · `PressScale` (D22) · R08-02 · **yes**

### Checkout
- Give the fact-line rotation a pause affordance or move it away from the primary CTA · problem: it loops every ≈3.3s for the whole checkout visit next to "Place order" with no user control · flag for approval (WCAG 2.2.2) · n/a (new finding) · **yes (needs approval)**
- Adopt `FailureView` + the offline contract on first-load error · problem: any failure incl. offline shows the same static plate with no checking/offline distinction · core contract, not a §9 (decision summary) token · n/a (architecture rule) · **yes**
- Sequence the up-to-7 simultaneous motions on one coupon/points change · problem: nothing orchestrates receipt-row reveal + total fade + savings count-up + tag pop + bar roll + fact-line jump + points bump · D17 extended · R08-27 · yes (minor, timing only)
- Fold the stacked timing→slot sheets into one flow · problem: picking "Scheduled" closes one 300ms sheet while a second 500ms sheet is already rising · matches the shell-arrival unification family · CC-13 · **yes (needs approval)**

### Checkout vouchers
- Swap the hard loader→content swap for `FadeThroughSwitcher` · problem: the only bucket change on this flow with no switcher, while both cart and checkout fade through · `FadeThroughSwitcher` (D17) · n/a (internal consistency) · no (same shape, safer)
- Wire a real offline/error state instead of the misleading "no offers" text · problem: a failed read and a genuinely empty wallet look identical, and offline the page states something untrue · core contract · n/a (architecture rule) · **yes**
- Give an unlocking offer a continuity cue instead of a section jump · problem: the offer moves between two separately-keyed slivers with no motion at all · R09-06 (hero/zoom continuity, adapted) · **yes**

### History coupons
- Route History through My coupons' already-loaded cubit · problem: opening History re-reads the same local data and flashes an undelayed shimmer for data already on screen · n/a (architecture) · n/a · no (same visible shape once fixed)
- Switch the drill-in to `HeroSharedAxisPage` · problem: a step inside one flow uses the full 100% slide-up meant for a new context, not the shared-axis type reserved for exactly this case · D8/D9 · CC-13 · yes (needs approval — page-type change)
- Cap the stagger to "first load only" and stop the cross-group index carry-over · problem: on a long first screen every expired card waits the maximum 300ms because its index continues the used group's · D17 · matches B1-08's root cause · **yes**

### My coupons
- Drop count-up-from-0 on "Save up to" and the stub amounts · problem: contradicts the app's own "never count up on open" rule that checkout itself follows for the identical concept · `RollingNumber` (D13, D20) · R08-27, R08-28 · **yes**
- Cap and gate the badge glow and empty-tab float with ambientBudget+OnScreen · problem: two infinite loops with no visibility gate for the whole visit · `AmbientLoop`/`OnScreen` (D14, D19) · matches B1-02 · **yes**
- Stop entrance replay on tab revisit/scroll-back · problem: `TabBarView`'s non-keep-alive lazy list means reveals/pops/sweeps replay on every tab visit · D17 · matches B1-08 · **yes**
- Tokenise the 60ms/30ms raw steps and fix the sheen-vs-shineSweep mismatch · problem: three raw literals and one wrong-token reference drift from the shared duration scale · D2/D3 · CC-23 · no (same numbers, just named)

### Home
- Gate every ambient loop with `AmbientLoop`+`OnScreen`, including muting hidden shell tabs · problem: 12 independent loops keep ticking whether or not Home is the visible tab, since `IndexedStack` does not mute tickers · `AmbientLoop`/`OnScreen` (D14, D19) · matches B1-02, the single biggest instance of it in the app · **yes (needs approval, on D24)**
- Collapse `HomeReveal`/`HomeCountdownText`/`HomePressable` onto the core primitives · problem: three near-duplicate systems exist beside `EntranceCascade`/`SecondClock`/`PressScale` with their own raw timings · D2/D3, D14 · CC-02, CC-03, CC-04, CC-10, CC-11 · yes (visible timing change)
- Fix the header-remount-on-bucket-swap so one-shot arrival cues fire once per real change · problem: the ETA pop, bell ring and search-hint restart replay on every loading↔loaded swap and every language switch, not only on a real change · n/a (architecture), extends D20 · n/a · **yes**
- Route the direct `HapticFeedback` calls on Home's add-to-cart through `Haptics.*` · problem: later adds and removes bypass the app's own mute setting · D21 · CC-19 · **yes**
- Stop cascade replay on scroll-back with a keep-alive or "seen" set · problem: feed blocks re-play their entrance every time they scroll back into view · D17 · matches B1-08 · **yes**

### Search
- Give discover a real loading/empty/error/offline state · problem: the body is blank white on first load and on any failure, with zero feedback · `FailureView`+skeleton (D18) · matches B1-04's root cause · **yes**
- Add a stale note to match Home/Offers/Content/Notifications · problem: the one cached-data screen in this group with no freshness cue at all · D18 pattern · n/a · yes (minor)
- Give Search's category tile the same entrance/press language as Home's · problem: the identical concept animates richly on Home and flat here · D14, D22 · R08-02 · yes (needs approval — visible change)

### Content
- Add pull-to-refresh to match Home/Offers/Notifications · problem: the one cached screen among its siblings with no way to refresh by hand · n/a (mechanical, matches a shipped pattern) · n/a · no (adds a gesture, no visible change until used)
- Route flow-step content through `HeroSharedAxisPage` · problem: About→Terms / Login→Terms slide up full-screen like a new context instead of the shared-axis type reserved for a step in a flow · D8/D9 · CC-13 · yes (needs approval — page-type change)
- Unify the back control to `RoundBackButton`/`PressScale` · problem: the plain Material `AppBar` back here (and on Notifications) disagrees with the round-button convention everywhere else · D22 · n/a · yes (minor)

### Offers
- Unify the countdown treatment with Home's `FlipValue` or the unused core `SecondClock` · problem: the identical concept ticks with no flip here, flips per-part on Home, and neither uses the core clock built for exactly this · `FlipValue`/`SecondClock` (D13) · n/a (internal consistency) · yes (minor)
- Sequence the opening motion — page, then hero, then cascade · problem: three entrances start at once so the heading is only fully readable after the page has already arrived · D17 · R09-25 · yes (minor, timing only)
- Tokenise the raw 30ms stagger step and 900ms emoji wiggle · problem: two raw literals drift from the shared duration scale · D2/D3 · n/a · no (same numbers, just named)

### Notifications
- Give a live-push insert a short entrance instead of a silent prepend · problem: the one event that rings the Home bell arrives in the inbox with zero motion · `EntranceCascade` single-item mode (D13) · R08-30 · yes (minor)
- Adopt a skeleton for first load to match Home/Offers · problem: a centred loader disc instead of a shape-matching list skeleton for the first list load · `Skeletonized` (D18) · R08-11 · yes (minor)
- Switch signed-out to the shared `HeroStateView.signedOut`+`FailureView` contract · problem: a feature-local `EmptyStateView`+lock instead of the same pattern checkout/orders use · core contract · matches B1-04 · **yes**

### Order invoice
- Size-transition the stale pill's insertion · problem: the whole document snaps down and back up with no easing when the pill appears/clears · `SizeFadeSwitcher`/`CollapseReveal` (D13) · R10-22 · yes (minor)
- Fix the reduced-motion loader flash · problem: `DelayedLoaderDisc` shows for at least one frame under reduced motion instead of skipping its wait entirely · core bug, no new token · n/a · yes (minor, shared with 3 other screens)
- Smooth the checking→offline swap with a short cross-fade · problem: the one hard cut inside an otherwise calm document screen · D17-style fix · n/a · yes (minor)

### Order review
- Hold the done-check visible for a beat before popping · problem: the success check is effectively invisible because the page has already left by the time it would render · n/a (sequencing/correctness fix, contradicts the class's own doc) · n/a · yes (minor, timing only)
- Give a locked/sent tile an explicit "sent" mark · problem: a submitted or locked star row looks identical to an active one, no cue at all · `PopScale`/`FlipValue`-style check (D13) · n/a · yes (minor)
- Refresh the orders list on return from a review · problem: the "Review" pill stays on the list card after a review is sent until the next unrelated refresh · n/a (architecture) · n/a · **yes**

### Order tracking
- Key the when-line and roll/flip the ETA value instead of fading on every change · problem: the app's own rule says never key a switcher by changing data, and checkout shows the identical value with a flip · `RollingNumber`/`FlipValue` (D13, D20) · R02-19, R08-28 · **yes**
- Give delivered a genuine, bounded success moment · problem: the terminal, most significant status change on the screen gets no success cue or haptic at all · n/a (a moment, not yet a §9 (decision summary) primitive) · R07-33, R08-23 · **yes**
- Sequence the five simultaneous cancel motions · problem: headline, when-line, stepper, cancellation notice and cancel button all move at once plus a snack plus the overlay exit · D17 extended · R05-17 · yes (minor, timing only)
- Add a live-status haptic on a poll-driven change · problem: a real status change while the app is foregrounded gets only a 300ms cross-fade, no attention cue · Haptics taxonomy (D21) · n/a · yes (needs approval — a new haptic moment)

### Orders (list)
- Give the reorder success a `FlyToCart` moment instead of a toast-only confirmation · problem: every other add-to-cart surface flies to the cart, this one is a toast after a ≥500ms overlay · `FlyToCart` (D13) · R08-20, R05-31, R05-33 · **yes**
- Fix the destructive-cancel-confirm haptic to warning · problem: a confirmed destructive action fires the light `tap` haptic · Haptics taxonomy (D21) · R07-26 · **yes**
- Give card action pills their own press scale · problem: the passive card-wide `PressScale` means pressing Cancel/Reorder visibly shrinks the whole card, not the pill · D22 · n/a · yes (minor)
- Size-transition the stale pill and the load-more footer instead of snapping · problem: both push/shrink the list with no easing in either direction · `SizeFadeSwitcher` (D13) · R10-22 · yes (minor)

### Customer-service hub
- Wire the existing `status`/`errorMessage` into a real loading/error view · problem: the cubit already emits both, the body ignores them entirely, so a failure is invisible · core contract · matches B1-04 · **yes**
- Size-transition the recent-order card's insertion · problem: it pops into the top of the list with no motion, pushing everything else down · `CollapseReveal` (D13) · n/a · yes (minor)
- Switch the forward flow (hub→topics→chat) to `HeroSharedAxisPage` · problem: orders reserves shared-axis for exactly this "step in a flow" shape, this hub does not use it · D8/D9 · CC-13 · yes (needs approval — page-type change)

### Help topics
- Fix the missing `findChildIndexCallback` so filtering does not re-stagger unaffected rows · problem: every row after the first index-shifted one is re-created and replays its entrance on each keystroke · n/a (correctness fix) · matches B1-08's root cause · **yes**
- Collapse the two disclosure primitives onto one · problem: `CollapseReveal` and `AnimatedAccordion` disagree — one keeps drawing the closing child, the other blanks it first · D13 · CC-07 · yes (visible timing change)
- Give the accordion toggle a selection haptic · problem: the comparable `OptionRow` toggle elsewhere fires one, this disclosure fires nothing · Haptics taxonomy (D21) · n/a · yes (minor)

### Rider chat
- Fix the reduced-motion scroll-to-end crash risk · problem: a zero-duration `animateTo` can trip a Flutter assertion under "remove animations," the review's own flagged real bug · n/a (correctness fix) · CC-01 · **yes**
- Give the scripted reply a brief typing indicator and route gestures through `Haptics.*` · problem: the reply lands 30ms after the customer's own bubble with zero haptics anywhere on the screen · Haptics taxonomy (D21) · R06-33 · **yes**
- Align entrance direction and send-button motion with the assistant's own chat · problem: the app's two chat surfaces read as unrelated products · D13 · matches CC-32's assistant-motion-vocabulary family · yes (needs approval — visible change)

### PDP image viewer
- Add drag-down-to-dismiss · problem: the one full-screen photo viewer in the app with no downward exit gesture or feedback · n/a (a gesture, not yet a primitive) · R09-05, R09-06 · yes (needs approval — new interaction)
- Swap in `HeroIcons.close` for the close button · problem: a Material glyph where the branded one already exists and is used elsewhere · D13 · n/a · no (wiring only)

### Product detail (PDP)
- Shorten or remove the "Added" hold that blocks a second add · problem: a customer wanting 2 pieces waits a full 1.2s with the tile untappable · n/a (timing fix) · R07-29, R08-07 · yes (needs approval — visible timing change)
- Slide the buy bar in like Pro's own bar instead of snapping · problem: the bar appears from `SizedBox.shrink()` and shrinks the viewport in the same frame, inconsistent with the app's other sticky bar · D2/D3 · n/a · yes (minor)
- Fix the badge to pop only on landing and only on a real change · problem: the badge pops at t=0 and on every page open, contradicting `FlyToCart`'s own documented contract · n/a (correctness fix) · n/a · **yes**
- Give the rail steppers the same `RollingNumber`+press-scale treatment as the bar stepper · problem: two stepper families disagree on the same page · D13, D14 · matches the `CatalogPillStepper` cross-cutting gap · yes (visible change, cross-cutting candidate)

### Recipe detail
- Give loading and error states a back affordance · problem: an iOS user can get trapped on the error screen with no swipe-back and no on-screen back button · n/a (correctness fix) · n/a · **yes**
- Route ingredient add through the same `ShelfAddControl` morph PDP uses · problem: a hard snap with no fly-to-cart, the only "add" surface in the app with zero motion · D13 · matches §38's cross-screen add-to-cart finding · **yes**
- Fix haptics to go through `Haptics.*` with one call per press · problem: two direct `HapticFeedback` calls fire for "Add all," bypassing the mute, with no success haptic · Haptics taxonomy (D21) · CC-19, CC-20 · **yes**

### Recipes (list)
- Add a skeleton + `EntranceCascade` to match Offers/Orders/Coupons · problem: the one list in this set with neither, a hard disc→list snap · D14, D17, D18 · matches Offers' own pattern · yes (visible change)
- Fix the dead pull-to-refresh on the empty state · problem: the spinner never appears at all, a pull is silently swallowed, while Pro's own unavailable view gets this right in the same codebase · n/a (mechanical fix) · n/a · **yes**
- Give rows a press scale · problem: PDP rail tiles and Pro brand tiles sink, recipe rows do not · D14, D22 · n/a · yes (minor)

### Pro membership
- Cap every loop's lifetime and gate all of them with ambientBudget+OnScreen, including through `ProKeepAlive` · problem: glow, float, two sweeps and two marquees never stop, several kept ticking even scrolled far out of view · `AmbientLoop`/`OnScreen` (D14, D19) · matches B1-02, the single biggest instance in the app · **yes (needs approval, on D24)**
- Drop points count-up-from-0 on open · problem: contradicts the app's own "cached balance never counts up" rule that PDP itself follows · `RollingNumber` (D13, D20) · R08-27, R08-28 · **yes**
- Replace the plan-tap's 8-way simultaneous choreography with a smaller, sequenced set · problem: one tap fires roughly 8 concurrent animations including a 1.1s arch redraw · D17 · R05-09 · yes (needs approval — visibly less motion)
- Fix `FloatLoop`'s unused `count` param so the bag genuinely stops · problem: the bag floats forever though the primitive supports a bounded count · core fix · matches B1-03's sibling fix · yes (visibly changes today's behaviour)
- Unify close/cancel/confirm-dialog controls and add a warning haptic to the destructive cancel · problem: four different control styles for comparable actions, and cancel renewal has no destructive cue at all · Haptics taxonomy (D21, D22) · R07-26 · **yes**



Screens/surfaces: BrandsPage, CategoriesPage, CategoryPage, ProductListingPage, then the 14 shared surfaces from
Appendix A (46-59): sheets & dialogs, snack bars, connectivity banner, stale notices, locale veil, tab bar + cart
bar, route→transition map, loaders, skeletons, state views, product cards/shelves/steppers, add-to-cart path,
ambient/brand widgets, images. Each idea: **idea** · UX problem solved · pattern/primitive/token · evidence ID ·
behaviour change (yes → needs approval, folded into §9 (decision summary) §24's list where it isn't already there; no →
same visible shape, safe to ship as a refactor). Where an idea repeats a Part-1/Part-2 candidate's root cause, the
candidate id (`B1-xx`/`B2-xx`) is cited directly instead of re-deriving the finding.

---

### BrandsPage
- Give brand rows the same press feedback + haptic as every other tile family in the app · problem: `BrandTile` is a bare `GestureDetector`, no press, no haptic, unlike `search_brand_tile.dart`/`pro_brand_tile.dart` · `PressScale` (D22) · matches B1-16 · **yes**
- Cross-fade loader→list→empty→error instead of a hard switch · problem: the disc pops in with a spring then disappears on a cut, four times over · `FadeThroughSwitcher` (D13) · matches B1-06 · no (same shape, calmer)
- Replace the disc with the shared grid-shaped skeleton language · problem: a list page loads with a spinner-style disc while the sibling listing screens show shaped bones — two loading languages in one feature · skeleton vs disc rule (D18) · n/a (new, see backlog_cand_3) · no (same wait, different look)

### CategoriesPage
- Give the top-level `CategoryTab` bar the same glide/click/centre language as `CollectionTabStrip` in the same feature · problem: it is the only tab control in the app with no press, no haptic, a snapping indicator and no scroll-into-view · one segmented/tab primitive (D14) · CC-26, matches B2-09 · yes (needs approval — a ruling first)
- Orchestrate the rail-pick pile-up (glide + scale + label lerp + chips snap + grid restart + one haptic) · problem: up to 6 concurrent motions fire on one circle tap with nothing sequencing them · sequencing rule (D17 extended) · matches B2-03 · yes (needs approval)
- Tell the customer when a category-tree refresh fails · problem: `CategoryBody` never reads the tree's failure status, so the rows just never appear with no loader or error cue · offline/failure contract (CLAUDE.md §3.2) · matches B1-04's root cause · **yes**

### CategoryPage
- Size-transition the late rail-header/chips insertion instead of snapping it above the grid · problem: when products arrive before the tree, a 108 dp header + chips row snap in and shove a mid-cascade grid down · `SizeFadeSwitcher`/`CollapseReveal` (D13) · matches B2-05 · no (same content, no more jump)
- Surface the category tree's silent failure · problem: identical root cause to CategoriesPage's tree-failure gap, on the page most often reached from search/PDP/the assistant · offline/failure contract (CLAUDE.md §3.2) · matches B1-04 · **yes**
- Route the title cross-fade through `signature`, not the `AnimatedSwitcher` default linear curve · problem: the one title swap on this page drifts from the curve every other cross-fade in the app uses · `AppMotion.signature` (D5) · n/a (internal consistency) · no

### ProductListingPage
- Unify money/qty motion on one `RollingNumber` family including the grid stepper · problem: the grid stepper's quantity snaps while cart's and PDP's own steppers roll the identical concept · `RollingNumber` (D13, D20) · matches B2-01 · **yes**
- Stop the ≈0.83 s reveal cascade from replaying on every restart (sort/filter/tab/rail/chip pick) · problem: every pick, not only a first load, re-runs the full clock+stagger · "first load only" rule (D17) · matches B1-08's root cause, extended to restarts · **yes**
- Fix the brand-filter sheet's silent wait and the double-tap race that opens an empty sheet · problem: the pill has no busy state while it awaits a full cache+server read, and a second tap opens the sheet on an empty list before the real one lands on top · pending-state pattern, no §9 (decision summary) token yet · n/a (new, see backlog_cand_3) · **yes**
- Collapse the three list-entrance systems (`ListingReveal`, `StaggerEntrance`, `EntranceCascade`) onto one and tokenise every raw step · problem: three primitives solve the same "cards arrive" problem with three different raw timings · `EntranceCascade` (D13, D17) · matches B1-07, CC-02, CC-03 · yes (10+ screens' step values move to 30 ms)

### shared:sheets-dialogs
- Give every draggable sheet a visible drag handle and stop stacking sheets (timing → slot) · problem: 4 different sheet tops exist and one flow closes a 250 ms sheet while a 500 ms one is already rising on top of it · one sheet-chrome rule (D12) · R09-12 (grab handles "easy to ignore", don't stack sheets) · yes (needs approval — visible chrome change)
- Standardise selection feedback across sort/brand/DOB sheets to match branch/timing's animated radio + haptic · problem: half the selection sheets confirm with a haptic + animated radio, the other half close on a static check with nothing · `OptionRow`/`Haptics.selection` (D21) · n/a (internal consistency) · **yes**
- Fix the destructive-confirm haptic taxonomy across all 4 dialogs · problem: logout fires two haptics, clear-cart one, delete-address/cancel-order a mismatched light tap, cancel-Pro-renewal none · Haptics intent helpers (D21) · matches B1-05 · **yes**

### shared:snack-bars
- Give every snack a tone (success/warning/error/offline) and an optional action · problem: all four kinds of message look and move identically, and there is no Undo after a destructive action anywhere in the app · new snack contract, no §9 (decision summary) token yet · R08-22 (choose the channel by severity), R08-21 (toasts + a11y) · yes (needs approval — visible chrome change)
- Fold the 4 floating snacks (all in account) onto the fixed convention the other ~65 snacks use · problem: the identical kind of message (a saved setting) floats in one place and sits fixed everywhere else · one snack-motion rule (D12) · n/a (internal consistency) · no (same message, one less surprise)

### shared:connectivity-banner
- Size-transition the banner's label when it goes from two lines to one on "back online" · problem: the label snaps and the whole app below jumps up in one frame · `SizeFadeSwitcher`/`CollapseReveal` (D13) · matches B2-05's root cause · no (same message, no jump)
- Give the offline row a real press state · problem: the only feedback on "check now" is a haptic and the icon later popping to dots, with no visual press of its own · `PressScale` (D22) · n/a (new finding) · no

### shared:stale-notices
- Adopt `CollapseReveal` for the stale pill and the offline/load-more swaps instead of a snap-open, fade-in-only, snap-close · problem: the same "optional block" shape that the connectivity banner already animates both ways is handled with three different, mostly instant, treatments here · `CollapseReveal` (D13) · CC-07 (show/hide by height+fade, one primitive, 3 near-copies) · no (same content, no jump)

### shared:locale-veil
- Move the success haptic from the cubit to the widget, fired when the veil has actually lifted · problem: `Haptics.success` fires from `SettingCubit` while the veil is still opaque, so the buzz lands on nothing visible · Haptics ownership rule (D21), CLAUDE.md §4 "no motion decisions in cubits" · CC-20 (a haptic decision fires inside a cubit) · **yes**
- Cover the connectivity banner with the veil, or document the gap · problem: with the banner open, its text flips language in plain sight while the rest of the screen stays veiled · veil scope (D7) · n/a (new finding) · yes (needs approval — visible timing/scope change)

### shared:tab-bar-cart-bar
- Give the tab switch a fast incoming fade with no haptic, matching §9 (decision summary)'s own answer · problem: tab bodies cut instantly while the Home item alone plays two animations of different length · `HeroFadeThroughPage`-style fade (D11) · matches B1-10 · yes (needs approval, on D24)
- Mute Home's ambient loops while its tab is hidden · problem: `IndexedStack` never mutes Home's loops, which check only bare `TickerMode`, so they keep producing frames on Search/Cart/Mine · `TickerMode`/`Visibility.of` gating (D19) · PB-01 (hidden shell tabs never muted) · no (invisible fix, same look when visible)
- Replace the cart-count badge's pop-from-0 with `ChangeBump` + roll-on-land, synced to the flight · problem: the badge blinks out and regrows on every change, including decrements, and finishes before the 400 ms flight lands · `ChangeBump`, `RollingNumber` (D13, D16) · matches B1-11 · **yes**

### shared:route-transition-map
- Fix the page-type drift so a step inside one flow always keeps its shared-axis legs · problem: checkout/orders/coupons/support lose a transition leg when entered from a non-shared-axis push or replaced via `pushReplacement` · `HeroSharedAxisPage` everywhere it's documented for (D8, D9) · matches B2-02, CC-13 · yes (needs approval — visibly different transitions on 6 routes)
- Collapse `HeroTransitionPage`/`HeroSlideUpTransitionPage` into one class with one consistent pop easing · problem: the two page types share a doc but pop with opposite easing curves, and the router's own comment claims only 2 types exist when there are 5 · page-type consolidation, no new token · CC-13 · yes (needs approval)
- Wire the manifest predictive-back flag once the page types are consolidated · problem: no route in the app gets an iOS edge-swipe or an in-app Android predictive preview, only the one framework licenses route does · `PredictiveBackPageTransitionsBuilder` (D11) · R03-14 (custom transitions lose the platform back gesture) · yes (needs approval — manifest flag)

### shared:loaders
- Delete the unused 2.2 MB loader GIF · problem: it ships in every build and is referenced nowhere in `lib/` or `test/` · already decided (§9 (decision summary) item 1) · PB-15 · no (dead weight removed, nothing on screen changes)
- Fix `DelayedLoaderDisc`'s reduced-motion flash and its invisible-tick waste · problem: under reduced motion the 150 ms "no flash" wait is skipped too, so a fast load can flash the disc for a frame · `MotionGuard`-correct delay (D7, D18) · PB-27, matches B2-06's exact bug on a shared primitive · **yes**
- Give a failed busy-overlay action the same drawn feedback success already gets · problem: `BusyOverlay` knows only `busy`/`done` — a failure just leaves with no mark at all · a failure mark to pair with `LoaderDoneMark` (D13) · n/a (new finding) · yes (needs approval — new visible state)

### shared:skeletons
- Add a `RepaintBoundary` around `Skeletonized` · problem: the shimmer repaints the whole host page on every tick, up to the nearest ancestor boundary above the scroll view · perf-only fix, no token change · PB-08 (exact match) · no (same look, cheaper)
- Pick one "content arrived" behaviour instead of four (cut / fade-through / stagger / feature-own reveal) · problem: the identical event (skeleton → real content) looks different on every screen that has one · `FadeThroughSwitcher`/`EntranceCascade` (D13, D17) · matches B1-06, B1-07 · yes (needs approval — 5 screens change look)

### shared:state-views
- Adopt `FailureView`+`DataFreshness`+`HeroStateView.signedOut` on the 6 screens still using the plain `ErrorView`/`EmptyStateView` for a network state · problem: `SignedOutView` literally renders as an error, and one `FailureView` itself switches icon size/spacing/heading mid-screen when its verdict changes · core offline contract (CLAUDE.md §3.2) · matches B1-04 (exact match) · **yes**
- Give the Retry/secondary state-view buttons a press state and a haptic · problem: "Retry" is the one CTA family in the app with no scale and no haptic, while every primary button has both · `PressScale`/`Haptics.tap` (D21, D22) · n/a (internal consistency) · no

### shared:product-cards-shelves-steppers
- Give the shared stepper a rolling count and a real press state everywhere it appears · problem: the identical `CatalogPillStepper` snaps its digit on 5 surfaces while cart's and PDP's own steppers roll the same concept, and −/+/bin have no press feedback at all · `RollingNumber`, `PressScale` (D13, D22) · matches B2-01 (exact match) · **yes**
- Retire `HomePressable` in favour of the shared `PressScale`, and give assistant/cart-deals/checkout-rail cards the same press the listing and PDP rail already have · problem: the same product card presses three different ways (or not at all) depending on which screen hosts it · `PressScale` (D14, D22) · matches CC-10 (exact match) · no (same feel everywhere, no new motion)
- Route the add→stepper morph through the shared `PopSwitcher` instead of each surface's own `AnimatedSwitcher` copy · problem: home quick-look's copy starts from a different scale (0.8) than every other host's (0.6) · `PopSwitcher` (D13) · matches CC-09 (exact match) · no (same shape, one primitive)

### shared:add-to-cart-path
- Sync the cart badge's pop with the flight's actual landing, and stop it re-popping on decrements/re-syncs · problem: the badge pops at t≈0 while the flight lands at 400 ms, and every server re-sync makes it blink out and regrow · `ChangeBump`, `RollingNumber` (D13, D16) · matches B1-11 (exact match) · **yes**
- Unify the add-to-cart haptic API and its 3 kind-mismatches across every surface · problem: home/listing/recipes bypass the app's haptic mute with direct `HapticFeedback`, and 3 specific gestures fire the wrong kind · `Haptics.*` intent helpers (D21) · matches CC-19, B1-05 (exact match) · **yes**
- Decide whether the first-add celebration (confetti + "+1" + haptic success) belongs on every add surface or stays home-only · problem: the identical "first item in an empty basket" moment is rewarded on Home alone and plain everywhere else · `FlyToCart`/`ConfettiBurst`/`Haptics.success` parity (D16) · matches B2-07 (exact match) · yes (needs approval — visible reward on 6+ more surfaces)

### shared:ambient-brand-widgets
- Gate every decorative loop (`LightSweep`, `BrandBackdrop`, `HeroWavingMark`/`HeroLockup` idle) with `ambientBudget`+`OnScreen` · problem: 7 of 11 `LightSweep` sites and both login-screen ambient loops run forever with no visibility gate, conflicting with the app's own "never loop without a reason" rule and WCAG 2.2.2 · `AmbientLoop`, `OnScreen` (D15, D19) · matches B1-02 (exact match), R06-35/R07-03 (WCAG 2.2.2) · yes (needs approval, D19/D24)
- Stop `BrandBackdrop`'s full-screen per-frame repaint on login/OTP · problem: a gradient+glow+32 doodles repaint every vsync for motion that moves ~0.086°/frame, for as long as the sign-in screen sits idle · frame-rate cap or the same `OnScreen` gate above · PB-03 (exact match) · no (same visual, far cheaper)
- Collapse the 3 idle-loop "when may I run" policies onto one · problem: visibility-gated, state-gated-only and fully-ungated loops all exist side by side with no shared rule · `IdleLoop`/`AmbientLoop` (D14, D15) · CC-04 (exact match) · no (internal consolidation)

### shared:images
- Route the network-image fade through `MotionGuard` · problem: it is the one fade primitive in the app that ignores reduced motion entirely · `MotionGuard`-gated `imageFade` (D7) · PB-12 (exact match) · no (instant under reduced motion, same otherwise)
- Replace the flat grey placeholder with a brand mark or a dominant-colour/blurhash placeholder · problem: the code's own doc comment promises a "skeleton placeholder" that does not exist; every missing/loading image is a flat grey tile · new placeholder asset, no §9 (decision summary) token yet · n/a (new, see backlog_cand_3) · no (same layout, different fill)


## 7. Durations, easing curves and interaction behaviour per pattern

**Curves** (cubic-bezier): `signature` (0, 0, 0.2, 1) · `exit` (0.4, 0, 1, 1) · `emphasizedDecelerate` (0.1, 0.7, 0.1, 1) · `machEaseInOut` (0.42, 0, 0.58, 1) · `linear`.

**Springs** (`SpringDescription`, mass 1):
- `snappy`: ζ 0.6, k 800, about 320 ms to settle, bounce about 0.4. Use it only on elements of 48 dp or less.
- `calm`: ζ 0.9, k 700, about 210 ms, no visible overshoot.
- Spatial motion may use a spring. Opacity and colour never overshoot [R01-02][R01-04][R03-20][R08-35].

| Pattern | Duration | Curve / spring | Interruption / reversal | Evidence |
|---|---|---|---|---|
| Press feedback (scale 0.97; icon buttons under 48 dp use 0.92) | in `microPop` 100 · out `fast` 150 | `signature` both ways | Release mid-press reverses from the current value. A cancelled press (drag out) releases without firing | [R05-08][R08-02][R08-03][R04-26] |
| Add → stepper swap (in place) | `snappy` settle (about 320 ms) | `snappy` scale 0.8 → 1 + fade `fast` | A second tap mid-swap acts on the stepper at once (the state is already committed, optimistic) | [R05-32][R08-18][R01-04] |
| Fly-to-cart | `slow` 400 | `signature` along a lifted bezier; thumbnail fade `fast` at the end | Rapid taps: at most 3 flights at a time, extra taps update the count only; a new route cancels flights | [R05-33][R08-20][INFERENCE] |
| Badge bump on land | `snappy` (about 320 ms) | `snappy`, peak 1.15 | Re-triggered mid-bump: restart from the current scale, never from 0 | [R02-20][R08-03] |
| Qty stepper digits / price / total roll | `medium` 250 | `signature`; roll direction from the delta | A new value mid-roll retargets from the current glyph position | [R02-19][R08-27][R08-28] |
| Earned amount count-up (savings after a coupon) | `slow` 400 (was 700) | `emphasizedDecelerate` | A new value mid-count restarts from the displayed value, never from 0 | [R08-27][INFERENCE] |
| Short label / time flip | `medium` 250 (was `flip` 280) | `signature` | Retargets | [R02-20] |
| List entrance (first load only) | item `medium` 250; step `staggerStep` 30; cap 6 items (so the last starts ≤ 150 ms) | `signature`; fade + 8 dp rise | Scrolling, a tap or a new data swap ends the cascade: every item jumps to rest | [R05-10][R09-26][P3-1] |
| Skeleton → content | `fast` 150 cross-fade | `signature` | New data mid-fade retargets; there is no blank gap | [R08-17][R05-24][A10 #3] |
| State swap (content ↔ error / empty) | `medium` 250 fade-through (outgoing first 30 %) | `signature` | Reverses from the current opacity | [R09-02] |
| Loader appear | wait `loaderDelay` 150, then fade `fast` + scale 0.9 → 1 `calm` | `calm` | Data before 150 ms: the loader never shows (this also holds under reduced motion) | [R08-12][R08-13][R08-03] |
| Busy overlay (submit) | scrim in `medium`, out `fast`; min visible `busyMinVisible` 500; done tick `drawOn` 700 then hold `successHold` 400 | `signature` / `exit` | Blocks taps and back by design (submit only) | [R08-12][R08-02] |
| Page push (forward, shared axis X) | enter `page` 300 · pop `page` 300 reversed | `signature`; 30 dp shift; outgoing fades 0-30 %, incoming fades 30-100 % | The back gesture drives progress 1:1; release commits or cancels with `calm` | [R09-01][R09-05][R02-02][R01-24] |
| Modal page (slide-up) | enter `page` 300 · exit `medium` 250 | enter `signature`, exit `exit` | Drag-down / back gesture tracks the finger; a fling carries velocity | [R09-05][R02-03][R03-17] |
| Top-level swap (fade-through page) | `page` 300 | `signature`; out 0-30 %; in scale 0.92 → 1 | Not interruptible (go replaces the stack) | [R09-02][R09-04][R01-16] |
| Tab switch (shell) | incoming fade `fast` 150; icon scale 1.12 `fast` | `signature` | A fast second tap jumps to the new tab at once | [R09-02][R09-04][R02-15] |
| Predictive back (Android) | follows the finger; commit about `fast`-`medium` | preview scale 1 → 0.9, shift (w/20 − 8) dp; commit `exit`, cancel `calm` | Fully interruptible: cancel returns to 1.0 | [R01-17][R01-24][R03-12][R09-08] |
| Bottom sheet | enter `page` 300 (large sheets `slow` 400, was 500) · exit `medium` 250 | enter `signature`, exit `exit`; scrim linear with the sheet | Drag tracks 1:1; release carries velocity; predictive back shrinks it to 0.9 | [R09-13][R04-22][R08-05][R01-21] |
| Dialog | enter `medium` 250 fade + scale 1.1 → 1 · exit `fast` 150 fade | enter `signature` (was `decelerate`), exit `exit` | Barrier tap mid-enter reverses | [R04-25][R05-02][R09-26] |
| Snack bar | in `medium` 250 · out `fast` 150; dwell `snackDwell` 4000 | in `signature`, out `exit` | A new snack replaces the old one with a cross-fade (no exit-then-enter, about 500 ms today, A09 11.4) | [R05-03][R04-24][R08-22] |
| Connectivity banner | height + fade in `medium`, out `fast`; "back online" `TintFlash` `breathe` 600 once | `signature` / `exit` | Flapping state: the latest state wins, retargeting mid-reveal | [R08-30][R08-29] |
| Stale note ("Updated … ago") | height + fade in/out `fast` 150 | `signature` / `exit` | Retargets | [R08-30][R08-27] |
| Empty state entrance | `medium` 250: fade + scale 0.9 → 1, once; no loop | `signature` | None needed | [R08-31][R08-08][R08-03] |
| Issue plate story (failure states only: `StateArtMotions`) | after the entrance, laps of `stateArtLap` 2400 — still for the first 10 %, the story, still for the last 25 % — as many as fit `ambientBudget` 5000 (two), on screen only, again when back on screen | per keyframe: `signature` arrivals, `machEaseInOut` swings, `linear` flickers | Off screen, a hidden tab, reduced motion or a screen reader → the still sticker (every track ends where it starts) | user request 2026-10-05 |
| Error shake (blocked tap / invalid submit) | `medium` 250 decaying sine, about 3 swings | `ShakeX` built-in | A re-tap restarts the shake | [R08-24][R08-26][R01-30] |
| Success check | `drawOn` 700 draw; hold `successHold` 400 | `emphasizedDecelerate` | Leaving the page cancels it | [R08-02][R02-21] |
| Celebration (confetti) | `confetti` 1400, one burst, no more than 50-60 pieces | physics + `linear` fade | `IgnorePointer`; never blocks | [R08-32][R08-23] |
| Expand / collapse | open `medium` 250 · close `fast` 150; chevron rotates with it | open `signature`, close `exit` | A re-tap reverses from the current height; content stays drawn while closing | [R09-26][A06 #2][A10 #13] |
| Carousel auto-advance | slide `page` 300; dwell `carousel` 3000 | `signature` | Touch pauses; resumes after one dwell; stops when off screen, under reduced motion or with a screen reader | [R07-03][R07-23][R02-27] |
| Ambient loop (decorative) | cycle `floatLoop` 3200 / sweep `sheen` 3600; stop after `ambientBudget` 5000 total | `machEaseInOut` (float) / `linear` (sweep) | Stops off screen or on a hidden tab; resumes only on a new trigger | [R07-03][R08-09][R10-18] |
| Locale switch veil | in `fast` 150, out `medium` 250; starts with the thumb (no 210 ms wait) | `signature` / `exit` | Taps blocked while the veil is up (they leak today, A09 11.5) | [INFERENCE][A09 11.4] |
| Pull-to-refresh | drag 1:1; settle `calm`; dots `loaderOrbit` 1200; done shrink `fast` | `calm` / `linear` / `exit` | Release above the threshold springs back; cancel mid-refresh is not offered | [R07-02][R01-12][R08-15] |
| Image fade-in | `fast` 150 (was 500 + 1000 stacked) | `signature` | Skipped when the image comes from the memory cache | [P3-5][R03-03][INFERENCE] |
| Scroll-linked header | 1:1 with scroll; title fades over the collapse range | none (scroll-driven) | User-driven, always reversible | [R07-02][R09-15][R02-30] |

---


## 8. Performance considerations for Flutter at 60 / 120 FPS

### 8.1 Frame budgets

A frame is on time only if **both** the UI (Dart build/layout/paint-recording) thread and the raster
(GPU command submission) thread finish inside the display's refresh interval — missing either one
drops the frame [R10-02]:

| Refresh rate | Total budget | Typical UI/raster split |
|---|---|---|
| 60 Hz | **16.6 ms** | ~8 ms UI + 8 ms raster [R10-02] |
| 90 Hz | 11 ms | — [R10-01] |
| 120 Hz | **8.3 ms** | ~8 ms combined — headroom is nearly gone [R10-01][R10-02] |

A "frozen frame" (Android vitals terms) is 700 ms–5 s of no new frame at all [R10-01] — an order of
magnitude worse than a single dropped frame, usually caused by synchronous work on the UI thread
(a blocking parse, a synchronous asset decode), not by raster cost. Hero's own 2.2 MB catalogue
parse before `runApp` (Appendix B, PB-14) is exactly this class of risk at startup, mitigated only
by running on an isolate (`compute`).

**Measurement rule:** profile only in **profile mode**, on a real device — debug mode "intentionally
sacrifices performance" for compile speed [R10-03]. DevTools' UI-thread graph shows Dart cost; the
raster-thread graph's red bar means "scene too complicated" [R10-03], and its layer toggles
(Clip/Opacity/Physical-Shape) isolate which primitive is the cost driver [R10-04][R03-04].

### 8.2 Impeller specifics

Impeller is Hero's actual renderer on iOS (Impeller-only) and Android API 29+ (Vulkan default,
<50 shaders) [R03-01]. Three Impeller-specific facts change what "optimize this" means versus older
Skia-era advice:

1. **`RepaintBoundary` is not a bitmap cache under Impeller.** `EnableRasterCache()` returns `false`
   by default; the raster cache is ignored unless the surface explicitly enables it [R03-02]. A
   `RepaintBoundary` still isolates *which subtree re-records*, which is why Appendix B's PB-04 and
   PB-08 (missing boundaries around the buddy overlay and the skeleton shimmer) matter — but it is
   not, by itself, "free caching."
2. **Shader-compile jank is largely solved.** Impeller precompiles pipeline state objects at build
   time, which the Flutter 3.47 release notes describe as eliminating first-run shader-compilation
   jank [R10-11] — a real win over the old Skia-era "first transition on a new screen is janky"
   problem, still relevant on the API-28-and-below devices that fall back to Skia [R10-12].
3. **It is not uniformly faster than Skia yet.** Impeller's Vulkan path shows real regressions on
   some Adreno GPUs during ordinary page-push transitions — 4-12 stalls of 26-166 ms observed against
   open engine issues, versus 34-52 ms on the Skia/GLES path on the same hardware [R03-08]; on some
   Android devices Flutter's frame rate is locked to 60 fps regardless of the display's true refresh
   rate, an open issue since 2024 [R10-17]. Treat "switch to Impeller and it's automatically faster"
   as false for the low/mid-range Android tier Hero ships to — profile on the actual device class,
   not just a flagship.

### 8.3 Raster-cost rules: opacity, blur, clip, shadow, `saveLayer`

Ranked roughly by cost, from the digest and confirmed against Hero's own code in Appendix B:

- **`saveLayer` (an offscreen buffer) is the single most expensive common technique** — "particularly
  disruptive on mobile GPUs" [R10-05]. Hero has 2 code sites: `brand_backdrop_painter.dart:95`'s
  `saveLayer(null, …)` is **unbounded** (PB-03, High) — the one to fix first; `splash_scene_painting.dart:58-63`'s
  is **bounded** to the shine's own rect (PB-28, Low, already the lower-cost shape).
- **`Opacity` the widget, animated directly, forces a rebuild every frame** — use `FadeTransition`/
  `AnimatedOpacity`, or a colour-alpha decoration for a static dim; a `Container` with alpha in its
  colour is "much faster" than wrapping in `Opacity` [R03-03][R10-06]. Hero has 26 raw `Opacity(`
  lines outside `AnimatedOpacity`; PB-18/PB-21/PB-26 are the ones an animation or a per-frame builder
  actually touches, and PB-26 (a *static*, never-animated `Opacity` over out-of-stock photos) is the
  cheapest possible fix under this rule — swap it for a decoration alpha and it stops compositing a
  layer at all.
- **`BackdropFilter` blur is the most expensive common "glass" effect**, and with no ancestor clip it
  filters the *entire screen*, not just its own bounds [R10-09]. Group multiple blurs behind one
  `BackdropGroup` (Flutter 3.29+) — one team's own measurement: 11.2 ms ungrouped vs. 3.9 ms grouped
  vs. 8.7 ms bounded-and-grouped, for the same blur [R03-06][R10-09]. Hero currently has **zero**
  `BackdropFilter`/`ImageFilter` code sites (confirmed in Appendix B/C's evidence tables) — this is a
  rule to hold the line on, not a fix to make, if a future "glass" surface is ever proposed (§9 (decision summary)
  §1 already rejects a parallel visual system).
- **Clipping is not free even without `saveLayer`.** `clipBehavior: antiAliasWithSaveLayer` should be
  avoided outright; even the cheaper default clip is "still costly" inside an animation — prefer
  pre-clipping the image/asset or using `borderRadius` on a decoration instead of a runtime clip
  [R03-05][R10-07]. Hero has 29 `ClipRRect`/12 `ClipRect`/4 `ClipPath`/3 `ClipOval` sites; none sit
  inside an animated rebuild per the confirmed findings, but a new animated clip should default to
  `borderRadius` first.
- **Shadows/elevation cost sits on the raster thread** ("Render Physical Shape" layer in DevTools
  isolates it, though no numeric cost is published) [R10-08]. PB-24 (the voice lock pill re-painting
  its shadow every drag frame) is Hero's one confirmed animated-shadow cost site.
- **"Advanced" blend modes cost more, worst on GLES-fallback devices** — prefer a framebuffer-fetch
  blend where the visual allows it [R03-07].
- **Rebuild only what animates.** Pass a static subtree as `AnimatedBuilder`'s `child:`, or drive a
  `CustomPainter` directly from a `Listenable` via `repaint:` instead of rebuilding a widget every
  tick [R03-10]. This single rule underlies more than a third of Appendix B's findings (PB-04, PB-07,
  PB-11, PB-18, PB-21, PB-29) — an `AnimatedBuilder` with no `child:` is, on its own, the most common
  perf defect this review found.
- **Snapshot a heavy subtree while it scales/skews/blurs** rather than re-recording it every frame of
  the transform, via `SnapshotWidget` — noting it cannot capture platform views [R03-09].

### 8.4 Ticker and offscreen rules

- **`TickerMode` only mutes a ticker created through a widget-aware ticker provider** — a raw `Timer`
  is never muted by it [R10-18]. This is why PB-16 (8 timer sources with no lifecycle listener) is a
  distinct problem from PB-01 (ticker-based loops under a hidden tab): muting tickers fixes PB-01's
  class of issue but does nothing for PB-06/PB-16's raw `Timer.periodic`s, which need an explicit
  `AppLifecycleListener`/`TickerMode` check of their own.
- **`IndexedStack` does not mute hidden tabs.** Confirmed directly in the engine source
  (`indexed_stack.dart:104-109`): its build only wraps children in a visibility scope for
  paint/hit-test, with no `TickerMode` [R10-19] — the exact root cause of Appendix B's PB-01, Hero's
  single highest-severity performance finding.
- **`TickerMode.of` is deprecated in favour of `TickerMode.valuesOf`** as of Flutter 3.35, and its new
  `forceFrames` escape hatch causes "significantly higher battery usage" if ever forced on [R10-20] —
  Hero should never reach for `forceFrames`.
- **`RepaintBoundary` isolates an animated repaint from static content around it**, at the cost of a
  raster-cache-memory line item if the surface does cache it [R10-21] — the fix behind PB-02, PB-04,
  PB-08, PB-11, PB-23, PB-29.
- **Animate paint properties, not layout properties.** Animating padding/margins/size forces a full
  layout pass every frame, not just a repaint [R10-22] — the mechanism behind PB-22 (`CountUpText`'s
  non-tabular digits forcing a parent relayout) and PB-24 (the voice lock pill's height-driven drag).

### 8.5 List and image rules

Not separately called out as its own digest topic, but directly evidenced in Hero's own code
(Appendix B, P3):

- **A list item's `State` does not survive scrolling past the cache extent unless it opts into
  `AutomaticKeepAliveClientMixin`.** Entrance animations gated on a `_seen`-once flag replay on every
  scroll-back without it — PB-09, PB-10, Hero's highest-severity list finding.
  `addRepaintBoundaries`/`addAutomaticKeepAlives` on the `ListView`/`SliverList` itself are a
  per-list, not per-item, decision, and `ListingProductTile`'s own `RepaintBoundary` (PB-11's
  counter-example) shows the item-owns-its-boundary pattern already works when applied.
- **Never change a list item's `key`+`runtimeType` pair mid-lifecycle.** `Widget.canUpdate` requires
  both to match for element reuse; swapping between `StaggerEntrance(key: k, child: Tile())` and a
  bare `Tile(key: k)` on the same key forces a full deactivate/re-inflate the moment state settles —
  PB-30, the single most expensive "invisible" list defect found (it silently destroys per-item
  state, not just costs a frame).
- **Bucket requested image sizes; don't derive a fresh CDN URL/cache key per exact pixel box.**
  `ResizeImage`'s default policy stretches to the *exact* requested box (`ResizeImagePolicy.exact`,
  confirmed in the SDK) [confirmed in Appendix B PB-32], and a cache key derived from that exact,
  unbucketed size guarantees a miss whenever the next screen wants a slightly different size —
  PB-13's card→PDP empty-grey-header defect.
- **Animated GIF/WebP has no decoded-frame cache in Flutter** — every loop re-decodes every frame, by
  design, to avoid an OOM crash class; the issue tracking this cost is still open [R10-23]. Lossy
  WebP is 64% smaller than GIF but 2.2× the decode time; lossless WebP is 19% smaller and 1.5× the
  decode time [R10-24]. This is a second, independent reason (beyond simple dead-code) that Hero's
  bundled, unused `hero_design_loading.gif` (PB-15) should stay deleted rather than "kept in reserve"
  — a GIF loader, if ever reintroduced, has a real per-loop decode cost a code-driven loader does not.
- **Tune `cacheExtent` and `precacheImage` for what's about to scroll/push into view** rather than
  decoding strictly just-in-time (PB-33), and prefer a shared `RepaintBoundary`-isolated shimmer
  (PB-08) over letting a loading placeholder's shimmer repaint whatever else shares its render tree.

### 8.6 First-run and splash

- Impeller's build-time shader precompilation removes the historic "first transition on this screen
  is janky" cost class on supported devices [R10-11], but coverage has holes — Android API 28 and
  below still falls back to Skia [R10-12], and Adreno/Vulkan-specific stalls remain open on some
  devices even under Impeller [R03-08].
- **Overlap, don't sequence, the splash intro and the first real data fetch.** Hero's own cold-start
  path currently begins loading Home only *after* the splash intro finishes (PB-31) — the two are
  independent costs (a fixed-duration animation vs. a variable-duration network fetch) and should run
  in parallel so total time-to-first-useful-frame is `max(splash, load)`, not `splash + load`.
  §9 (decision summary) §23 already flags this as an approved-pending finding ("splash should overlap the Home
  load").
- **iOS: unlock ProMotion explicitly.** `CADisableMinimumFrameDurationOnPhone = true` in the iOS
  plist is required for 120 Hz on ProMotion iPhones and already ships in the current Flutter app
  template [R10-14] — verify it is still present after any iOS project regeneration.
- **A real frame-and-GPU budget applies from the very first screen**, not just to steady-state motion
  — this is Impeller's own framing for why the rules in §8.3 aren't optional polish [R10-10].

### 8.7 Illustration cost case: Lottie vs. Rive vs. code-driven — conclusion: code-driven stays the default

| Option | Runtime cost | Notes |
|---|---|---|
| **Lottie** (`lottie` 3.6.1) | Pure-Dart renderer; 3.6.1 throttles frame scheduling to the composition's own frame rate instead of every vsync; a `renderCache.raster` option trades memory for CPU [R10-25]. | Still a bundled-asset + parse + per-frame-interpret cost the app doesn't otherwise pay. |
| **Rive** (`rive`/`rive_native` 0.14.11/0.1.11) | Native C++ runtime; draws to a native texture *per widget* unless explicitly shared via `RivePanel`; no published APK-size or battery figures [R10-26]. | Vendor claims of a large size/perf edge over Lottie (e.g. "240 KB Lottie → 16 KB Rive") are vendor-sourced with no independent 2024-26 Flutter benchmark found in this research pass [R10-27] — **do not treat those numbers as verified**. |
| **Code-driven** (`AppMotion`/`MotionGuard`/`core/motion` primitives, Hero's actual approach) | No parse cost, no extra runtime, no extra package weight; cost is fully accounted for by the rules in §8.3-§8.4 above (the same rules any Lottie/Rive-driven `CustomPainter` would also have to obey). | This is §9 (decision summary) §1's decision: *"No parallel system: extend `AppMotion`/`MotionGuard`/`Haptics`… No new packages (no Lottie/Rive/animations pkg); the unused 2.29 MB GIF is removed."* |

**Conclusion, consistent with §9 (decision summary):** stay code-driven by default. Neither Lottie nor Rive
has a Flutter-specific, 2024-26, independently-measured performance claim strong enough in this
research pass to justify adding a second animation runtime and its parse/texture/package cost on top
of a primitive set (`core/motion`) that already covers Hero's actual motion vocabulary (§8.7 of
this document/decisions.md §13). Revisit only if a specific illustration (not a UI-state
animation) needs vector detail no `CustomPainter` can reasonably express — and even then, prefer Rive
over Lottie for that one case (native runtime, no per-frame Dart interpretation cost) rather than
adopting both.

### 8.8 Per-pattern performance budget summary

| Pattern | Budget / rule | Evidence |
|---|---|---|
| Any single frame, 60 Hz screen | ≤ 16.6 ms UI + raster combined | R10-02 |
| Any single frame, 120 Hz screen (ProMotion / high-refresh Android) | ≤ 8.3 ms combined | R10-01, R10-02 |
| Ambient/decorative loop (glow, float, sweep, marquee) | Stops off screen, hidden tab, background, reduced motion, screen reader; ≤ `ambientBudget` 5000 ms before it must rest even on screen | §9 (decision summary) §19; Appendix B PB-02, PB-05, PB-24 |
| Any animated `Opacity` | `FadeTransition`/`AnimatedOpacity`, never the raw widget, in a per-tick builder | R03-03, R10-06; Appendix B PB-18, PB-21 |
| Any static (non-animated) dim/tint | Decoration/colour alpha, not `Opacity` | R10-06; Appendix B PB-26 |
| Any blur ("glass") | Group behind one `BackdropGroup`; bound to its own rect | R03-06, R10-09 |
| Any `saveLayer` | Bounded to the minimum rect that needs it; never `null` | R10-05; Appendix B PB-03 (unbounded, High), PB-28 (bounded, Low) |
| Any clip inside an animation | `borderRadius` on a decoration, or pre-clip the asset; never `antiAliasWithSaveLayer` | R03-05, R10-07 |
| Any `AnimatedBuilder`/`ListenableBuilder` | Always pass static content as `child:`; never rebuild what doesn't animate | R03-10; Appendix B PB-04, PB-07, PB-11, PB-18, PB-21, PB-29 |
| Any list-item entrance | Survives scroll-back (`AutomaticKeepAliveClientMixin` or a played-once set); never replays on scroll-back, filter, sort or a route transition | §9 (decision summary) §17; Appendix B PB-09, PB-10, PB-30 |
| Any repeated countdown/ticking display | One shared clock per page (`SecondClock`), not one timer per instance | Appendix B PB-06 |
| Any network image | Bucketed request sizes so card→detail shares a cache entry; explicit resize policy matched to the source aspect ratio; `cacheExtent`/`precacheImage` tuned for the next screen | Appendix B PB-13, PB-32, PB-33 |
| App backgrounded | Every timer/ticker pauses from one `AppLifecycleListener`, not per-widget | R10-18; Appendix B PB-16 |
| Illustration/mascot motion | Code-driven (`CustomPainter` + `core/motion`) by default; no Lottie/Rive without a specific, justified need | §9 (decision summary) §1; §8.7 above |

Full Phase 3 report: Appendix B.


## 9. The Hero 2026 Motion & Interaction System

### 9.1 Principles
1. **Purpose or nothing.** Every animation names one job (feedback, continuity, orientation, perceived speed, state change, attention or delight), or it is cut [R02-01][R08-07].
2. **Input first.** Motion never blocks, delays or hides what the user asked for, and every animation can be interrupted and reversed mid-flight [R08-06][R02-04].
3. **Direction is meaning.** Horizontal means forward and back in a flow (mirrored in RTL), vertical means modal, and a fade means unrelated [R09-05][R02-02][R09-04].
4. **Small and quick.** Motion lasts 100-300 ms and no more than 400 ms when it is functional. Exits are shorter than entrances. Springs move things; tweens fade and colour them [R09-26][R04-22][R01-02].
5. **One primary motion per moment.** Delight is rare and earned, and never repeated on every visit [R08-08][R08-32].
6. **Still when idle.** Only real progress may loop. Decorative motion stops within 5 s, off screen and in the background [R07-03][R10-18].
7. **Reduce means replace.** Under reduced motion, movement becomes a short fade, the meaning stays, and haptics still fire [R02-26][R07-05][R07-32].

### 9.2 Token table

Tokens live in `AppMotion` (`core/motion/motion.dart`). `AppSprings` stays in `spring_curve.dart`, but `motion.dart` re-exports it and documents it as the spatial half of one token story. Counts are refs / files (C2 table A).

**Kept / extended**

| Name | Value | Curve | Use for | Replaces (refs) |
|---|---|---|---|---|
| `microPop` | 100 ms | `signature` | press-in, tiny ticks | kept (2) · now the press-in value |
| `fast` | 150 ms | `signature` / `exit` | fades, colour, press release, small exits, skeleton → content, image fade, tab fade | kept (73 / 57) |
| `medium` | 250 ms | `signature` / `exit` | component state change, value roll / flip, dialog enter, sheet and modal exit, expand | kept (69 / 55) · absorbs `flip` |
| `page` | 300 ms | `signature` | page push / pop, sheet enter, carousel slide | kept (33 / 30) |
| `slow` | 400 ms | `signature` / `emphasizedDecelerate` | fly-to-cart, large sheet enter, scroll-to glide, earned count-up; the functional ceiling | kept (23 / 19) · absorbs `sheetLarge`, `countUp` |
| `staggerStep` | 30 ms | — | the only cascade step | kept (4) · replaces 12 feature literals (35-80 ms) + the `stagger_entrance.dart:20` literal (C2 #2) |
| `loaderDelay` | 150 ms | — | show-delay for every loader, also under reduced motion | kept (3) |
| `busyMinVisible` | 500 ms | — | submit overlay minimum | kept (3) |
| `breathe` | 600 ms | `machEaseInOut` | a single `TintFlash` wash ("changed", "back online") | kept (4) |
| `drawOn` | 700 ms | `emphasizedDecelerate` | self-drawing check / outline / ready wipe only | kept (10 / 7) · its 3 misuses (bell, "+1", home reveal) move to their own consts (C2 #3) |
| `shimmer` | 1100 ms | `linear` | skeleton sweep | kept (4) [R05-07] |
| `loaderOrbit` | 1200 ms | brand swap curve | brand two-dot loader | kept (3) |
| `confetti` | 1400 ms | physics | one celebration burst | kept (4) |
| `carousel` | 3000 ms | — | auto-advance dwell, rotating hint / ticker dwell | kept (7 / 5) · replaces `AssistantComposerHint.every` 4 s (C2 #9) |
| `floatLoop` | 3200 ms | `machEaseInOut` | one ambient float cycle (fix: one leg is half a cycle, A01) | kept (4) · absorbs `glowPulse` |
| `sheen` | 3600 ms | `linear` | `LightSweep` pass + rest | kept (10 / 6) · home-loop arithmetic on it is removed (C2 #3) · absorbs `shineSweep` |
| `signature` | Cubic(0, 0, 0.2, 1) | — | default enter / standard | kept (107 / 90) · absorbs `standard`, `decelerate` |
| `exit` | Cubic(0.4, 0, 1, 1) | — | every exit / dismiss | kept (38 / 34) |
| `emphasizedDecelerate` | Cubic(0.1, 0.7, 0.1, 1) | — | large reveals, count-up, draw-on (M3 uses 0.05; the difference is not visible, keep) [R01-15] | kept (50 / 45) |
| `machEaseInOut` | Cubic(0.42, 0, 0.58, 1) | — | "move from A to B while visible" (thumbs, ambient float) [R04-23] | kept (18 / 16) · absorbs the raw `Curves.easeInOutCubic` ×2 (C2 #11) |
| `dialogScaleBegin` | 1.1 | — | dialog enter scale | kept (1) |
| `AppSprings.snappy` | ζ 0.6 · k 800 (about 320 ms) | spring | small spatial pops: check, badge, add → stepper, chip | kept (34) · absorbs `emphasized` (easeOutBack) |
| `AppSprings.calm` | ζ 0.9 · k 700 (about 210 ms) | spring | thumbs, digits, loader disc, predictive-back cancel, pull-to-refresh settle | kept (7) |

**New**

| Name | Value | Curve | Use for | Replaces |
|---|---|---|---|---|
| `successHold` | 400 ms | — | a success state stays before moving on | moved from `AppSprings.successHold` (3) |
| `linear` | `Curves.linear` | — | loops, shimmer, marquee, scroll-driven | new · replaces raw `Curves.linear` ×8 (C2 table E) |
| `blinkPeriod` | 1000 ms | — | caret / recording dot blink | new · replaces 2 local 1000 ms (C2 #12) |
| `snackDwell` | 4000 ms | — | snack bar dwell (theme) | new · Material default today [R05-03] |
| `ambientBudget` | 5000 ms | — | total run time of any decorative loop before it rests | new [R07-03] |
| `pressedScale` | 0.97 | — | the one card / button press depth | new · replaces 0.95 / 0.96 / 0.97 / 0.98 per widget (A10 #3) |
| `pressedScaleSmall` | 0.92 | — | icon buttons under 48 dp | new · replaces 0.9 / 0.92 |
| `slideShift` | 30 dp | — | shared-axis page shift | new · lifts the constant out of `hero_shared_axis_transition` [R09-01] |
| `entranceRise` | 8 dp | — | list and cascade item rise | new · replaces 8 % / 12 % / 8 dp variants (A01) |
| `staggerMaxItems` | 6 | — | cascade cap (items after the 6th start with the 6th) | new · replaces caps 4 / 5 / 6 / 7 / 8 / 10 (C1 E4) |

**Retire** (**16** tokens, current use in brackets)

| Token | Refs / files | Goes to | Note |
|---|---|---|---|
| `standard` | 13 / 12 | `signature` | an alias (C2 #8) |
| `decelerate` | 3 / 3 | `signature` (dialog enter) / `exit` | dialog exit gets `exit` |
| `emphasized` (easeOutBack) | 15 / 13 | `AppSprings.snappy` | PopScale feel changes slightly **[BEHAVIOUR CHANGE, minor]** |
| `popup` | 1 / 1 | `medium` | misused by the tab mark morph (C2 #3) |
| `imageFade` | 1 / 1 | `fast` | **[BEHAVIOUR CHANGE]** 500 → 150 ms |
| `sheetLarge` | 4 / 4 | `slow` | large sheets 500 → 400 ms **[BEHAVIOUR CHANGE]**; scroll-to-top uses `slow` [R08-05][R04-22] |
| `flip` | 6 / 3 | `medium` | 280 → 250 ms |
| `countUp` | 4 / 2 | `slow` | 700 → 400 ms **[BEHAVIOUR CHANGE]**; the tracking stepper gets its own const |
| `glowPulse` | 3 / 2 | `floatLoop` + `ambientBudget` | the GlowPulse primitive retires |
| `shineSweep` | 2 / 1 | `sheen` | |
| `popScaleBegin`, `popScaleEnd`, `pageSlideBegin`, `pageSlideEnd` | 1 / 1 each | private consts in their one primitive | trivial scalars (C2 #8) |
| `AppConstants.heroAutoAdvance`, `searchHintRotate` | 0 | delete | second source of truth (C2 #9) |

**Move (not retire):** the 8 `splash*` tokens (1-3 refs each) go to a feature-local `SplashMotion`, with the same values. The splash decision is kept (C2 #8).

**Totals:** 23 kept + 10 new = **33 tokens proposed**; **16 retired**; 8 moved.

**MotionGuard** (same class, 3 additions):
- `reduced(context)`: true when `disableAnimations` is on (Android "Remove animations"), or when iOS `accessibilityFeatures.reduceMotion` is on [R07-10][R03-24][R01-35].
- `off(context)`: new. Only `disableAnimations`. Motion becomes instant, as today.
- `reduced && !off` means **replace**. Spatial movement becomes a `fast` cross-fade, loops stop, and loaders keep a slow opacity breathe [R07-11][R07-09][R08-15].
- `ambientAllowed(context)`: new. False under `reduced`, with a screen reader (`accessibleNavigation`), when `TickerMode` is off, or off screen. It replaces the ad-hoc checks in 8 files (baseline §2).
- `scrollTo(position, to, …)`: new. Jumps instead of animating a zero duration, which fixes the `im_chat_body.dart:87` assert (C2 #1).

### 9.3 Primitive catalogue

Call sites are instantiations / files outside `core/motion`.

**`core/motion`**

| Primitive | Sites | Decision | Reason |
|---|---|---|---|
| PressScale | 70 / 70 | **keep** + absorb `HomePressable` (4) | One press. Depth comes from `pressedScale` / `pressedScaleSmall`. Default `haptic` becomes **none** (opt-in) [R07-29][R08-33] **[BEHAVIOUR CHANGE]**. Stacked presses (card + "+") are not allowed (A07 #9) |
| PopScale | 40 / 40 | **keep**, narrowed | `.onMount` (30) only for dots and badges of 24 dp or less, or empty-state art from 0.9. `popKey` "changed" use (10) moves to ChangeBump (C1 #6) [R08-03] |
| PopSwitcher | 12 / 11 | **keep** + absorb 5 raw add → stepper swaps (C1 #9) | One in-place swap |
| ChangeBump | 10 / 10 | **keep** | "This value changed", badges on land |
| ShakeX / BlockedTapShake | 9 / 8 · 2 / 2 | **keep** + absorb `HomeBellRing` (rotate axis) (C1 #14) | One decaying swing |
| TintFlash | 1 / 1 | **keep** + `PlayWhenVisibleMixin` shared with ReadyWipe (C1 #16) | Single wash |
| FlipValue | 11 / 10 | **keep** for labels and time; drop `axis` (0 callers, not RTL-safe) (C1 #21) | Short text swap |
| RollingNumber (+ RollingGlyph) | 6 / 6 | **keep**, the one number primitive; adopt in `CatalogPillStepper` and the checkout / deals steppers | Quantities and money (A10 #1, A04) |
| CountUpText | 7 / 7 | **keep**, restricted | Earned amounts after an action only; `from: 0` on open is banned (A01, A04, A07 #5) |
| EntranceCascade / Item | 2 / 2 · 4 / 3 | **keep**, the one list entrance | Absorbs StaggerEntrance, HomeReveal*, ListingReveal*, LedgerRowEntrance, the offers gate (C1 #1-#3) |
| StaggerEntrance | 30 / 16 | **retire → EntranceCascade** | Timer-based, replays on remount, raw 30 ms default (C1 #3, P3-2, P3-16) |
| ScrollReveal | 14 / 14 | **keep** + a cancellable delay (P1-9) | "First seen in the viewport"; its measure is shared with the new OnScreen gate |
| ListItemTransition | 2 / 1 | **keep** | Cart line insert / remove |
| FadeThroughSwitcher | 27 / 26 | **keep** + a `crossFade` mode (`fast`, no 0.92 scale, no 105 ms blank) for skeleton → content | Fade-through stays for unrelated swaps. Its reduced-motion fade already fits the "replace" rule |
| SizeFadeSwitcher | 3 / 3 | **keep** | Swap with a size change |
| CollapseReveal | 24 / 23 | **keep** + absorb AnimatedAccordion (3), 3 near-copies and 6 raw bars / errors (C1 #7) | One show / hide |
| FloatLoop | 7 / 7 | **keep** as a preset of AmbientLoop; bounded by `ambientBudget`; leg bug fixed | A01 |
| IdleLoop | 2 / 2 | **keep** as a preset of AmbientLoop (mark cape) | Brand |
| GlowPulse | 3 / 3 | **retire → FloatLoop preset** | Endless; `Opacity` rebuilt every frame (P1-6, P2-L1) |
| AmbientLoop (engine) | — | **new**: merges the IdleLoop, FloatLoop, GlowPulse and `HomeLoop` (5) engines; `active` + OnScreen + `ambientBudget` | C1 #4, P1 rec 2 |
| OnScreen gate (`PlayWhenOnScreen`) | — | **new**: the viewport + TickerMode + lifecycle gate, promoted from `HomeReveal` | P1 rec 2, P3-17 |
| RotatingLine | 1 / 1 | **keep** + absorb the home ticker, search hint and composer hint (7 copies) (C1 #8) | Stops off screen and in the background |
| SecondClock / Scope | 7 files | **keep** + absorb the CountdownChip and HomeCountdownText timers (C1 #11, P1-3) | One clock per page |
| ConfettiBurst / ConfettiOverlay | 5 / 5 · 1 / 1 | **keep both entry points**; share one `ConfettiPiece.scatter` (C1 #15) | Allowed moments only (§9.4) |
| FlyToCart | 16 files / 23 | **keep**; use `FadeTransition`, not `Opacity` (P2-L2); a shared `CatalogCartGestures.add/remove` (C2 #7) | One add gesture |
| LocaleSwapVeil | 1 | **keep** + `IgnorePointer`; haptic moves to the page listener (C1 #19) | A09 11.5 |
| SpringCurve / AppSprings | 34 + 7 refs | **keep**, re-exported from `motion.dart`, doc fixed (C2 #13) | |
| Haptics | 88 calls | **keep** + intent helpers (`cartAdd`, `cartRemove`, `refuse`, `commit`, `done`) | §9.5 |
| LightSweep (core/widgets) | 12 / 12 | **keep, move to core/motion**; at most 2 passes and 1 per screen; OnScreen-gated | C1 #17, A01 |
| ReadyWipe (core/widgets) | 2 / 2 | **keep, move to core/motion** | CTA "ready" |
| AssistantEntrance (feature) | 10 / 8 | merge candidate → see Assistant spec | C1 E2 |

**Navigation (`core/navigation`)**

| Type | Sites | Decision | Reason |
|---|---|---|---|
| HeroTransitionPage | 35 (34 routes + error page) | **keep the name; motion becomes shared axis X** **[BEHAVIOUR CHANGE]** | Forward push is horizontal and mirrors in RTL [R09-05][R02-02]. Fixes the half-played shared axis (A06 #5) |
| HeroSharedAxisPage (+ transition) | 2 + `_orderPage` (3 routes) | **merge into HeroTransitionPage** | Same motion once the default is horizontal |
| HeroSlideUpTransitionPage | 3 | **keep** for modals; exit uses `exit` over `medium` | It differed only in pop curve (C1 #13) |
| HeroFadeThroughPage | 1 | **keep** for top-level swaps; settle scale 0.92 like the switcher | C1 #13 |
| HeroCrossFadePage | 2 | **keep** for login → OTP (brand backdrop continuity) [INFERENCE] | |
| Predictive back / iOS swipe | 0 | **new** on all 4 page types; needs `android:enableOnBackInvokedCallback="true"` (touches `android/**`: needs approval) | [R01-19][R03-13][R03-14] |
| `showHeroBottomSheet` | 16 files | **keep**, retuned (large 400 ms, exit `medium`/`exit`) | |
| `showHeroDialog` | 9-10 files | **keep**; enter `signature`, exit `fast`/`exit` | |
| `showHeroSnackBar` | 35 files / 46 | **keep** + a `snackBarTheme` (floating, AnimationStyle, `snackDwell`) | Material default today (A09) |
| `navigation.dart` barrel | — | export all page types (C1 #13, #18) | |

**Loaders and state widgets (`core/widgets`)**

| Widget | Sites | Decision | Reason |
|---|---|---|---|
| AppLoader / DelayedLoaderDisc | 26 / 32 | **keep**; keep the 150 ms delay under reduced motion (A06, A10 #15); scale from 0.9, not 0.7 | [R08-12] |
| BrandedDotLoader / BrandedLoader / LoaderDisc | — | **keep** (brand); under `reduced && !off`, an opacity breathe replaces the orbit **[BEHAVIOUR CHANGE]** | [R08-15][R07-14] |
| BusyOverlay / CubitBusyOverlay | 2 / 13 files | **keep** | Contract §3 |
| BrandedRefresh + RefreshDiscHeader | 18 files | **keep** | |
| Skeletonized (+ 6 layouts) | 11 | **keep** + a `RepaintBoundary` (P2-M3); sweep mirrors in RTL | [R05-07][INFERENCE] |
| HeroStateView / EmptyStateView / ErrorView / FailureView | 7 / 22 / 10 / 17 files | **keep**; one entrance (fade + 0.9 → 1, `medium`, once) for every variant; no loop (the FloatLoop on empty coupons retires); issue plates (`HeroStateView.failure`, `StateArtMotions`) then tell their story inside the ambient budget (2026-10-05); checking → offline cross-fades (A06 #14) | A10 #9-#10 |
| StaleDataNotice / StaleAgePill / CubitStaleNotice | 2 + | **keep**; `CollapseReveal` both ways instead of snap + `Opacity` (A06 #11) | |
| ConnectivityBar (banner) | 1 | **keep** (CollapseReveal + TintFlash) | |
| RetryingNetworkImage / HeroNetworkImage | 2 | **keep**; `fast` fade, gated, no placeholder fade stacking (P3-5) | |
| AnimatedAccordion | 3 | **retire → CollapseReveal** | C1 #7 |
| BrandBackdrop | login / OTP | **keep** (brand); static layer + one moving ring; rests when idle (P2-H1) | |
| CountdownChip / CountdownDigits | 3 / 2 | **keep**; clock from SecondClock | P1-3 |
| CountBadge | — | **new**, merges the 6 badge copies (CartBasketBadge, ShellNavBadge, MineUnreadBadge …) | C1 #6 |
| AnimatedProgressBar | — | **new**, merges 3 progress-fill copies | C1 #22 |

**Retire / merge count: 9 primitives.** StaggerEntrance, GlowPulse, AnimatedAccordion, HeroSharedAxisPage, `HomeLoop`, `HomePressable`, `HomeReveal*`, `ListingReveal*`, `LedgerRowEntrance`. AssistantEntrance is deferred to the Assistant spec. **New: 5.** AmbientLoop, OnScreen gate, CountBadge, AnimatedProgressBar, predictive back on the page types.

### 9.4 Pattern specs

Legend: **P** = purpose; **Dur** = duration; **H** = haptic; **RM** = reduced-motion fallback (`reduced && !off`; under `off` everything is instant); **Perf** = budget.

Global perf budget: fit 8 ms per frame at 120 Hz (16 ms at 60 Hz), UI thread plus raster [R10-01][R10-02]. Animate transform and opacity only, through `*Transition` widgets or a painter driven by a `Listenable` [R03-10][R10-06]. No `Opacity` widget in a per-frame builder, and no animated clip, blur or shadow [R03-03][R03-05][R10-07][R10-08]. Put a `RepaintBoundary` around the moving child [R10-21]. Measure in profile mode on a real device [R10-03].

1. **Press feedback.**
   - Trigger: pointer down on any tappable card, button or tile.
   - P: feedback. Motion: `PressScale` to `pressedScale` 0.97 (icon buttons `pressedScaleSmall` 0.92). Dur: in `microPop`, out `fast`. Curve: `signature`.
   - H: none by default; `tap` only on commit buttons (AppButton, HeroSubmitButton).
   - RM: no scale; the press tint (ripple colour) stays [R07-01].
   - RTL: none. Perf: one `ScaleTransition`, nothing else rebuilt.
   - Evidence: [R05-08][R08-02][R08-03][R07-29].
2. **Add-to-cart + fly-to-cart + badge.**
   - Trigger: tap "+" or "Add".
   - P: feedback + continuity + state change.
   - Motion:
     - (a) The button becomes a stepper in place (`PopSwitcher`, `snappy`), optimistic.
     - (b) A 56 dp thumbnail flies on a lifted bezier to the cart target (`FlyToCart`, `slow`, `signature`).
     - (c) On land, the badge `ChangeBump`s (`snappy`) and its count rolls (`RollingNumber`, `medium`).
   - Rules: no flight target means (a) + (c) at once. At most 3 flights at a time.
   - H: `Haptics.cartAdd()` → `selection` at tap. On Home only, the first add of a session → `success` (+ confetti, a kept decision).
   - RM: no flight; the badge tints (`TintFlash`, `fast`) and the count changes [R04-20].
   - RTL: the flight path comes from real positions (no mirroring); the stepper grows from the directional corner (`AlignmentDirectional`).
   - Perf: one overlay entry, `Transform` + `FadeTransition`, no `Opacity` (P2-L2).
   - Evidence: [R05-32][R05-33][R08-20][R08-18]. Do not use the "+12 %" claim [R04-30].
3. **Qty stepper.**
   - Trigger: tap + or −.
   - P: state change. Motion: the digits roll (`RollingNumber`), up for +, down for −. Dur: `medium`. Curve: `signature`.
   - H: + → `selection`, − → `tap`; below the minimum or at the stock limit → `BlockedTapShake` + `warning` (the PDP "+" at stock is silent today, A07 #15).
   - RM: the number cross-fades `fast`.
   - RTL: rolls are vertical; digits keep tabular widths; buttons follow directional order.
   - Perf: the glyph column sits in a `RepaintBoundary`.
   - Evidence: [R02-19][R08-28][R08-26].
4. **Value change** (price, total, count, balance).
   - Trigger: the value changes after a user action or a server reply.
   - P: state change. Motion: `RollingNumber` for money and quantities; `FlipValue` for short labels and time; `CountUpText` only for an amount the user just earned. Never animate on first paint. Dur: `medium` (count-up `slow`). Curve: `signature` / `emphasizedDecelerate`.
   - H: none (the action already fired one).
   - RM: `fast` cross-fade.
   - RTL: numbers stay LTR inside RTL text.
   - Perf: tabular figures, so the parent is not laid out again on every frame (P2-L3).
   - Evidence: [R08-27][R02-19][A01].
5. **List entrance.**
   - Trigger: the first data arrival for a list on a page that is not mid-transition.
   - P: perceived speed + orientation.
   - Motion: `EntranceCascade`: fade + `entranceRise` 8 dp, step `staggerStep` 30, cap `staggerMaxItems` 6. Dur: `medium` per item. Curve: `signature`.
   - Rules: it never replays on scroll-back, filter or sort (a filter swap uses `crossFade`). It is skipped when the page itself is entering (the route is the entrance) or when data comes from the device cache at mount.
   - H: none. RM: one `fast` fade for the whole list. RTL: vertical rise only.
   - Perf: one clock per list; a `RepaintBoundary` per animating item (P3-4).
   - Evidence: [R05-10][P3-1][P3-2][A01].
6. **Skeleton → content.**
   - Trigger: data replaces the skeleton.
   - P: perceived speed. Motion: `FadeThroughSwitcher(crossFade)`, no scale, no blank gap. Dur: `fast`. Curve: `signature`.
   - Rules: use a skeleton only for known list and grid structures and only when there is no device copy. The shimmer starts after `loaderDelay`; a load under about 1 s shows a static skeleton.
   - H: none. RM: instant swap; the shimmer holds still (a static skeleton).
   - RTL: the shimmer sweep runs from the start edge.
   - Perf: `Skeletonized` inside a `RepaintBoundary` (P2-M3).
   - Evidence: [R05-24][R08-17][R08-11][R05-07].
7. **Loader delay.**
   - Trigger: any wait with no known structure.
   - P: perceived speed. Motion: `AppLoader` waits `loaderDelay` 150, then fades `fast` + scale 0.9 → 1 `calm`; the dots orbit at `loaderOrbit`.
   - H: none.
   - RM: the delay is kept (fixes the flash, A06); the orbit becomes a slow opacity breathe.
   - RTL: the orbit turns counter-clockwise in RTL [R04-27].
   - Perf: no ticking during the invisible wait (P2-L8).
   - Evidence: [R08-12][R08-13][R08-15].
8. **Page push (forward, shared axis X).**
   - Trigger: `context.push` to a deeper or next step.
   - P: orientation + continuity. Motion: incoming +`slideShift` → 0 with fade 30-100 %; outgoing 0 → −`slideShift` with fade 0-30 %; pop reverses. Dur: `page`. Curve: `signature`.
   - H: none.
   - RM: a `fast` cross-fade only [R07-06].
   - RTL: the X sign flips with `Directionality`.
   - Perf: two `SlideTransition` + `FadeTransition`; check Adreno devices [R03-08].
   - Evidence: [R09-01][R09-05][R02-02].
9. **Tab switch.**
   - Trigger: a tap on a shell tab.
   - P: orientation. Motion: the incoming tab fades in `fast`; the icon scales to 1.12 (`fast`, `signature`; the Home mark morph uses `medium`, not `popup`); the outgoing tab cuts. Every hidden tab sits under `TickerMode(enabled: false)`.
   - H: none (navigation).
   - RM: instant. RTL: none.
   - Perf: hidden tabs stop all tickers (P1-1, High).
   - Evidence: [R09-02][R09-04][R10-19]. **[BEHAVIOUR CHANGE]** (the instant cut becomes a fade).
10. **Modal slide-up.**
    - Trigger: open PDP, image viewer, assistant chat, search from a pill, cart preview or the Pro paywall.
    - P: continuity + orientation (a layer you will close). Motion: 100 % Y + fade in; out down. Dur: in `page`, out `medium`. Curve: `signature` / `exit`.
    - H: none.
    - RM: `fast` fade.
    - RTL: vertical, no mirroring.
    - Perf: an opaque route; the page below stops.
    - Evidence: [R09-05][R02-03].
11. **Top-level swap (fade-through).**
    - Trigger: `context.go` between unrelated roots: splash → shell, sign-in → shell, sign-out / expiry → login, order placed → tracking.
    - P: orientation (no false hierarchy). Motion: out fades in the first 30 %; in fades + 0.92 → 1. Dur: `page`. Curve: `signature`.
    - H: none. RM: `fast` fade. RTL: none.
    - Perf: `SnapshotWidget` is allowed for the scale [R03-09].
    - Evidence: [R09-02][R09-04]. Using one page type for the shell also stops the tab-state reset (A02).
12. **Predictive back / iOS swipe back.**
    - Trigger: an edge back gesture.
    - P: orientation (preview, cancel).
    - Motion:
      - Android: the page scales 1 → 0.9 and shifts (w/20 − 8) dp with the finger; commit plays the pop spec; cancel `calm`.
      - iOS: the gesture drives the shared-axis progress.
      - Sheets shrink to 0.9.
    - Dur: gesture-driven. H: none.
    - RM: gesture tracking stays (user-driven) and the scale is dropped [R07-02][R07-05].
    - RTL: the back edge follows the platform.
    - Perf: transforms only.
    - Evidence: [R01-17][R01-24][R03-12][R03-14][R09-08]. Needs the manifest flag (approval).
13. **Bottom sheet.**
    - Trigger: `showHeroBottomSheet`.
    - P: continuity (a layer over context). Motion: slide from the bottom + scrim fade; drag 1:1; a fling carries velocity. Dur: in `page` (large `slow`), out `medium`. Curve: `signature` / `exit`.
    - Rules: one sheet at a time. The timing → slot flow swaps content inside one sheet instead of chaining sheets (A04, A09 11.4).
    - H: none on open; content decides.
    - RM: `fast` fade, no slide.
    - RTL: vertical.
    - Perf: no blur; the scrim is a colour alpha.
    - Evidence: [R09-12][R09-13][R03-17][R08-05].
14. **Dialog.**
    - Trigger: `showHeroDialog`.
    - P: attention (a decision is needed). Motion: fade + scale `dialogScaleBegin` 1.1 → 1; exit fade. Dur: in `medium`, out `fast`. Curve: `signature` / `exit`.
    - H: a destructive confirm button → `warning`; else `tap` on confirm.
    - RM: `fast` fade.
    - RTL: none.
    - Perf: `FadeTransition` + `ScaleTransition`.
    - Evidence: [R04-25][R05-02][R01-30].
15. **Snack bar.**
    - Trigger: `showHeroSnackBar` (background results and system events only).
    - P: feedback. Motion: a floating snack rises + fades; a replacement cross-fades. Dur: in `medium`, out `fast`, dwell `snackDwell`. Curve: `signature` / `exit`.
    - Rules: errors about a field or button show next to it, not in a snack.
    - H: none.
    - RM: fade only.
    - RTL: vertical; the action sits at the trailing edge.
    - Perf: theme-level `AnimationStyle` [R03-26].
    - Evidence: [R05-03][R04-24][R08-21][R08-22].
16. **Connectivity banner + stale note.**
    - Trigger: connectivity verdict changes; data shown from the device copy.
    - P: state change without alarm.
    - Motion:
      - Banner: `CollapseReveal` in `medium`, out `fast`.
      - "Back online" (`connectivity.back_online`): one `TintFlash` (`breathe`), then auto-collapse.
      - Stale note (`connectivity.updated_just_now` / `updated_minutes` / `updated_hours`, per CLAUDE.md §3.2): `CollapseReveal` `fast`; the age text updates with no motion.
      - Never a full-screen error over data; never pulsing or red flashing.
    - H: none on state changes. `refuse` (`warning`) only when the user tries an action that needs the internet (`connectivity.action_needs_internet`).
    - RM: fade only.
    - RTL: none.
    - Perf: one reveal; no `Opacity` widget (A06 #11).
    - Evidence: [R08-30][R08-29][R07-15].
17. **Empty state.**
    - Trigger: loaded with no items.
    - P: orientation. Motion: the icon or illustration fades + scales 0.9 → 1 once; the text and action are static. No `FloatLoop` (empty coupons / history today). Dur: `medium`. Curve: `signature`.
    - H: none.
    - RM: static.
    - RTL: the art mirrors only if it is directional (`matchTextDirection`).
    - Perf: one-shot.
    - Evidence: [R08-31][R08-08][A04].
18. **Error + retry shake.**
    - Trigger: a blocked tap or an invalid submit.
    - P: feedback (error). Motion: `ShakeX` on the source control (not a distant button); the inline reason appears with `CollapseReveal`; the border colour changes. On Retry, the state view cross-fades to the loader. Dur: shake `medium`, reveal `fast`.
    - H: `warning` (`Haptics.refuse()`).
    - RM: no shake; the colour and text only [R08-24].
    - RTL: the shake is symmetric.
    - Perf: one `Transform`.
    - Evidence: [R08-24][R08-26][R08-25]. Disabled-looking buttons still accept the tap and explain (A02 #2).
19. **Success / celebration.**
    - Trigger: order placed, first add of a session (Home), Pro subscribed, reward earned, profile saved (check only).
    - P: delight (earned) / feedback.
    - Motion:
      - Submit: the check draws (`drawOn`) in the button or disc, holds `successHold`, then the screen moves on.
      - The celebration moments add one `ConfettiBurst` (`confetti`, no more than 60 pieces, `IgnorePointer`).
      - Never confetti for routine actions. At most once per moment per session.
    - H: `success`, once.
    - RM: the check appears without a draw; no confetti [R08-32].
    - RTL: none.
    - Perf: one painter; the burst stops at `confetti`.
    - Evidence: [R08-23][R08-32][R07-33].
20. **Expand / collapse.**
    - Trigger: a tap on a disclosure row.
    - P: continuity. Motion: `CollapseReveal` (height + fade; the content stays drawn while closing); the chevron rotates 180°. Dur: open `medium`, close `fast`. Curve: `signature` / `exit`.
    - H: none (disclosure is navigation-like).
    - RM: instant height, `fast` fade.
    - RTL: a horizontal chevron uses `matchTextDirection`.
    - Perf: layout animation accepted for a one-shot on a single block; never in a list of more than 10 open at once [R10-22].
    - Evidence: [R09-26][A06 #2].
21. **Carousel / auto-advance.**
    - Trigger: a timer on banners, the ticker or the rotating hint.
    - P: attention (low). Motion: the page slides `page` / `signature`; dwell `carousel`; the hint and ticker use `RotatingLine` (vertical swap, `medium`).
    - Rules: pause on touch and while dragging. Stop off screen, on a hidden tab, in the background, under RM, and with a screen reader. The page dots show position. The category shelf auto-glide follows the same rules (finding §5).
    - H: none.
    - RM: no auto-advance; manual swipe only [R02-27].
    - RTL: `PageView` follows `Directionality`.
    - Perf: one `SecondClock`-style timer per page, not per widget.
    - Evidence: [R07-03][R07-23][R07-24].
22. **Ambient loops.**
    - Trigger: rare hero art only: the Pro hero, the rewards badge, one "tap me" `LightSweep` per screen, the brand mark cape, the category shelf wash (kept). The buddy → see Assistant spec.
    - P: delight / attention.
    - Motion: `AmbientLoop` presets (float `floatLoop`, sweep `sheen` with at most 2 passes). All motion stops after `ambientBudget` 5 s and resumes only on a new trigger (revisit, pull-to-refresh).
    - H: never.
    - RM: a still frame.
    - RTL: the sweep runs from the start edge.
    - Perf: OnScreen gate + `TickerMode` + app lifecycle; `RepaintBoundary`; transitions, not `Opacity` (P1-2, P1-6, P2-L1).
    - Evidence: [R07-03][R08-09][R08-08][R10-18].
23. **Locale switch veil.**
    - Trigger: a language pick in Settings.
    - P: continuity (hides the relayout flash). Motion: `LocaleSwapVeil` in `fast`, out `medium`, starting with the thumb; taps are blocked while it is up.
    - H: `success` from the page's `BlocListener` when the switch commits (not from the cubit, C1 #19).
    - RM: an instant swap, no veil.
    - RTL: the veil is direction-free; the new layout arrives already mirrored.
    - Perf: one full-screen colour layer; no blur.
    - Evidence: [INFERENCE][A09 11.4-11.5].
24. **Pull-to-refresh.**
    - Trigger: an overscroll drag at the top.
    - P: feedback + perceived speed.
    - Motion: the disc follows the finger 1:1; past the threshold it is "armed"; on release it settles `calm` and the dots orbit; when done it shrinks `fast`. Empty and error states stay pullable.
    - H: `selection` once when armed.
    - RM: tracking stays (user-driven); the orbit becomes a breathe.
    - RTL: none.
    - Perf: `RefreshDiscHeader` repaints only the disc.
    - Evidence: [R07-02][R01-12][A07 #14].
25. **Image fade-in.**
    - Trigger: a network image decodes.
    - P: perceived speed. Motion: fade `fast` / `signature`; none when the image comes from the memory cache; no second placeholder fade.
    - H: none. RM: none (instant). RTL: none.
    - Perf: one `FadeTransition` per image; decode at the display size (P3-12, P3-14).
    - Evidence: [P3-5][R03-03].
26. **Scroll-linked header.**
    - Trigger: scroll.
    - P: orientation.
    - Motion: the header collapses 1:1 with the offset; the title reveals over the collapse range (the four app bars share one `ScrollReveal(title:)`, A01); the depth change is a colour or border, not an animated shadow. Parallax factor ≤ 0.5 and gated (recipe detail is not gated today, A07 #12).
    - H: none.
    - RM: collapse stays (user-driven); parallax off [R09-17].
    - RTL: none.
    - Perf: no layout per frame beyond the sliver; no shadow animation [R10-08]. Hide-on-scroll chrome is off with a screen reader [R09-15].
    - Evidence: [R07-02][R09-15][R02-30].
27. **Segmented switch / selection chip / radio.**
    - Trigger: a tap on a segment, chip or radio.
    - P: state change. Motion: the thumb moves with `AppSprings.calm` (`HeroSegmentedControl` everywhere, including the basket switch); a chip tints over `fast`; the radio mark springs in and fades out (`HeroRadioMark`; `RadioDot` merges into it, A10 #17).
    - H: `selection`.
    - RM: instant thumb; colour `fast`.
    - RTL: the thumb follows `Directionality`.
    - Perf: one transform.
    - Evidence: [R02-22][R04-26][A09 11.2].
28. **AI assistant** → see Assistant spec.

### 9.5 Haptics map

| Interaction | HapticKind | Never fire when |
|---|---|---|
| Add to cart / "+" / increment | `selection` (`Haptics.cartAdd()`) | The tap was refused (use `warning` instead) |
| First add of a session (Home only) | `success` (`cartAdd(first: true)`) | Any later add; outside Home |
| Remove / "−" / delete line | `tap` (`cartRemove()`) | — |
| Primary commit button (Add, Save, Continue, Place order) | `tap` on press | The button is busy; twice for one press (the button fires, PressScale does not) |
| Chip, segment, radio, option row, sort pick | `selection` | Programmatic selection |
| Pull-to-refresh armed | `selection` | Again during the same drag |
| Blocked tap, invalid submit, action needs internet | `warning` (`refuse()`) | More than once per 500 ms [INFERENCE] |
| Destructive confirm (delete address, cancel order, clear cart, log out, cancel Pro) | `warning` | Only on confirm, never on opening the dialog |
| Order placed, Pro subscribed, profile saved, reward earned, language switched | `success` (`done()`) | Routine saves; from a cubit (page `BlocListener` only) |
| Navigation (push, back, tab switch, row open, carousel, banner) | none | — |
| Loaders, snack bars, connectivity changes, value rolls, entrances, ambient loops | none | — |
| Assistant (thinking, landed answer, voice) | → see Assistant spec (note: haptics can disturb the microphone [R07-34]) | — |

Rules:
- Fire at the moment the visual confirms: tap-up, or land for flights [R07-31].
- Keep haptics under reduced motion [R07-32].
- Everything goes through `Haptics`, so `Haptics.enabled` can mute it (it needs a settings toggle: **[BEHAVIOUR CHANGE]**) [R07-30].
- One haptic per gesture.
- Negative events are stronger than positive ones [R01-30][R07-28].
- Evidence: [R02-22][R02-23][R07-26][R07-29][R08-33][R08-34][R01-27].

### 9.6 AI assistant motion spec


2026-09-28 · Phase 3 design, input for the "AI ASSISTANT — dedicated section" of
`docs/prompts/motion_system_2026_prompt.md`. Design only: no code was changed.

- **Stays inside §9 (decision summary).** "D#" means an item there (for example D17 = the list-cascade rule). Token names are the `AppMotion` names after the D2–D6 changes: `microPop 100 · fast 150 · medium 250 · page 300 · slow 400 · staggerStep 30 · loaderDelay 150 · successHold 400 · blinkPeriod 1000 · carousel 3000 · floatLoop 3200 · snackDwell 4000 · ambientBudget 5000 · entranceRise 8 dp · pressedScale 0.97 · pressedScaleSmall 0.92`, curves `signature / exit / emphasizedDecelerate / machEaseInOut / linear`, springs `AppSprings.snappy / calm`.
- **Evidence.** `[Rxx-yy]` = a finding in research_log_2026.md. `[INFERENCE]` = our own reasoning with no source.
- **Hero today.** Citations come from Appendix A (static audit, verified 2026-09-28). A few lines were re-read for this spec and are marked *(re-read)*.
- **Path legend.** `P/` = `lib/src/features/assistant/presentation/`, `W/` = `P/widgets/`, `D/` = `lib/src/features/assistant/domain/`, `core/` = `lib/src/core/`.

---

#### 0. The assistant's motion rules

1. **The answer comes first.** While a reply streams, the only things that move are the new words, and a card when it arrives. Avatars, chips, badges and hints stay still [R06-07][R08-08].
2. **The buddy is a face, not a performer.** It is still by default. It reacts briefly to real events and never loops for attention [R06-16][R06-17][R06-35].
3. **Only real work may loop.** Dots loop while the server works, and the dot and halo move while the microphone is open. Nothing fakes a wait [R06-34][R07-04][R08-10].
4. **One text reveal everywhere, by whole words.** The same widget reveals the stream, the buddy's lines, the greeting, the tour and the voice transcript. It never reveals letter by letter, so Arabic words keep their joined forms [R06-02][R06-04].
5. **Items that go into the cart travel to the cart.** A confirmed proposal uses the same `FlyToCart` as any other add. It never gets confetti (D16, D21 celebration list).
6. **Haptics mark the customer's own commits and outcomes.** An arriving reply never vibrates, and a haptic never fires while the microphone is recording [R07-29][R07-34].
7. **Reduced motion means replace, and a screen reader means calm.** Under reduced motion, movement becomes a `fast` fade and the meaning stays (D7). With a screen reader there are no proactive lines, no timed content and no ambient motion.

#### 1. New names this spec introduces

| Name | Where | What |
|---|---|---|
| `AssistantMotion` | `P/` feature-local const class (the same idea as `SplashMotion`, D6) | The assistant-only numbers, so no raw literals remain: mascot `blinkHalf 75`, `hop 720`, `wave 900`, `wink 420`, `lookHold 1100`. Reveal: `wordStepMin 30`, `wordStepMax 80`, `revealMax 1200`, `streamMaxLag 500`. Timing: `streamFlush 50`, `slowAfter 10 s`, `thoughtReadBase 1800` + `thoughtReadPerLetter 35`, `greetingShowFor 8 s`, `voiceLevelTick 70`, `holdScale 1.8`, `wakeBlinkGap 8 s`, `hopGap 30 s`, `followUpGap 90 s`. The mascot stays on the `feature_controller_allowlist` (system.md 9.8). |
| `AssistantWordReveal` | `W/` (shared by chat, buddy, greeting, tour, voice) | Whole-word reveal. Each new word fades in over `fast` using only span alpha. Words that are already shown never animate again, and finished text is plain. There are two modes: **network** (the stream) and **local** (known text). Details in §2.3. |
| `AssistantStepLine` | `W/chat/` | The status line under the thinking dots: a per-tool glyph plus a label. The label changes through `FlipValue`, and each label stays at least `successHold`. Details in §2.7. |
| `BuddyMotionGate` | `W/buddy/` (+ read by the chat avatar) | One boolean `mayMove`. It combines `MotionGuard.ambientAllowed` (D7) with the assistant's own signals: typing, streaming, recording, a busy or submit route, and another primary motion playing. Every buddy animation asks this gate. See §3. |
| `EntranceCascadeItem.single` | `core/motion` (added to the kept primitive) | A standalone one-shot entrance that plays on mount and needs no `EntranceCascade` scope: fade + `entranceRise`, `medium`/`signature`, `play: false` mounts it at rest. It replaces `AssistantEntrance` (§3.6). |
| `FlyToCart.inFlight` | `core/motion/fly_to_cart.dart` (a `ValueListenable<bool>`) | Lets the buddy wait while a flight is in the air (one primary motion at a time, principle 5 in system.md 9.1). |

---

#### 2. Per-interaction spec

Every item uses the same fields: **2026** · **Hero today** · **Gap** · **Do** · **Timing** · **Haptic** · **Reduced** · **RTL**.

##### 2.1 Idle state and the buddy's presence

- **2026:**
  - The assistant's "face" is a static entry icon, not a free-roaming mascot [R06-16].
  - Copilot's character is opt-in and appears only in voice sessions [R06-17].
  - The assistant lives in the search bar rather than in a floating bubble [R06-15].
  - Where a character moves, it reacts to app state instead of playing canned clips [R09-27][R09-28].
  - Delight fades into distraction with repetition, and self-animating controls count as a defect [R08-08].
  - Ambient loops over 5 s beside content need pause/stop [R06-35][R07-03].
  - Keeta's KiKi mascot aims at "warmth" [R04-10].
- **Hero today:**
  - **Launcher:** it slides off its edge and scales to 0.6 on every show/hide flip, using `page`/`emphasizedDecelerate` in and `medium`/`exit` out (`W/buddy/assistant_buddy_launcher.dart:91-101,145-151,332-341`). It moves by `Positioned`, so the Stack is laid out again every frame (`launcher:317-333`).
  - **Ambient mascot motion:** a blink every 3–7 s and a glance every 15–25 s, for 30 s after any touch (`W/mascot/assistant_mascot.dart:63-78`; `launcher:85`). Eyes follow every touch (`launcher:163-179`). A 720 ms hop plays on cart qty up, greeting close, tour end, drag landing and a playful line (`W/buddy/assistant_buddy_layer.dart:202-205`).
  - **Always-alive mascots:** the chat header and welcome avatars are `alive: true` (`W/chat/assistant_chat_title.dart:26`, `W/welcome/assistant_welcome_hero.dart:40`, re-read). So are the greeting-header and hide-sheet mascots, through the `AssistantMascot` default (`mascot:30`).
  - **Opposite defaults:** `AssistantAvatar` defaults to still (`W/chat/assistant_avatar.dart:15`).
- **Gap:**
  - The buddy loops on its own for 30 s after every touch.
  - Four surfaces blink independently, and two of them can blink at once (the hide sheet over the live launcher).
  - Timers ignore `TickerMode`.
  - Spatial motion causes layout work on every frame.
- **Do:** apply the policy in §3.
  - **Presence:** keep the slide + 0.6→1 scale, but drive it through `Transform` (paint only). Every movement goes through `BuddyMotionGate`.
  - **Idle:** replace the endless ambient scheduler with a *wake window*. After a wake trigger the mascot may blink once. The window closes after `ambientBudget`.
  - **Glance:** autonomous glances are retired. The eyes move only in reaction (a touch, or their own thought bubble rising).
  - **Defaults:** make `AssistantMascot` still by default (`alive: false`), matching `AssistantAvatar`. Only the shell launcher opts in to the wake window.
- **Timing:**
  - Presence: in `page` `signature`, out `medium` `exit`.
  - Wake blink: `AssistantMotion.blinkHalf` 75 ms × 2, at most 1 per `wakeBlinkGap` 8 s.
  - Look at a touch: `medium` ease, held `lookHold` 1.1 s.
  - Hop: 720 ms, at most 1 per 30 s (§3.1).
- **Haptic:** none for presence, blink, look or hop (D21: navigation, ambient, entrances = none). Gestures on the launcher are covered in §3.1.
- **Reduced:** no ambient motion at all. Presence is a `fast` fade in place. The eyes stay centred. A drag still tracks the finger and lands with no spring [R07-05].
- **RTL:** the launcher's home edge is the *end* edge, and slide-off moves toward that edge (mirrored). Looking toward a touch uses real screen x, so no mirroring is needed. A wave uses the mascot's end-side sprout.

##### 2.2 Thinking state (sent, no word yet)

- **2026:**
  - One explicit request state machine: submitted → streaming → ready/error [R06-06].
  - Show something at once, and let people keep using the app [R06-36][R08-15].
  - Under 1 s no feedback is needed; past 10 s, say when it will be done [R06-34].
  - The simplest good loader is a caret or dots [R06-33].
  - Gemini lights up half the screen with a glow while it thinks [R06-19][R06-20]. **Not adopted:** it is too loud for a grocery app and breaks "one primary motion" [INFERENCE].
- **Hero today:**
  - The thinking bubble mounts **with no entrance**, and the reply row has no `AssistantEntrance` (`W/chat/assistant_reply_layout.dart:42-45`, re-read).
  - It uses `BrandedDotLoader` with no `loaderDelay`. The label cross-fades from "Thinking" to the tool label to "Taking longer" at 10 s (`W/chat/assistant_thinking_bubble.dart:27,41,87,94-97`).
  - The avatar is in the **talking** mood, so a 150 ms mouth flap loops for the whole wait (`thinking_bubble:64`).
  - The header subtitle flips to "Typing…" (`W/chat/assistant_chat_title.dart:42`).
  - When the first word arrives, the bubble is swapped by a plain `if/else`, so the height and the avatar snap (`reply_layout:42-45`).
- **Gap:** a fast reply flashes dots. The mouth loop contradicts the steady caret. Thinking → text is a hard cut. The status line only changes by snapping.
- **Do:**
  - **Delay:** the reply row appears only after `loaderDelay` 150 ms. If the first word arrives sooner, no dots are ever drawn (D18).
  - **Entrance:** the row enters with `EntranceCascadeItem.single`.
  - **Dots:** `BrandedDotLoader`, a real progress loop that is exempt from the 5 s rule [R07-04].
  - **Avatar:** a **thinking** mood that holds a still pose (eyes up and to the side). There is no mouth loop.
  - **Status line:** `AssistantStepLine` sits under the dots (§2.7).
  - **Thinking → first word:** one bubble shell for the whole reply. `SizeFadeSwitcher` cross-fades the content in `fast`, the height eases over `medium`, and the avatar keeps its element, easing its mood thinking → idle over `medium`.
  - **Header subtitle:** keep the `FlipValue`.
- **Timing:** show delay 150 ms. Row entrance `medium` `signature`, rise 8 dp. Content swap `fast`, height `medium`. `AssistantMotion.slowAfter` 10 s → the label flips to "Taking longer…", and Stop stays visible.
- **Haptic:** none (loaders = none, D21).
- **Reduced:** the row appears by `fast` fade, and the dots switch to the loader breathe (D7, D18). The swap to text is an instant fade.
- **RTL:** everything is vertical or a fade. The dots follow the core loader's RTL rule, with no feature override.

##### 2.3 Streaming text reveal

- **2026:**
  - Keep chunk arrival separate from reveal pace, and reveal at a steady pace with word chunking (~5 ms/char, 10 ms delay) [R06-01].
  - Fade in **only newly added words** (150 ms). Finished messages are plain text [R06-02]. Reveal speed scales with reply length [R06-03].
  - The Flutter streaming package turns per-character fade **off for streams and RTL**; its "Claude" preset uses 80 ms per word [R06-04].
  - Throttle rebuilds to ~20/s [R06-05].
  - Don't auto-scroll to the end; keep the reader at the top of the new message [R06-07].
  - A blinking caret works as a loader [R06-33].
- **Hero today:**
  - Deltas are coalesced into at most one flush per 50 ms, and **only complete words** are drawn, so Arabic words never re-shape (`P/cubit/assistant_chat_cubit.dart:36-39`, re-read; `D/entities/assistant_live_turn.dart:174-179`, re-read).
  - Words appear without any animation.
  - The caret is a steady bar, not blinking on purpose, and excluded from semantics (`W/chat/assistant_streaming_caret.dart:7-9`, re-read).
  - Anchored physics follow the reply while it fits. Once it outgrows the screen, the list stops with the reply's start at the top and holds the reader's place when they scroll up (`W/chat/assistant_anchored_scroll_physics.dart:6-22`, `W/chat/assistant_scroll_anchor.dart`, re-read). **This already matches [R06-07].**
  - At `message_end` the caret disappears in one frame.
  - Screen readers get one announcement per landed reply (`P/pages/assistant_chat_page.dart:69-88`, re-read).
- **Gap:** words arrive in bursts of whatever came in 50 ms (sometimes 0, sometimes 8 words), so the reply "jumps". The caret end snaps.
- **Do:** `AssistantWordReveal`, **network mode**.
  - The cubit keeps its 50 ms flush and its complete-words rule. The data layer does not change.
  - The widget releases the words of each flush evenly over the next flush window, so the reveal trails the network by about 50 ms.
  - Each new word fades in from alpha 0 → 1 over `fast`. There is no slide and no blur (blur needs a saveLayer).
  - **Backlog:** if more than `streamMaxLag` 500 ms of words is waiting (a burst after a tool call), the rest appears in one fade. Never hold text back to put on a show.
  - **`message_end`:** the remaining words appear in one `fast` fade, and the caret fades out over `fast`.
  - **Perf:** only the last text block rebuilds. Word alpha is a span *colour* change, which Flutter compares as paint-only (`RenderComparison.paint`), so there is no re-layout. Verify this in a profile build (§6).
  - **Caret:** keep it steady. `blinkPeriod` is not used here, because the dots are the loader and the caret only marks "still writing".
  - **Auto-scroll:** keep today's anchoring as it is. On send, the glide to the newest row uses `MotionGuard.scrollTo` (D7, `slow` per system.md) and replaces the raw `animateTo(0, page)` (`W/chat/assistant_message_list.dart:86-95`, re-read). Never follow the stream past the reply's first line.
  - **Local mode** (known text, for the buddy, greeting, tour and voice): step = `clamp(revealMax 1200 ms / words, wordStepMin 30, wordStepMax 80)` per word, each word fading over `fast`. Longer text therefore goes faster per word, and no line takes more than 1.2 s [R06-03][R06-04].
- **Timing:** word fade `fast` 150 ms linear alpha. Network lag about 50 ms, at most 500 ms. Local pace 30–80 ms per word, total ≤ 1.2 s. Caret out `fast` `exit`.
- **Haptic:** none per word and none when the reply lands. Remove today's `selection` (`page:78-80`) (**approval** §4 #9).
- **Reduced:** words appear with no fade (they stay whole-word, so Arabic is still safe). The caret has no fade.
- **RTL:** word-level only, never per grapheme, so Arabic joining forms never change mid-word [R06-04]. A "word" is a whitespace-delimited token, so prices and numbers inside Arabic text appear whole. The caret sits at the logical end of the text (`EdgeInsetsDirectional.only(start:)`, already the case).

##### 2.4 Chat bubble entrance and grouping

- **2026:** the composer text morphs into the sent bubble [R06-33]. New words slide up 4 px [R06-02]. Follow-ups sit under the answer [R06-09].
- **Hero today:**
  - **Sent bubble:** it rises by 0.3 of its height and scales from 0.96 at its end-bottom corner, through `AssistantEntrance` with `medium`/`emphasizedDecelerate` (`W/chat/assistant_user_bubble.dart:55`; `W/chat/assistant_entrance.dart:46,71`). At most 2 fresh rows animate, and opening from history never animates (`W/chat/assistant_message_list.dart` `_markFresh`, re-read).
  - **Reply row:** it has no entrance.
  - **Grouping:** one row per turn, in canonical order: text → cards → footer (`reply_layout:10-12`, re-read). Every reply text bubble carries its own still avatar (`W/chat/assistant_text_bubble.dart:44`, re-read).
  - **Actions row:** copy + thumbs **snaps** in at `message_end` while the chips below it animate (`W/chat/assistant_message_footer.dart`).
- **Gap:** the sent bubble has a large rise and a corner scale that nothing else in the app uses. The reply appears with no entrance. The footer's parts behave unevenly.
- **Do:**
  - **Sent bubble:** `EntranceCascadeItem.single`, fade + `entranceRise` 8 dp. Drop the corner scale (**approval** §4 #14). A morph from the composer is not adopted: it costs a shared-element overlay for little gain [INFERENCE].
  - **Reply row:** it enters once, as the thinking row (§2.2), and never enters again. Cards enter inside it (§2.6).
  - **Footer at `message_end`:** the actions row fades in over `fast`, and the chips cascade under it, starting in the same frame (§2.5). Both use `CollapseReveal`/`SizeFadeSwitcher`, so the height eases over `medium` and never snaps.
  - **Grouping:** keep turn grouping and one still avatar per reply bubble.
  - **Divider row:** the "New chat started" row (`W/chat/assistant_divider_row.dart`) fades in over `fast` when it is inserted live.
  - **History:** rows opened from history or recycled never animate. Keep `_markFresh` and pass it as `play:`.
- **Timing:** entrances `medium` `signature`, rise 8 dp. Footer fade `fast`, height `medium`.
- **Haptic:** send = `tap` (commit, D21). Keep `W/composer/assistant_composer.dart:75`. Nothing else.
- **Reduced:** `fast` fade in place, with no rise and no height ease.
- **RTL:** the rise is vertical, so no mirroring is needed. The sent bubble stays aligned to the end and the reply to the start.

##### 2.5 Suggested-action chips

- **2026:**
  - Tappable buttons, not text; they update with context and stay available after the first turn [R06-08].
  - They go below the answer they relate to [R06-09].
  - Rufus: tap suggested questions [R05-35]. Glovo: swipeable suggestion cards [R04-03] (not a fit for text chips).
- **Hero today:**
  - Chips slide in from the start edge with a 30 ms stagger (`W/chat/assistant_suggestion_chips.dart:28,40-43`), only on the newest reply (`assistant_message_footer.dart`, re-read). Older chips **vanish in one frame** when a new turn starts.
  - Other chip rows use different staggers: welcome starters 40 ms (`W/welcome/assistant_starter_chips.dart:22,43-47`), greeting starters 50 ms (`W/buddy/assistant_buddy_starters.dart:26-27,48`), tour starters 60 ms + a 160 ms lead (`W/onboarding/assistant_onboarding_starters.dart:28-29,48-51`).
  - Press is `PressScale` with the default `tap` haptic.
- **Gap:** four stagger values, a horizontal slide that no other list in the app uses (D17 is vertical), a snap when chips leave, and the wrong haptic kind for a pick.
- **Do:**
  - **Entrance:** every chip row is `EntranceCascade` + `EntranceCascadeItem` (D17): `staggerStep` 30, at most `staggerMaxItems` 6, fade + 8 dp rise, `medium` `signature`. Mount the row only when its content is ready instead of using timer delays; the greeting starters mount when the message reveal ends.
  - **Tap:** `PressScale` at `pressedScale` 0.97 (in `microPop`, out `fast`). The chip row collapses (`CollapseReveal`, `fast` `exit`) as the chip's text enters as the sent bubble (§2.4).
  - **Chips of an older reply:** they collapse over `fast` `exit` when a new turn starts, instead of vanishing.
- **Timing:** first chip starts in the `message_end` frame. The last of 6 starts at +150 ms and ends at +400 ms.
- **Haptic:** `selection` (chip pick, D21) instead of `tap`. Only one per tap: the `PressScale` haptic is off (D13).
- **Reduced:** the row appears by one `fast` fade, with no stagger.
- **RTL:** the rise is vertical, so there is nothing to mirror. The chips wrap from the start edge.

##### 2.6 Cart-proposal cards (arrive, confirm, reject, link to the cart)

- **2026:**
  - Confirm before significant actions; never buy on the user's behalf automatically [R06-11].
  - Instacart reviews first: nothing is finalised without an explicit action [R06-13]. Rufus/Alexa offers "add all" or item by item [R06-14].
  - Intent preview, plus a time-limited undo [R06-30]. Output arrives as action cards the user Accepts [R06-31].
  - Inline confirmation is the "visual proof" [R06-32].
  - Confirm success only for significant tasks [R07-33][R08-23]. Celebrate only when it is rare and earned [R08-32].
- **Hero today:**
  - The card rises in while streaming (`W/blocks/assistant_card_list.dart:47`). Confirm is disabled with a "waiting" hint while the reply is live (`W/blocks/assistant_cart_action_footer.dart:52`).
  - While confirming, the `AppButton` swaps its label for a loader (`footer:49-52`).
  - **On success:** the footer swaps pending → done with a plain `switch`, so the height snaps (`footer:39-69`). The border tweens grey → green (`W/blocks/assistant_card_frame.dart:40-41`). The check pops (`W/blocks/assistant_cart_action_done.dart:34`). **Confetti from the centre of the body on every confirm** (`W/chat/assistant_celebration.dart:17-18,30`). `Haptics.success` (`P/pages/assistant_chat_page.dart:123`). The app-bar badge pops from 0 (`W/chat/assistant_cart_button.dart:32,60`).
  - Cancelled or expired cards fade to 60 % and keep an opacity layer for good (`W/blocks/assistant_cart_action_card.dart:29,37-38`).
  - A product-tile add, by contrast, uses `FlyToCart` (`W/blocks/assistant_cart_taps.dart:20-21`).
- **Gap:** routine confetti. Two different "went into the cart" motions on one screen. The height snaps. A permanent saveLayer. Rejecting gives no feedback.
- **Do:**
  - **Arrive:** `EntranceCascadeItem.single` inside the existing `RepaintBoundary`. The lines inside the card do not cascade.
  - **Live → confirmable:** at `message_end`, the Confirm fill tweens over `fast` and the "waiting" hint collapses (`CollapseReveal` `fast`).
  - **Confirm press:** `PressScale` + `AppButton`. The label stays and `BrandedLoader.inline` appears after `loaderDelay` (the CLAUDE.md loader row).
  - **Success**, in this order:
    - (a) The footer swaps pending → done through `SizeFadeSwitcher`, so the height eases over `medium`.
    - (b) The border tints to green over `medium` (colour tween, never a spring, D5).
    - (c) The check `PopScale.onMount` (≤ 24 dp, `snappy`).
    - (d) **`FlyToCart` from up to 3 line thumbnails** to the app-bar cart, `slow`, starting `staggerStep` apart (D16: at most 3 flights).
    - (e) **On land:** the badge `ChangeBump` + `RollingNumber` to the new total (D16, D20).
    - **No confetti** (**approval** §4 #10).
  - **Reject ("Not now"):** the footer swaps to a "Not added" line through `SizeFadeSwitcher` over `medium`. The card's colours cross-fade to the muted palette over `fast`. The muting is baked into the colours: there is no lasting `AnimatedOpacity`, so no layer remains.
  - **Expired:** the same muted look, with no haptic. If it expires while off screen, there is no motion at all.
  - **Confirm failed:** the button returns to its label. An inline error line appears via `CollapseReveal` `medium` under the button, next to the source [R08-24]. Offline → `showFailureSnackBar` (CLAUDE.md §3).
  - **Undo** within `snackDwell` [R06-30][R06-14]: this is a new feature, listed under **approval** §4 #20.
- **Timing:** arrive `medium`. Done swap `medium`. Border `medium`. Check `snappy`. Flights `slow` with 0/30/60 ms starts. Badge bump on the first land and the roll on the last. Reject swap `medium`, colours `fast`.
- **Haptic:**
  - Confirm press → `tap` (commit, D21).
  - Confirmed → `Haptics.cartAdd()` `selection` **on the first flight's land** [R07-31], replacing `success` (**approval** §4 #10).
  - Reject → `tap` (a remove-type commit).
  - Confirm failed → `warning` (`refuse()`).
- **Reduced:** no flights. The badge only tints (D16). The done swap is a `fast` fade and the check appears without a pop.
- **RTL:** flights go from the card to the cart's real position, which is mirrored for free because the app bar is mirrored. The card and its lines align to the start.

##### 2.7 Tool-running indicators

- **2026:**
  - Status text should name the real step, not "Processing…" [R06-10].
  - Stream-of-thought lives in a bounded, collapsible container with per-step states [R06-29], but step-by-step "reasoning" builds unwarranted trust [R06-28]. Show a summary, not the raw chain [R06-26][R06-27].
  - A sparkle does not say what the assistant is doing; pair it with an icon or label [R06-37].
  - Past 10 s, say when it will be done [R06-34].
- **Hero today:** the label in the thinking bubble cross-fades ("Thinking" → tool label → "Taking longer") through an `AnimatedSwitcher` (`W/chat/assistant_thinking_bubble.dart:41,87,94-97`; labels in `W/chat/assistant_tool_labels.dart`). Tools last 0–23 ms, so the label holds the last tool name (`D/entities/assistant_live_turn.dart` `lastToolName`). It is text only.
- **Gap:** tool labels can flicker, and there is no glyph to identify the step.
- **Do:**
  - **`AssistantStepLine`:** a static per-tool glyph (Phase 5, §5) at the start, followed by the label.
  - **Label changes:** they go through `FlipValue` (`medium`). A label stays at least `successHold` 400 ms. If more tools start in the meantime, jump straight to the newest after the hold; there is no queue.
  - **No step list.** The tools take milliseconds, and a list would add false weight [R06-28].
  - **Loops:** the glyph never animates; the dots are the only loop.
  - **At 10 s:** "Taking longer…", with Stop visible.
  - **Screen readers:** the line is not a live region (Hero already announces once, on landing).
- **Timing:** label `FlipValue` `medium`, with a minimum hold of `successHold`. The line appears together with the thinking row after `loaderDelay`.
- **Haptic:** none.
- **Reduced:** the label swap is a `fast` cross-fade (FlipValue's reduced path).
- **RTL:** the glyph sits at the start. `FlipValue` is vertical (D13: its `axis` is dropped because it is not RTL-safe).

##### 2.8 Errors and retry mid-stream

- **2026:**
  - Regenerate is valid in ready/error, and stop is valid in submitted/streaming [R06-06]. Put Retry near the output [R06-12]. Apologise in three parts [R06-30].
  - Put errors next to the source, with redundant cues; animation must never be the only signal [R08-24].
  - Inline messages persist, while toasts fail on a11y [R08-21][R08-22].
  - Negative feedback should be stronger than positive [R01-30][R07-28].
- **Hero today:**
  - **Turn failed or stopped:** the footer rises in (`W/chat/assistant_ended_turn_footer.dart:42-43`, re-read). It carries the message, Retry (last row), Talk to a person and a new-chat option. A failure fires `Haptics.warning` (`page:56`) with no snack (`page:46`).
  - **Retry:** it removes the kept reply and answers the same bubble again (`P/cubit/assistant_chat_cubit.dart:205-212`, re-read).
  - **Refused before storing (offline, 429, 400):** the "Not sent" row snaps in (`W/chat/assistant_unsent_row.dart:25`), and a transport snack is shown via `showHeroSnackBar` rather than `showFailureSnackBar` (`page:44,54,58`; `cubit:338-362`).
  - **Thread load error:** a red `ErrorView`, not `FailureView` (`W/chat/assistant_chat_body.dart:61`).
- **Gap:** when the text is cut off, the caret snaps away. Retry swaps rows with no continuity. The offline path breaks the app's connectivity contract.
- **Do:**
  - **Mid-stream failure:** the partial text **stays** and the caret fades out over `fast`. The footer (icon + message + Retry + Talk to a person) enters with `CollapseReveal` `medium`. The avatar eases to an "oops" mood over `medium` (a painted mood, §5).
  - **Retry:** the footer collapses (`fast` `exit`). The failed reply's content cross-fades to a new thinking row in the **same place** (the one-shell `SizeFadeSwitcher` from §2.2), so there is no new user bubble and no jump.
  - **Stop:** the same footer in its grey form, with no haptic. The send ↔ stop icon keeps its cross-fade.
  - **Unsent row:** `CollapseReveal` `fast` instead of a snap. Offline → `showFailureSnackBar` (at most one `connectivity.action_needs_internet` + a banner nudge).
  - **Thread load error:** `FailureView` (checking → offline), and the app-standard `FadeThroughSwitcher` between screen states (§2.12).
- **Timing:** caret out `fast`. Footer in `medium`, out `fast`. Retry swap: content `fast`, height `medium`.
- **Haptic:** turn failed → `warning`, once per turn (`refuse()`'s 500 ms guard stops repeats). Stop → none (the customer chose it). Retry tap → `tap`.
- **Reduced:** `fast` fades only. Colour and icon carry the error, never motion alone [R08-24].
- **RTL:** the footer is indented at the start (already `EdgeInsetsDirectional`). Nothing moves horizontally.

##### 2.9 Voice recording (hold, lock, cancel, live level, transcript)

- **2026:**
  - ChatGPT moved voice into the thread with a live transcript [R06-23].
  - Gemini shows a waveform in a centred pill [R06-24].
  - Claude uses push-to-talk (hold), and its orb glow pulses while listening; about 5 s of silence auto-sends [R06-25].
  - A mascot's motion can be driven by audio volume [R09-28].
  - Haptics can disturb the microphone [R07-34]. Use haptic patterns by their meaning [R07-26].
  - The WhatsApp hold/lock/slide model has no finding in the digest [INFERENCE].
- **Hero today:**
  - **Hold:** raw pointer down. The mic grows ×1.8 over `fast` `emphasizedDecelerate` (`W/voice/assistant_voice_mic_button.dart:28,152`). The halo appears at full size with no entrance (`mic_button:151`). Its scale is re-tweened on every 70 ms tick (`W/voice/assistant_voice_mic_halo.dart:37-44`; cubit `defaultTick` `P/cubit/assistant_voice_cubit.dart:53`, re-read).
  - **Hold bar:** snaps over the field (`W/composer/assistant_composer_area.dart:44-57`).
  - **Slide to cancel:** follows 50 % of the finger (`W/voice/assistant_voice_slide_hint.dart:27,47-49`).
  - **Lock pill:** rises, and its **chevron bobs forever** while held (`W/voice/assistant_voice_lock_pill.dart:45-51,85-90`).
  - **Locked state:** the panel grows in (`W/voice/assistant_voice_reveal.dart:26`), but the locked controls snap (`W/voice/assistant_voice_locked_controls.dart:20,31`).
  - **Level and status:** the waveform is stepped at 70 ms (`W/voice/assistant_voice_wave_view.dart:24`). A red dot blinks every 1000 ms (`W/voice/assistant_voice_blink_dot.dart:13,41`).
  - **Transcript:** it grows in (`W/voice/assistant_voice_transcript_preview.dart:27`) and dims to 60 % while sending (`W/voice/assistant_voice_transcript_card.dart:48`).
  - **Cancel:** the bin animation takes **1000 ms and covers the text field meanwhile** (`W/voice/assistant_voice_discard.dart:20`; `composer_area:44`).
  - **Haptics:** hold → `success` (medium), lock → `selection`, discard → `warning` (heavy), too short → `selection` (`W/voice/assistant_voice_listener.dart:69,73,96,99`, re-read). While the mic is open there are no spoken announcements, by design (`listener:91-92`, re-read).
- **Gap:** the haptic meanings are wrong (the start "succeeds", and a chosen discard gets the heavy error buzz). The input is blocked for 1 s. Swaps snap. The chevron loops. The halo pops in, and the level visibly steps at 90/120 Hz (unverified).
- **Do:**
  - **Hold start:** fire the haptic **at pointer-down, before the recogniser opens** [R07-34]. The mic grows `holdScale` ×1.8 over `fast` `emphasizedDecelerate` (kept). The halo enters from the mic's size to the first level over `fast`. The field → hold bar swap uses `FadeThroughSwitcher` crossFade mode (`fast`).
  - **Live level:** the data tick stays at `voiceLevelTick` 70 ms. The halo follows its target through **one** controller with `AppSprings.calm`, so it is smooth at any refresh rate and never restarts a tween per tick. The waveform keeps its bars and paints only when new data arrives (verify the stepping on a 120 Hz device, §6). No mascot reacts to the voice: the halo is the only level signal (principle 1).
  - **"On air" dot:** keep the `blinkPeriod` 1000 ms blink. It is a real-state indicator (like a loader), so it is exempt from `ambientBudget`.
  - **Slide to cancel:** direct manipulation, following the finger (kept). Past the threshold, the mic fades and drops into the bin. The bin runs in `slow` 400 ms (was 1000 ms) and **never blocks the field**: the field shows under it and takes input at once (**approval** §4 #13).
  - **Lock:** at the threshold crossing, the padlock closes with `PopSwitcher` (`snappy`). The chevron nudges once (a `floatLoop` preset, one cycle, count 1) when the pill appears, then stays still. The locked controls replace the hold bar with a `FadeThroughSwitcher` crossFade (`fast`).
  - **Transcript:** partial results use `AssistantWordReveal` **local mode, append-only**. Only new trailing words fade in over `fast`. A word the recogniser rewrites is swapped with no fade, so corrections never flicker [INFERENCE]. The card height eases over `medium`. While sending, it dims through a colour tween (`labelGrey`, `fast`) instead of `AnimatedOpacity` (no layer). On send, the card collapses (`medium` `exit`) at the same moment the user bubble enters (§2.4).
  - **Too short:** show the tooltip.
  - **Chat header avatar:** still for the whole recording (§3.2).
- **Timing:**
  - Hold grow `fast`. Halo follows with the `calm` spring. Dot `blinkPeriod`.
  - Swaps `fast`. Lock pop `snappy`. Bin `slow`.
  - Transcript words `fast`, height `medium`. Collapse on send `medium` `exit`.
- **Haptic:**
  - Hold start → `selection` at pointer-down (was `success`).
  - Lock → `selection` at the threshold crossing (kept; a light tick is harmless to speech-to-text [INFERENCE], verify on device).
  - Cancel → `tap` (a remove, D21; was heavy `warning`).
  - Too short → `warning` via `refuse()` (invalid gesture, D21).
  - Sent → `tap` (kept).
  - No other haptic while the mic is open.
- **Reduced:**
  - The mic does not grow and simply changes colour. The halo becomes a static ring whose opacity follows the level.
  - The dot is steady red. There is no bin: the mic fades out over `fast`.
  - Dragging still tracks the finger [R07-05].
- **RTL:**
  - Slide to cancel goes toward the **start** edge (already RTL-aware, `W/voice/assistant_voice_drag.dart:37-59`), and the chevron auto-mirrors. Lock (up) needs no mirroring.
  - The waveform's newest bar enters at the end edge (time follows reading direction) [INFERENCE].

##### 2.10 Feedback thumbs

- **2026:** feedback is voluntary and placed where it does not interrupt, and the control gives "a clear signal that the action had an effect" [R06-12]. Put messages next to the action, not in a toast [R08-21]. Avoid haptics and motion on frequent taps [R07-29].
- **Hero today:** the outlined ↔ filled icon swap uses `PopScale(popKey: selected)`, which pops from 0 **on un-rate too** (`W/chat/assistant_thumb_button.dart:43-50`). The haptic is `selection` (`:45`). Every up/down rating also shows a "thanks" snack (`page:49`). That is three signals for one small action.
- **Gap:** too many channels, a pop on un-rate, and a toast away from the control.
- **Do:**
  - **Rate:** the icon fills with `ChangeBump` (`AppSprings.calm`, D5: calm = thumbs).
  - **Switch sides:** the other thumb cross-fades back over `fast`.
  - **Un-rate:** a `fast` cross-fade with no bump.
  - **Thanks:** replace the snack with an **inline "Thanks" label** next to the thumbs. It fades in over `fast`, stays for `snackDwell`, and fades out over `fast` (**approval** §4 #12). It is a polite live region, so a screen reader hears it once.
- **Timing:** bump `calm` (about 210 ms). Fades `fast`. Label dwell 4 s.
- **Haptic:** `selection` once per tap (rate, switch or un-rate), all selection changes (D21).
- **Reduced:** the icon swaps with a `fast` fade and no bump. The label appears with a `fast` fade.
- **RTL:** the thumbs row sits at the start. There is no directional motion.

##### 2.11 Handoff to a human

- **2026:** escalation to a person is part of good agent UX (5–15 % of sessions escalate, with above 90 % completion) [R06-30]. Confirm significant actions [R06-11]. Inline status persists, and timed toasts should not carry important messages [R08-22]. The status-transition motion of handoffs has no finding in the digest [INFERENCE].
- **Hero today:**
  - The confirmation is a `showHeroDialog` (`W/chat/assistant_handoff_dialog.dart`).
  - On success: `Haptics.success` + a snack (`page:57`), and a banner that **snaps in** at the top, pushing the list down (`W/chat/assistant_chat_body.dart:68`). The banner is `liveRegion: true` (`W/chat/assistant_handoff_banner.dart`, re-read).
  - Conversation closed → the composer **snaps** to the "chat ended" bar (`chat_body:74-77`).
- **Gap:** the banner and the snack say the same thing twice. The layout snaps. The haptic is from the celebration family for a support event.
- **Do:**
  - **Dialog:** kept (D12: fade + 1.1→1, in `medium` `signature`, out `fast` `exit`).
  - **Handed off:**
    - The banner enters with `CollapseReveal` (height `medium` `signature`, content `fast`). The reversed list is pinned to the bottom, so the reader's place holds.
    - The header subtitle `FlipValue`s to the support line.
    - The header avatar eases to a calm "handing over" mood (`medium`) and then stays still.
    - The snack is dropped, because the live-region banner is the inline proof (**approval** §4 #11).
  - **Messages from a person** (when they arrive): they enter like any reply (`EntranceCascadeItem.single`) but **never word-reveal**. A human's text appears whole: word reveal belongs to model output only, so the two are never confused [INFERENCE].
  - **Chat ended:** composer → ended bar through `FadeThroughSwitcher` crossFade (`fast`).
- **Timing:** banner `medium`. Subtitle `medium`. Composer swap `fast`.
- **Haptic:** the dialog's confirm button → `tap` (commit). Handed off → none (was `success`; D21 keeps `success` for orders, Pro, profile, reward and language). A failed handoff → `warning`.
- **Reduced:** the banner appears with a `fast` fade and no height ease.
- **RTL:** the banner's glyph sits at the start. All motion is vertical or a fade.

##### 2.12 The rest of the chat surface (states, route, list chrome, composer hint)

- **Screen states:** today, loading / welcome / thread / error / signed-out / store-off all snap (`W/chat/assistant_chat_body.dart:39-80`).
  - Use `FadeThroughSwitcher` for unrelated states and its crossFade mode (`fast`) for skeleton → thread (D17).
  - Welcome → first message uses a fade-through.
  - Signed-out uses `HeroStateView.signedOut`, as Orders and Checkout do.
  - The "Continue your last chat" tile enters with `CollapseReveal` `medium` instead of pushing the starters down in one frame (`W/welcome/assistant_continue_tile.dart`).
- **Welcome avatar:** today `PopScale.onMount` + alive (`W/welcome/assistant_welcome_hero.dart:39-40`). New: empty-state art pops once from 0.9 (D13), then stays still.
- **Route:** chat = `HeroSlideUpTransitionPage`, in `page` `signature`, out `medium` **`exit`** (D9). Today it pops with the enter curve (`core/navigation/hero_slide_fade_transition.dart:76-80`). Add predictive back / swipe (D11). History = `HeroTransitionPage` shared-axis X (D8), not a second slide-up.
- **Jump to latest:** today it scales from exactly 0 (`W/chat/assistant_jump_to_latest.dart:33-34`). New: fade + scale from `pressedScaleSmall` 0.92 → 1 over `medium` `signature`, with its own `RepaintBoundary`, and no haptic (navigation).
- **Composer hint:** today it rotates every 4 s forever, even while typing, recording, covered or backgrounded (`W/composer/assistant_composer_hint.dart:40-44`). New: `RotatingLine` (D13), dwell `carousel` 3 s, **changing at most once per chat open**, so all motion ends within `ambientBudget`. It stops when the field is focused, has text, the mic is open, the route is covered or the app is hidden (**approval** §4 #15).
- **Character counter:** today it snaps in and pushes the composer up (`W/composer/assistant_composer_bar.dart:65-68`). New: `CollapseReveal` `fast`.
- **Overflow menu:** Material default (`W/chat/assistant_chat_menu.dart:51`). Leave it as a platform control, and check that it respects "Remove animations" (§6).
- **Tour sheet (buddy onboarding):**
  - Large sheet `slow` (D12).
  - The perch drop uses `AppSprings.calm`, replacing the raw 240/0.5.
  - Fix the perch lean flipping sign at every half-swipe: the lean must be continuous across the page boundary (`W/onboarding/assistant_onboarding_perch.dart:146`).
  - Demos play **once per sheet open** and do not replay on swipe-back (`…/assistant_onboarding_timeline.dart:76-88`).
  - The cart demo shows the **`FlyToCart` + badge** the real chat now uses, not confetti (`scenes/assistant_onboarding_cart_scene.dart:69`).
  - The typed demo uses `AssistantWordReveal` local mode.
  - Caption and starters use `EntranceCascade`.

---

#### 3. Buddy motion policy

The buddy is **alive but not childish**. It is still until something happens, reacts once, and goes still again. Every row below is gated by `BuddyMotionGate.mayMove`. The only exception is **direct manipulation**, which always follows the finger.

##### 3.1 When the buddy MAY move

| # | Motion | Trigger | Max frequency | Duration | Loops | Replaces today |
|---|---|---|---|---|---|---|
| 1 | Launcher arrive / leave (slide to the end edge + scale 0.6↔1, `Transform`) | `launcherShown` flips: tab with a launcher, keyboard closed, scrolling up, store on | per flip; flips closer than `page` 300 ms merge into the last state | in `page` `signature`, out `medium` `exit` | 1 | `Positioned` movement with `emphasizedDecelerate` in |
| 2 | Wake blink (20 % chance of a double) | a **wake**: launcher arrives, app resumes, a launcher tab becomes current, or the first touch after ≥ 10 s with no touch | at most 1 per `wakeBlinkGap` 8 s, and only inside the 5 s wake window (`ambientBudget`) | 75 ms × 2 (150 ms; 450 ms when double) | 1 | a blink every 3–7 s for 30 s after every touch |
| 3 | Eyes look toward a touch | pointer-down on the shell outside the launcher; not while a scroll is in progress | at most 1 per 2 s | ease `medium`, hold `lookHold` 1.1 s, ease back `medium` | 1 | every touch |
| 4 | Hop (squash and stretch) | cart qty goes up (on the **last flight's land**), drag landed, greeting closed, tour ended | at most 1 per `hopGap` 30 s, at most 3 per visit; never while `FlyToCart.inFlight` | `AssistantMotion.hop` 720 ms (delight, not functional) | 1 | per event; also on "playful" lines |
| 5 | Wave (sprout) | the visit's greeting line starts | 1 per visit | 900 ms | 1 | every opener line |
| 6 | Wink | a "company" line is shown | at most 1 per line | 420 ms | 1 | kept |
| 7 | Mood ease (idle, talking, happy, curious, thinking, oops) | a state change (line starts or ends, confirm, failure) | per change | `medium` | 1 | 260 ms raw |
| 8 | "Talking" pose | its own line is revealing | per line | a **still** pose held for the reveal (≤ 1.2 s) | 0 | 150 ms mouth-flap loop |
| 9 | Thought bubble: rise → words → read → sink | proactive cadence (§3.4) | greeting + 1 per visit (kept) + at most 1 follow-up ≥ `followUpGap` 90 s later | rise `slow` (circles `snappy`, ≤ 48 dp), words ≤ 1.2 s (§2.3 local), read 1.8 s + 35 ms/letter (kept), sink `medium` `exit` | 0 (no bob, no badge rock, no fake dots) | 8 per visit, 1.1 s fake dots, a `FloatLoop` bob forever, badge rocking |
| 10 | Greeting card drop | nudge policy (kept: ≤ 1/day, 3-day snooze, 7-day back-off) | ≤ 1 per shell | in `page` `signature` from the top; drag-settle `AppSprings.calm`; out `medium` `exit`; message by word reveal | 1 | spring 320/0.72 drop, with the settle not gated |
| 11 | Drag + release | the finger | direct | follows the finger; release `AppSprings.calm` to the nearest side | — | raw spring 420/0.72 |
| 12 | Press squash | tap-down on the launcher | per tap | `pressedScaleSmall` 0.92, in `microPop`, out `fast` | 1 | 0.9, `fast` |

**Haptics on the buddy** (D21: navigation = none, one per gesture):
- Long-press → hide sheet: `selection`.
- Drag start: `selection`.
- Drag landing: none (was `tap`).
- Launcher tap → chat or tour: none (was `tap`).
- Thought tap → chat: none (was `tap`).
- Greeting arrival or dismiss: none. Unsolicited content never vibrates [R07-29][INFERENCE].
- Greeting chip: `selection`.

##### 3.2 When the buddy MUST stay still

"Still" means no blink, look, hop, wave, wink or mood ease, and no new thought or greeting. A thought already on screen **sinks** (`medium` `exit`) unless noted otherwise. Timers are **cancelled**, not paused: a muted ticker still counts time (`ticker.dart:62-64`, per A03).

| Condition | What it covers | Signal the gate reads | On leaving the condition |
|---|---|---|---|
| **User is typing** | shell: keyboard up (the launcher already hides, `P/cubit/assistant_buddy_state.dart:49`); chat: composer focused or has text | `MediaQuery.viewInsets.bottom > 0`; composer focus / controller | a new wake window only after the keyboard closes, plus 2 s |
| **Reading a streaming answer** | the whole chat while `state.isStreaming`, and until 2 s after `message_end` | `AssistantChatState.isStreaming` | mood eases to idle once, and that is all (no "done" wiggle) |
| **Recording** | phases holding / locked / sending | `AssistantVoiceState.phase != idle` | nothing is replayed |
| **Checkout / payment / order placement** | the Cart tab (no launcher, kept: `config/routes/feature_routes/shell_routes.dart:31-32`), checkout, the place-order busy overlay, the Pro paywall, order tracking right after "order placed" | route not the shell (`TickerMode` off + `ModalRoute.isCurrent` false); `CubitBusyOverlay` busy | a thought or greeting cut here is **not** logged as *ignored* and not replayed. The next wake comes only after the shell has been current for ≥ 2 s |
| **Reduced motion** | everything ambient; presence becomes a `fast` fade; the thought appears whole with a `fast` fade; the drag still follows the finger | `MotionGuard.reduced` | — |
| **Screen reader** | no proactive thoughts (kept, `P/cubit/assistant_buddy_scene.dart:48`); the greeting has **no countdown**; no ambient motion; the launcher is a labelled static button | `MediaQuery.accessibleNavigation` (inside `ambientAllowed`) | — |
| **Off screen / covered / backgrounded** | a pushed route, **a sheet or dialog above (non-opaque included)**, a hidden tab, the app not resumed | `TickerMode`, route current, `AppLifecycleState.resumed` | cancel the thought, greeting-countdown, joy and composer-hint timers. On return: a fresh wake window. The greeting countdown **restarts from full** and is never completed by elapsed time |
| **User scrolls or drags content** | ambient motion paused; a running thought sinks `fast` `exit` and counts as said | a `ScrollStartNotification` on the tab | a wake only after 2 s with no scroll (kept rule, `cubit:375`) |
| **Another primary motion** | a `FlyToCart` flight, confetti, a page or sheet transition, the category-shelf glide, a snack entering | `FlyToCart.inFlight`; `ModalRoute.animation` status; the shelf's `AmbientLoop.active` | hold **one** pending reaction (for example the cart hop) and play it when that motion ends; drop the rest |
| **Hidden for today / store off / greeting or tour up** | launcher hidden (kept) | cubit state | kept |

##### 3.3 Chat avatars (inside the assistant chat)

- **Header avatar:** one wake blink ~600 ms after the route settles (once per chat open). After that it only makes state-driven mood eases: thinking → idle, happy on confirmed, oops on failure, handing-over on handoff. It never blinks or glances again (`alive: false`).
- **Welcome avatar:** it pops once (§2.12) and then stays still.
- **Reply avatars:** still (kept). The live reply's avatar keeps its element from thinking → text (§2.2).
- **Hide-sheet and greeting-header mascots:** still (they get the `alive: false` default). Only the greeting header plays the talking pose → happy mood ease once.

##### 3.4 Proactive cadence (thought bubble and greeting)

- **Kept (a user decision, recorded in memory "Jameia assistant buddy"):** a greeting line plus 1 chained line at each visit, and the nudge policy (≤ 1 greeting per day, none on a day the chat was opened, 3-day snooze after a dismiss, 7-day back-off after 2 ignores) (`D/entities/assistant_nudge_policy.dart`).
- **Changed (approval §4 #1–#4):**
  - Follow-ups: today one line 45 s after the last, slowing ×2/×3, up to 8 per visit (`P/cubit/assistant_buddy_cubit.dart:70-83`, re-read). New: **at most 1 follow-up, ≥ 90 s later**, only while Home or Search has been idle for 2 s.
  - A new "visit": today a return after 1 min. New: a return after **30 min**, or a cold start [INFERENCE].
  - The fake 1.1 s "thinking" dots before a line: removed. The bubble rises and the words start at once (no real work is happening) [R06-34].
  - A line in progress **yields** to the user (§3.2) instead of playing to the end (`assistant_buddy_state.dart:53`).
- **Greeting countdown:**
  - The 8 s `greetingShowFor` starts after the message has revealed, and pauses while a finger rests on the card (kept).
  - It is cancelled and restarted off stage, so it no longer closes on return and logs *ignored* (A03 §1 problem 12).
  - The bar is static under reduced motion (A03 §1 problem 6). There is no countdown with a screen reader (WCAG 2.2.1 via [R08-21]).

##### 3.5 Implementation notes (for the builder)

- **`BuddyMotionGate`** is an `InheritedNotifier` above the shell's buddy layer and the chat body. It exposes `mayMove` and `isSensitive`. The mascot's scheduler, the launcher, the thought bubble and the greeting all ask it before starting anything.
- **The wake window uses the `AmbientLoop` engine's budget semantics** (D15): `active` + OnScreen + `ambientBudget`. The mascot keeps its own painter and controllers, which stay allow-listed.
- **Timers:** replace every `Timer` that drives buddy motion with ticker-driven delays (an `Interval` on a controller, like `EntranceCascadeItem`), or cancel it in `didChangeDependencies` when `TickerMode` turns off. No timer runs while the buddy is off stage.
- **Perf:** presence and snap via `Transform.translate` (paint only). A `RepaintBoundary` around the whole layer (system.md §5, P2-H2). The drag updates a `ValueNotifier`, not `setState` on the `LayoutBuilder`.

##### 3.6 AssistantEntrance decision (D14): **MERGE, then retire**

`AssistantEntrance` (`W/chat/assistant_entrance.dart`, re-read) is a one-shot fade + slide + optional scale with a `Timer` delay. It has 10 call sites in 8 files (re-read with grep): `blocks/assistant_card_list.dart:47`, `buddy/assistant_buddy_starters.dart:39,46`, `chat/assistant_ended_turn_footer.dart:42`, `chat/assistant_suggestion_chips.dart:40`, `chat/assistant_user_bubble.dart:55`, `onboarding/assistant_onboarding_caption.dart:39,55`, `onboarding/assistant_onboarding_starters.dart:48`, `welcome/assistant_starter_chips.dart:43`.

- **Chip and caption rows** (6 sites) → `EntranceCascade` + `EntranceCascadeItem` (D17). The rise is vertical, so the horizontal slide-from-start and its RTL flip are gone. The steps become `staggerStep`. The delays become "mount when ready".
- **Single elements** (sent bubble, card, ended-turn footer, the new thinking row) → `EntranceCascadeItem.single(play:)`. It runs on one controller with no `Timer`, so it honours `TickerMode`. The corner scales (0.96 and 0.98) are dropped.
- **Why merge and not keep:** the two primitives do the same job with different numbers. `AssistantEntrance`'s timer ignores `TickerMode`. Its x-offset slide is the only horizontal list entrance in the app.
- **What merging costs:** the sent bubble loses its corner grow, and the chips lose their sideways slide (**approval** §4 #14).
- **Retired / merged count** in D14 becomes **10**.

---

#### 4. Behaviour changes needing approval

| # | Today | Proposed | Why |
|---|---|---|---|
| 1 | Up to 8 proactive lines per visit at a 45 s cadence (`assistant_buddy_cubit.dart:70-83`) | greeting + 1 (kept) + at most 1 follow-up ≥ 90 s later | [R08-08][R06-35]; loops while nobody asked (A03 §1 #1) |
| 2 | A "visit" restarts after 1 min away | after 30 min, or a cold start | fewer re-greets [INFERENCE] |
| 3 | A started line plays to the end through scrolls and taps (`assistant_buddy_state.dart:53`) | it sinks as soon as the user acts | input first (system.md 9.1 #2) |
| 4 | 1.1 s fake "thinking" dots before every proactive line | the text starts right after the rise | dots mean real work [R06-34] |
| 5 | Blink every 3–7 s and glance every 15–25 s for 30 s after each touch; header, welcome, greeting and hide-sheet mascots are alive | one wake blink per 8 s, only inside a 5 s window; no autonomous glance; every mascot defaults to still | [R06-16][R06-17][R07-03] |
| 6 | 150 ms mouth-flap loop while talking or thinking | a still talking pose; a thinking pose | peripheral motion (A03 §1 #8, §2 #2) |
| 7 | Thought cloud bobs forever; badge rocks while thinking | both retired | D19 |
| 8 | Launcher tap, thought tap and drag landing give `tap` haptics | none (navigation); long-press and drag start keep `selection` | D21 |
| 9 | `selection` haptic on every landed answer (`page:78-80`) | none | [R07-29]; D21 |
| 10 | Confetti + `success` on every confirmed proposal | `FlyToCart` ×≤3 + badge bump/roll + `cartAdd` `selection` on land | D16, D21; [R08-32] |
| 11 | Handoff: `success` haptic + snack + banner snaps in | the banner animates in (live region); no snack; no success haptic | [R08-21][R08-22]; D21 |
| 12 | Thumbs: pop both ways + haptic + "thanks" snack | calm bump on rate only; an inline "Thanks" beside the thumbs for 4 s; no snack | [R06-12][R08-21] |
| 13 | Voice: hold `success`, discard `warning`, too-short `selection`; bin 1000 ms blocks the field | hold `selection` at pointer-down; discard `tap`; too-short `warning`; bin 400 ms with the field usable | [R07-26][R07-34]; D2 ceiling; input first |
| 14 | Sent bubble: 30 % rise + corner scale 0.96; chips slide in from the start edge; `AssistantEntrance` | 8 dp rise + fade for all; chips cascade vertically; `AssistantEntrance` retired | D17; §3.6 |
| 15 | Composer hint rotates every 4 s, always | at most one change per chat open (3 s dwell); stops while focused, typing, recording, covered or hidden | D19; [R07-03] |
| 16 | Greeting: spring drop; the countdown can expire under a page and log *ignored*; the bar is animated under reduced motion | tween drop; the countdown restarts off stage and is never logged from elapsed time; a static bar under reduced motion, none with a screen reader | A03 §1 #6, #12; WCAG 2.2.1 |
| 17 | Stream: words pop in 50 ms bursts; caret snaps off | a `fast` fade on new words, trailing ≤ 50 ms (≤ 500 ms on a burst); the caret fades out | [R06-01][R06-02] |
| 18 | Thread load error → red `ErrorView`; offline send → `showHeroSnackBar` | `FailureView` + `showFailureSnackBar` (CLAUDE.md §3 contract) | visible change, although it is a contract fix |
| 19 | Tour: demos replay on every return; confetti demo; 👋 emoji | play once per open; `FlyToCart` demo; the mascot's own wave | A03 §5 |
| 20 | No undo after confirming a proposal | an "Undo" in the done row for `snackDwell` (**needs an API check**: can the confirmed lines be reverted?) | [R06-30][R06-14] |
| 21 | Rejecting a proposal gives no haptic | `tap` | D21 (a remove-type commit) |
| 22 | Chat pop uses the enter curve; no swipe or predictive back | out `medium` `exit`; predictive back (with D11's manifest flag) | D9, D11 |

#### 5. Asset needs (feeds Phase 5)

All assets are SVG through `HeroIcons` / `HeroAssets`, or **painted moods added to `AssistantMascotPainter`**. No Lottie, Rive or GIF (D1; the Rive case from [R09-27] is declined for the same reason).

| # | Need | Where it is used | Today | Format |
|---|---|---|---|---|
| 1 | Per-tool glyph set: search, cart, order truck, offers tag, recipe, FAQ, delivery clock, branch pin | `AssistantStepLine` (§2.7) | text only (`W/chat/assistant_thinking_bubble.dart:55-61`) | 16–20 dp SVG, one stroke weight, `matchTextDirection` for the truck |
| 2 | Thought-topic glyph set: greet, find, deals, choose, ask, fix, home, meals, cart, company | the buddy's thought badge | 14 px Material icons (`W/buddy/assistant_buddy_thought_badge.dart:32,71-80`) | 14–16 dp SVG |
| 3 | Mascot moods: **thinking** (eyes up and to the side), **oops** (failed turn), **handing over** (points to a person) | §2.2, §2.8, §2.11, §3.3 | talking mood reused; Material error icon | painter moods |
| 4 | Handoff illustration + small inline glyph (mascot passing to a person) | handoff dialog, banner, card | `support_agent_rounded` | illustration SVG + 20 dp glyph |
| 5 | Signed-out chat: "sign in to chat" (mascot + lock) | chat and history signed-out states | 56 px Material lock (`W/chat/assistant_chat_body.dart:55-59`; history `body:36-40`) | `HeroStateView.signedOut` art (shared) or a mascot variant |
| 6 | Store switched the assistant off: mascot "resting / back soon" | `chat_body:43-48` | `auto_awesome_outlined` | illustration SVG |
| 7 | Thread can't load / offline | `chat_body:61` | red Material error icon | the shared offline plate + a mascot "can't reach" variant |
| 8 | Empty history: mascot + empty speech bubble | `W/history/assistant_history_body.dart:56` | `forum_outlined` | illustration SVG |
| 9 | History status-chip glyphs (with support, closed) | history rows | none | 12–14 dp SVG |
| 10 | Microphone permission: mascot + mic | `W/voice/assistant_voice_blocked_dialog.dart:53` | `mic_off_rounded` | illustration SVG |
| 11 | "Hold to talk" first-use hint (finger on the mic, arrow up to the lock) | composer tooltip | tooltip text only | small SVG |
| 12 | Tour step 1 hero | onboarding hello scene | 👋 emoji (`W/onboarding/scenes/assistant_onboarding_wave.dart:30,74`) | **no new asset**: use the mascot's painted wave |
| 13 | Tour grocery tiles (cleaner, bulb, coffee) | `scenes/assistant_onboarding_item.dart:11-25` | Material glyphs | 3 small product SVGs |
| 14 | An AI-identity glyph that pairs the sparkle with a label or the mascot (entry points, store-off) | launcher long-press sheet, store-off, Mine row | bare `auto_awesome` | 20 dp SVG [R06-37] |
| 15 | (low) Day-part accent for the greeting (morning / evening) | greeting card | text only | optional, 2 small SVGs |

#### 6. Open issues, to verify on a device

1. **Word-alpha fades must be paint-only.** Confirm in a profile build that only the last block repaints and nothing is re-laid out (`RenderComparison.paint` for colour-only `TextSpan` changes; the caret `WidgetSpan` must stay identical).
2. **Voice stepping at 120 Hz.** Check whether the 70 ms waveform steps are visible. If they are, interpolate the scroll per frame; the data tick stays the same.
3. **Lock haptic and speech-to-text.** Check whether a `selection` tick at lock time shows up in the transcript on the test phone (8970c9c8, MIUI) [R07-34].
4. **Overflow menu.** Check that the `PopupMenuButton` animation respects "Remove animations".
5. **Jump-to-latest from scale 0.** The Impeller crash risk is still only PLAUSIBLE (A03 §2 #10). The new 0.92 start removes it whatever the answer.
6. **Proposal "Undo" (§4 #20)** needs a backend check before design work (`node .claude/skills/hero-api-integration/scripts/openapi_route.js assistant`).


### 9.7 Do / Don't

**Do**
- Use a token from `AppMotion` / `AppSprings` for every duration, curve, scale and shift.
- Route every animation through `MotionGuard`; under reduce, replace movement with a `fast` fade.
- Make exits shorter than entrances, and keep functional motion at 400 ms or less.
- Move things with springs; fade and colour them with tweens that never overshoot.
- Retarget from the current value when a new value arrives mid-animation.
- Gate every loop with the OnScreen gate + `TickerMode` + lifecycle, and bound it with `ambientBudget`.
- Mirror horizontal motion in RTL (`EdgeInsetsDirectional`, `AlignmentDirectional`, a sign from `Directionality`).
- Use `FadeTransition` / `ScaleTransition` / `SlideTransition` and put a `RepaintBoundary` around the moving child.
- Expose state (`justAdded`, `changed`, `done`) from the cubit; decide motion and haptics in the widget or page listener.
- Show text and colour with every animated error.

**Don't**
- Don't write a raw `Duration(…)`, `Curves.*` or `Cubic(…)` for motion in a feature.
- Don't call `HapticFeedback.*` directly, or fire haptics from a cubit.
- Don't scale in from 0, except for dots and badges of 24 dp or less.
- Don't count up from 0 when a screen opens, and don't replay an entrance on scroll-back, filter or sort.
- Don't play a list cascade under a page transition.
- Don't block input for a flourish. Hold only for a submit (busy overlay), and never an "Added ✓" hold (the PDP holds 1200 ms today, A07).
- Don't loop without an "in progress" reason, and don't loop off screen or on a hidden tab.
- Don't use the `Opacity` widget in an animation builder, or animate blur, clip, shadow or padding.
- Don't chain one sheet after another, or put a toast where an inline message belongs.
- Don't slide a drill-down vertically, or slide a top-level swap at all.
- Don't add Lottie, Rive or GIF assets without a cost / benefit case, and don't keep the unused GIF.

### 9.8 Review checklist (per PR)

- [ ] Every duration, curve, scale and shift is an `AppMotion` / `AppSprings` token; there is no raw `Duration`, `Curves` or `Cubic` in motion args.
- [ ] Each animation states its purpose (a code comment or the PR text) and is the only primary motion at that moment.
- [ ] Reduced motion was checked with both switches: Android "Remove animations" gives instant, and iOS Reduce Motion gives a fade substitute that keeps the meaning.
- [ ] The RTL run (Arabic) was checked: horizontal motion mirrors, and directional art uses `matchTextDirection`.
- [ ] Interruption was checked: double-tap, a tap mid-animation, a back press mid-transition, and a new data arrival mid-animation.
- [ ] No loop runs off screen, on a hidden tab, or in the background (DevTools shows no frames when idle); decorative loops stop at `ambientBudget`.
- [ ] Haptics go through `Haptics` intent helpers, follow the §9.5 map, fire one per gesture, and none come from cubits.
- [ ] Nothing blocks input except a submit under `CubitBusyOverlay`, and content never waits for a flourish.
- [ ] The page type matches the §9.3 map (push = shared axis X, modal = slide-up, top-level = fade-through).
- [ ] Perf: transform and opacity only, a `RepaintBoundary` on moving children, no `Opacity` / `saveLayer` per frame, and a profile-mode trace on a mid-range Android device inside the budget.
- [ ] The existing primitive was used, with no new feature-local copy of a core primitive.
- [ ] Any text shown by the motion (hint, banner, snack) comes from i18n keys in both `en.json` and `ar.json`.
- [ ] Tests: the widget test pumps with `disableAnimations: true` and false; new primitives have tests.

### 9.9 Enforceability: `architecture_lints` proposals (not edits)

| Proposed rule | Checks | Scope / allow-list |
|---|---|---|
| `motion_tokens_only` | a `Duration(` literal or a `Curves.` / `Cubic(` / `SpringDescription(` in `duration:`, `reverseDuration:`, `curve:`, `period:` args or `AnimationController(duration:)` | `features/**/presentation`, `core/widgets`; allow `core/motion`, `SplashMotion`; timers that are not motion are excluded by the argument name |
| `no_raw_haptic_feedback` | `HapticFeedback.` anywhere except `core/motion/haptics.dart` | all `lib/` |
| `no_motion_in_cubit` | a cubit or state importing `core/motion/**` | `presentation/cubit/**` (extends `cubit_depends_on_usecases`) |
| `feature_controller_allowlist` | `AnimationController(`, `createTicker`, a motion `Timer.periodic` in feature widgets | allow-list file (assistant mascot, splash) |
| `no_opacity_in_animation_builder` | an `Opacity(` inside a `builder:` of `AnimatedBuilder` / `TweenAnimationBuilder` / `ValueListenableBuilder` | all presentation |
| `repeat_needs_gate` | a `.repeat(` without `count:` in a file with no `MotionGuard` / `TickerMode` reference | all `lib/` |
| `motion_guard_required` | a file with `AnimationController(` or an implicit `Animated*(`, and no `MotionGuard` reference | all `lib/` (54/57 already pass, C2 table B) |
| `no_raw_animated_switcher` | `AnimatedSwitcher(` / `AnimatedSize(` in features (use PopSwitcher / SizeFadeSwitcher / CollapseReveal) | features (20 + 10 today, C1 E3) |
| `scroll_animate_via_guard` | `.animateTo(` on a `ScrollController` / `ScrollPosition` outside `MotionGuard.scrollTo` | all presentation |
| `motion_barrel_imports` | features import motion only via `motion.dart` / `motion_widgets.dart` / `haptics.dart`, and navigation only via `navigation.dart` | features (C1 #18) |
| `page_type_allowlist` | `pageBuilder:` returns one of the 4 Hero page types | `config/routes/**` (extends `GoRoute(builder:)` rule) |

Not checkable by lint (review only): purpose, one primary motion per moment, scale from 0, the haptic kind mapping, replays on scroll-back, and the 5 s ambient budget at runtime.


### 9.10 Decision summary

1. No parallel system: extend `AppMotion` / `MotionGuard` / `Haptics`; `motion.dart` re-exports `AppSprings`. No new packages (no Lottie / Rive / animations pkg); the unused 2.29 MB GIF is removed.
2. Duration scale: microPop 100 (press-in) · fast 150 (fades, press-out, exits) · medium 250 (component change, value roll, dialog in, sheet / modal out) · page 300 (pages, sheet in) · slow 400 (flight, large sheet, earned count-up; ceiling for functional motion).
3. Other kept durations: staggerStep 30 · loaderDelay 150 · busyMinVisible 500 · breathe 600 · drawOn 700 · shimmer 1100 · loaderOrbit 1200 · confetti 1400 · carousel 3000 · floatLoop 3200 · sheen 3600.
4. New: successHold 400 (moved from AppSprings) · blinkPeriod 1000 · snackDwell 4000 · ambientBudget 5000 · pressedScale 0.97 · pressedScaleSmall 0.92 · slideShift 30 dp · entranceRise 8 dp · staggerMaxItems 6 · linear.
5. Curves: signature (0,0,.2,1) enter · exit (.4,0,1,1) · emphasizedDecelerate (.1,.7,.1,1) big reveals · machEaseInOut (.42,0,.58,1) A→B while visible · linear loops. Springs: AppSprings.snappy ζ.6 k800 (small pops, ≤48 dp) · AppSprings.calm ζ.9 k700 (thumbs, digits, settles). Opacity and colour never use a spring.
6. Retired tokens (16): standard, decelerate, emphasized→snappy, popup, imageFade→fast, sheetLarge→slow, flip→medium, countUp→slow, glowPulse, shineSweep→sheen, popScaleBegin/End, pageSlideBegin/End, AppConstants.heroAutoAdvance/searchHintRotate. Splash tokens move to feature-local SplashMotion.
7. MotionGuard: reduced = disableAnimations OR iOS reduceMotion; off = disableAnimations only (instant). reduced && !off = REPLACE (fast fade, loops stop, loaders breathe). New: ambientAllowed(), scrollTo().
8. Page map: forward push = HeroTransitionPage, re-done as shared axis X (30 dp + fade, page 300, mirrored in RTL); HeroSharedAxisPage merges into it.
9. Page map: modal (PDP, image viewer, assistant chat, search from pill, cart preview, Pro paywall) = HeroSlideUpTransitionPage (in page / signature, out medium / exit).
10. Page map: top-level go (splash→shell, sign-in→shell, sign-out / expiry→login, order placed→tracking) = HeroFadeThroughPage (0.92 settle); login→OTP = HeroCrossFadePage (backdrop).
11. Tabs: incoming tab fades fast; hidden tabs under TickerMode(false); no haptic. Predictive back + iOS swipe on all page types (manifest flag needs approval).
12. Sheets: in page (large slow), out medium / exit, one sheet at a time. Dialog: fade + 1.1→1, in medium / signature, out fast / exit. Snack: floating, in medium, out fast, dwell 4 s, a replacement cross-fades.
13. Kept primitives: PressScale (haptic default → none), PopScale (onMount only for ≤24 dp dots / badges), PopSwitcher, ChangeBump, ShakeX / BlockedTapShake, TintFlash, FlipValue (labels / time), RollingNumber (all money + qty), CountUpText (earned amounts only), EntranceCascade (the one list entrance), ScrollReveal, ListItemTransition, FadeThroughSwitcher (+ crossFade mode), SizeFadeSwitcher, CollapseReveal, FloatLoop / IdleLoop (AmbientLoop presets), RotatingLine, SecondClock, Confetti*, FlyToCart, LocaleSwapVeil, LightSweep + ReadyWipe (move into core/motion).
14. Retired / merged primitives (9): StaggerEntrance→EntranceCascade, GlowPulse→FloatLoop preset, AnimatedAccordion→CollapseReveal, HeroSharedAxisPage→HeroTransitionPage, HomeLoop→AmbientLoop, HomePressable→PressScale, HomeReveal*→EntranceCascade + OnScreen gate, ListingReveal*→EntranceCascade, LedgerRowEntrance→EntranceCascadeItem. AssistantEntrance: Assistant spec decides.
15. New: AmbientLoop engine, OnScreen gate (PlayWhenOnScreen), CountBadge (core/widgets), AnimatedProgressBar (core/widgets), CatalogCartGestures.add/remove, Haptics intent helpers.
16. Add-to-cart: in-place PopSwitcher (snappy) → FlyToCart (slow) → badge ChangeBump + roll ON LAND; at most 3 flights; reduced = badge tint only.
17. Lists: cascade on first load only, 30 ms × max 6, fade + 8 dp, medium; never on scroll-back, filter, sort or under a route transition. Skeleton→content = fast cross-fade.
18. Loaders: 150 ms delay always (also reduced); scale 0.9→1 calm; skeleton only for known structure with no device copy.
19. Loops: only real progress loops forever; decorative stop at ambientBudget 5 s, off screen, hidden tab, background, reduced, screen reader. At most one LightSweep per screen, ≤2 passes.
20. Numbers: roll with direction from the delta, medium; never count up from 0 on open.
21. Haptics: selection = add / + / pick / PTR armed; tap = commit press / remove / −; success = order placed, first add (Home), Pro, profile saved, reward, language; warning = refusal, invalid, needs-internet, destructive confirm; none = navigation, tabs, loaders, snacks, value changes. Only via Haptics, never in cubits, one per gesture.
22. Press: 0.97 (icons 0.92), in 100 / out 150 signature; no stacked presses.
23. Findings, not silent changes: category shelf wash / glide needs rest + pause (WCAG 2.2.2); splash should overlap the Home load; the buddy → Assistant spec. "No basket bar on Home when cart has items" stays.
24. Behaviour changes needing approval: horizontal push, tab fade, PressScale haptic off, sheetLarge 500→400, countUp 700→400, imageFade 500→150, emphasized→spring, reduced-motion loader breathe, ambient budget on the shelf, splash skip, Haptics mute toggle, manifest predictive-back flag.
25. AI assistant motion → see Assistant spec (§9.6 (AI assistant motion spec)).


---

## Appendix A. Full per-screen audit (all 44 pages + shared surfaces)


Source: Appendix A (account ×8), Appendix A
(splash, main shell, login, OTP verify, address list, address edit), Appendix A
(buddy layer, chat, history, tour). One block per screen, all audit-cited `file:line`s and all
numbered problems kept. Tokens/primitives per §9 (decision summary) (`D#` = that file's numbered
item, same convention as §9.6 (AI assistant motion spec)). Evidence IDs (`Rxx-yy`) from research_log_2026.md.
Assistant screens: §9.6 (AI assistant motion spec) is the design of record — Opportunity here points at its
`§`/approval-item numbers rather than re-deriving.

---

### 1. Mine (tab) — `lib/src/features/account/presentation/pages/mine_page.dart`
- **Entry/exit:** IndexedStack tab 4, hard cut on switch (`main_shell_page.dart:62-75`); body builds once on first visibility so the cascade plays once (`Visibility.of`, `mine_body.dart:21-29`); IndexedStack keyed by language — a locale switch rebuilds the tab from scratch, new `AccountCubit`, scroll lost (`main_shell_page.dart:59-64`); standalone route = `HeroTransitionPage` (`shell_routes.dart:96-103`); assistant buddy launcher floats over the tab (`shell_routes.dart:29-39`).
- **Motion:** #1 header bg gradient lerp+shadow fade+ring fade on scroll, `Interval(0.8,1)` (`mine_header_background.dart:16,25-34`); #2 avatar docks+scales 1→0.5 first 60%, edit badge scale→0 (`mine_header.dart:34,92-99`; `mine_docking_avatar.dart:26-37`; `mine_avatar.dart:106-113`); #3 name/phone ink-alpha fade, compact title fades in last 30% (`mine_header.dart:35-36,61-90`; `mine_header_details.dart:37-43`; `mine_header_compact_title.dart:33`); #4 first-open cascade `StaggerEntrance` medium/signature raw 30ms step (`stagger_entrance.dart:20-21,37-44`; `mine_content.dart:41-49`; `mine_menu_group.dart:139-161`); #5 wallet stat `RollingNumber` flip280 (`mine_wallet_stat.dart:32-37`); #6 points `CountUpText` 700ms emphasizedDecelerate, change only, not on open (`mine_points_stat.dart:32-37`); #7 coupons/favourites `FlipValue` (`mine_count_stat.dart:40-44`); #8 stat tile `PressScale` 0.97, `haptic: null` (`mine_stat_tile.dart:23,42-45`); #9 invite banner `PressScale` 0.98 + `LightSweep` sheen3600/sweep1440/rest2160, gated `Visibility.of` (`mine_invite_banner.dart:24,40-46`; `light_sweep.dart:21-22,57-58,64-70`); #10 PRO pill sweep only at `opacity==1` (`mine_pro_badge.dart:25-27`); #11 unread badge pop .85→1 snappy, 0↔N no transition (`mine_unread_badge.dart:27-47`; `mine_menu_cell.dart:71-74`); #12 Pro chip `PopSwitcher`, first appearance static (`mine_pro_status_chip.dart:64-66`); #13 scan `PressScale` 0.9 / menu NoSplash highlight / header `GestureDetector` no feedback (`mine_scan_action.dart:18,23-27`; `mine_menu_cell.dart:47-50`; `mine_header.dart:52-55`).
- **State-change:** nothing paints until `AccountState.isResolved`, no loader/skeleton (`mine_content.dart:18-20,29-32`); error = zero counts, silent (`account_cubit.dart:80-81`); guest↔signed-in swaps the header delegate, `maxExtent` snaps, no size/cross-fade (`mine_header_sliver.dart:20-35`; `mine_header_metrics.dart:62-71`); assistant row/Pro chip insert with no transition when their cubits answer (`mine_menu.dart:40-42`; `mine_menu_group.dart:111-117`).
- **Gestures:** vertical scroll drives the collapse; no pull-to-refresh (`mine_content.dart:33`); no long-press/swipe; header tap → profile/login.
- **Haptics:** none; stat tiles + invite banner pass `haptic: null` (`mine_stat_tile.dart:44`; `mine_invite_banner.dart:42`); menu rows silent by design (`mine_menu_cell.dart:14-15`); only the scan `IconButton` + menu `InkWell`s get `Feedback.forTap`.
- **Problems:** P1 header/sign-in pill look tappable, no press state or haptic (`mine_header.dart:52-55`; `mine_sign_in_pill.dart:9-11`); P2 invite sweep loops to an unbuilt placeholder route, same for the Favourites stat (`mine_invite_banner.dart:43-46`; `placeholder_routes.dart:11-17`); P3 press dips inconsistent 0.9/0.97/0.98/highlight-only/none on one screen; P4 3 disagreeing number primitives in one stats row; P5 blank tab then cascade on first visit (`account_repository_impl.dart:25`); P6 header height snap guest↔signed-in; P7 language switch replays the cascade from 0 under a muted ticker whose clock starts on its first unmuted tick (`stagger_entrance.dart:63-64`); P8 core `StaggerEntrance` default step is raw 30ms, not `AppMotion.staggerStep`; P9 unread badge 0→N/N→0 has no transition; P10 assistant row/first Pro chip arrive with no transition.
- **Perf risk:** header subtree rebuilds every scroll frame (gradient+`BoxShadow`+2 `ClipRect`s+`Transform`-scaled avatar shadow re-rastered, `mine_header_delegate.dart:23-32`; `mine_header_background.dart:35-48`; `mine_avatar.dart:67`; `mine_docking_avatar.dart:33-37`); `titleFor`/`.tr()` + avatar initial recomputed twice per scroll frame; invite sweep ticks 1.44s/3.6s while the tab is visible (gated `Visibility.of`+`TickerMode`, not scroll position); 6 `StaggerEntrance` controllers+Timers on first open, cheap.
- **Opportunity:** unify wallet/points/coupon motion on one `RollingNumber`-family primitive, never count-up on open (D13, D20 — points already complies); replace `StaggerEntrance` with `EntranceCascade` capped at 6, tokenised step (D4, D14, D17); gate invite+PRO `LightSweep` with `ambientBudget`+`OnScreen` (D14, D19; R06-35, R07-03 stop/pause past 5s; R08-09 "if eyes are drawn to it, it's too much"); give the header tap + sign-in pill a `PressScale` (D22; R08-02 pressed state must appear within 100-150ms); `loaderDelay` before the blank first frame (D18; R08-12 show-delay+minimum-visible anti-flicker); badge gets an enter/exit via `ChangeBump` (D13) instead of a cut.
- **Assets:** guest header is a grey Material person glyph (`mine_avatar.dart:85-91`) — needs a sign-in illustration; scan glyph is a QR-scan PNG on a delivery-code button, mismatched (`mine_scan_action.dart:12-14,27,35`) — needs a delivery-code glyph matching `HeroIcons.confirmReceipt`; no brand glyph set for wallet/points/coupon/Pro/gift/settings menu icons (Material only; checkout already ships `checkout_wallet.svg`/`checkout_points.svg` unused here, `hero_assets.dart:43-45`); assistant row uses bare `auto_awesome` — needs a mini mascot glyph.

---

### 2. Wallet — `lib/src/features/account/presentation/pages/wallet_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:47-54`) + `LedgerAppBar` title `ScrollReveal` playing under the 300ms slide.
- **Motion:** #1 body switch skeleton/sign-in/error/list via `FadeThroughSwitcher` (`ledger_body.dart:58-66`); #2 skeleton shimmer 1100ms (`skeletonized.dart:19-28`; `ledger_skeleton.dart:27`); #3 first-load cascade of day titles+rows, one controller + `Interval`s, lead `microPop`100+step `fast~/5`30+each `slow`400, 710ms total (`ledger_list.dart:59-83`; `ledger_row_entrance.dart:12,21-29`); #4 new lines flash green→clear on `changeSerial` bump, `slow*2.5`=1000ms `exit` (`ledger_list.dart:66-67,85-92,135-143`; `ledger_fresh_flash.dart:17-23`); #5 balance timeline on `changeSerial`: delta chip enter `slow`/hold `page*5`=1500ms/exit `fast`, digits roll `microPop` after, `Haptics.success` (`wallet_balance_card.dart:28-33,64-120`; `wallet_delta_chip.dart:37-44`); #6 balance digits `RollingNumber` (`wallet_balance_amount.dart:50-58`); #7 pinned day titles (`ledger_day_sliver.dart:38-45`); #8 `BrandedRefresh` pull disc, `loaderOrbit`1200 (`branded_refresh.dart:56-73`; `refresh_disc_header.dart:48-57,103-136`); #9 load-more `FadeThroughSwitcher` (`ledger_load_more_row.dart:38-45`); #10 retry pill `PressScale`0.96+`tap` (`ledger_retry_pill.dart:23`); #11 empty/sign-in icon `PopScale.onMount` (`empty_state_view.dart:33-39`); #12 stale pill fades in (`stale_age_pill.dart:59-66`); #13 failure snack via `ScreenFailureListener` (`wallet_page.dart:29-32`; `screen_failure_listener.dart:35-44`).
- **State-change:** loading→loaded: skeleton fades through **while** rows cascade, two entrance systems nested (`ledger_body.dart:58`; `ledger_list.dart:113-119`); empty = `EmptyStateView` under the balance card (`ledger_list.dart:171-172`); error w/ nothing saved = `FailureView` checking→offline/`ErrorView` (`failure_view.dart:36-49`; `hero_state_view.dart:124-129`); signed-out = lock pop + green button (`ledger_body.dart:69-74`); stale/offline w/ data = pill height inserted with no size transition, list jumps (`stale_data_notice.dart:29-35`); reconnect = `ReconnectRefresh` → chip timeline+flash if moved (`ledger_body.dart:52-53`; `ledger_cubit.dart:49-62`); open with a saved copy: a server answer that differs ticks `changeSerial`, so chip+roll+success haptic+flash can all play on a plain open, not only pull-to-refresh (`ledger_cubit.dart:51-62`); next-page failure offline hard-swaps the slot via `LoadMoreOfflineNote`, bypassing the switcher (`next_page_sentinel.dart:53-57`).
- **Gestures:** pull-to-refresh (`ledger_list.dart:161-162`), scroll w/ pinned headers, back. Rows not tappable, no swipe.
- **Haptics:** `selection` on refresh arm (`branded_refresh.dart:63`); `success` on the balance roll, also under reduced motion (`wallet_balance_card.dart:17-18,119`); `tap` on retry + sign-in button (`app_button.dart:59`).
- **Problems:** P1 route+fade-through+row cascade can land together during the 300ms page slide; P2 stale notice pushes the list with no size transition (`stale_data_notice.dart:29-35`); P3 success haptic fires on a balance **drop** too, no sign check (`wallet_balance_card.dart:115-120`); P4 signed-out here (lock+green) vs. Rewards (red error+"Retry", `rewards_body.dart:27-29`); P5 header doesn't cascade here vs. Rewards `ScrollReveal` (`rewards_balance_header.dart:29`); P6 raw-value durations `page*5`/`slow*2.5`/`fast~/5` (`wallet_balance_card.dart:32`; `ledger_list.dart:60,66`); P7 weak empty state, 56dp grey icon (`wallet_page.dart:37`); P8 chip+roll+haptic+flash can all fire on a plain open; P9 offline load-more note hard-swaps the footer.
- **Perf risk:** `LedgerBody`'s `BlocBuilder` rebuilds the switcher on each ledger change, entrance not replayed (`ledger_body.dart:55-57`; `ledger_list.dart:113-114`); 8 `FadeTransition` opacity layers for ~710ms once, each rebuilding a `Transform.translate` per frame (`ledger_row_entrance.dart:23-28`); flash repaints a `ColoredBox` behind a `RepaintBoundary` row for 1s; skeleton shimmer full-list shader sweep while loading; balance card gradient+`BoxShadow` blur24 static, chip in its own `RepaintBoundary`, `_maybeRoll` listener ticks the whole ~2.05s timeline but `setState`s once (`wallet_balance_card.dart:116-120`); refresh disc loops only while refreshing.
- **Opportunity:** nest the row cascade inside the `FadeThroughSwitcher`'s settle instead of two systems at once (D17); fix the success-haptic sign check — a value going down should never fire `success` (D21; R07-26 "don't use a [positive] pattern to mean [a negative outcome]"); size-transition the stale pill's height instead of an instant push (R10-22 avoid animating layout properties, prefer a size tween); tokenise `page*5`/`slow*2.5`/`fast~/5` onto the D2/D3 duration ladder; unify signed-out/first-load-error treatment with Loyalty/Rewards/Profile under one `HeroStateView.signedOut`+`FailureView` contract (CLAUDE.md §3.2).
- **Assets:** no empty-wallet illustration in the `EmptyStateView` slot (`ledger_list.dart:171-172`); signed-out is only a lock glyph; brand wallet glyph exists (`checkout_wallet.svg`, `hero_assets.dart:43`) but unused here; no transaction-kind glyph set (Material only, `wallet_entry_label.dart:16-23`); shared offline/error plates are Material icons (`hero_state_view.dart:66`).

---

### 3. Loyalty points — `lib/src/features/account/presentation/pages/loyalty_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:55-62`) + `LedgerAppBar` title `ScrollReveal`.
- **Motion:** shares `LedgerBody`/`LedgerList` w/ Wallet (fade-through switch, shimmer, row cascade, fresh-line flash, pinned titles, `BrandedRefresh`, load-more switcher, retry dip, empty/sign-in pop, stale pill, failure snack). Differences: L1 balance card is **static text**, no count, no roll, no delta chip (`ledger_balance_card.dart:10-11,97-105`); L2 "Redeem your points" tile `PressScale`0.96+`tap` (`loyalty_rewards_entry.dart:51-52`); L3 shine always on, no visibility gate, period `sheen*2`=7200ms/sweep2000/α0.8 (`loyalty_rewards_entry.dart:31-37,63-67`); L4 gift badge `FloatLoop` 3dp — `repeat(reverse:true)` makes one leg take the whole `floatLoop`3200, 6.4s up-and-back not the documented 3.2s (`rewards_gift_badge.dart:14,24-26`; `float_loop.dart:39-41,53-55`).
- **State-change:** as Wallet for loading/empty/error/signed-out/stale/reconnect; the programme (`LoyaltyProgramCubit`, memoised `GET /v1/init` per run) inserts the rewards tile+rules card into the header with **no transition** on its first arrival, everything below jumps (`loyalty_header.dart:23-24,48-51`; `loyalty_program_cubit.dart:21-27`), silent on failure; a refresh that moves points flashes new lines but the balance text just changes (only `WalletBalanceCard` listens to `changeSerial`).
- **Gestures:** as Wallet (pull-to-refresh, scroll, back).
- **Haptics:** refresh arm `selection`, tile `tap`, retry `tap`; **no haptic when points change** (Wallet has `success`).
- **Problems:** P1 balance motion inconsistent across the app for the same points value: static here, delta+roll+haptic on Wallet, count-up-from-0 on Rewards, count-up-on-change-only on Mine; P2 header grows with no transition when the programme arrives; P3 two ambient loops on one tile, never visibility-gated, keep ticking scrolled away (Mine gates its sweep with `Visibility.of`, this one does not); P4 shine period/α mismatched with Mine's invite banner (7.2s/α0.8 vs 3.6s/α0.28); P5 weak empty state, `stars_outlined` (`loyalty_page.dart:44`); P6 core token drift: `FloatLoop` doubles its documented period (`float_loop.dart:35-38,55`), `GlowPulse` gets it right.
- **Perf risk:** two forever tickers for as long as the page is open, both run offscreen once scrolled (float in `RepaintBoundary`, sweep via `ClipRRect` band 2s/7.2s); header `BlocBuilder` rebuilds card+tile+rules once when the programme lands.
- **Opportunity:** pick one balance-change primitive for money-like values app-wide (`RollingNumber`, D13) and apply it here too, not a static text; gate both loops with `ambientBudget`+`OnScreen`, cap at one `LightSweep`/screen ≤2 passes (D14, D19; R06-35, R07-03, R08-09); fix `FloatLoop`'s doubled period at the core level (affects every consumer, not just this screen).
- **Assets:** no points-empty illustration for a new member; brand points glyph exists (`checkout_points.svg`, `hero_assets.dart:45`) unused; "how it works" rule glyphs are generic Material; bonus moments have Material-only glyphs (welcome=`celebration_outlined`, profile=`person_outline_rounded`, `loyalty_entry_label.dart:22-23`); sign-in illustration shared with Wallet.

---

### 4. Loyalty rewards — `lib/src/features/account/presentation/pages/loyalty_rewards_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:63-70`) + `RewardsAppBar` title `ScrollReveal`.
- **Motion:** #1 loader→content is a **hard switch**, plain `switch` (`rewards_body.dart:20-40`); #2 loader disc, `loaderDelay`150+`slow`400+`loaderOrbit`1200 loop (`app_loader.dart:29-33`; `delayed_loader_disc.dart:21-32`); #3 balance header `ScrollReveal`, `slow`400 (`rewards_balance_header.dart:29`); #4 balance **counts up from 0 on every open** (from old value on refresh), `countUp`700ms (`rewards_balance_card.dart:103-116`); #5 star `GlowPulse` forever, opacity .45→.75/scale1→1.08, `glowPulse`5000 (`rewards_star_badge.dart:24`; `glow_pulse.dart:37-55,83-90`); #6 progress bars fill empty→value, `slow`400 (`reward_progress_bar.dart:60-69`); #7 section titles `ScrollReveal` (`rewards_section_title.dart:24`); #8 reward cards `ScrollReveal(delay)` raw 70ms×index, max5 (`reward_card.dart:56-59,104-108`); #9 "KD x off" pill `PopScale.onMount` keyed to mount, so a below-fold card's pop can run unseen (`reward_card_art.dart:65-66,96-104`); #10 faded gift `FloatLoop` 4dp on up to 4 ready cards forever (`reward_card_backdrop.dart:27,70-72`; `reward_card_art.dart:87`; `rewards_grid.dart:33-34`); #11 card `PressScale`0.96+`tap`, ready cards only (`reward_card.dart:112-114`); #12 applying overlay: veil+continuous `LightSweep`(sweepShare1)+inline dots (`reward_card_art.dart:107-113`; `reward_applying_overlay.dart:22-29`); #13 "Applied" chip `PopScale.onMount` **also on every open** when the tier's already on the basket, green ring snaps (`reward_card_footer.dart:63-66`; `reward_card_art.dart:71-73`); #14 confetti 48 pieces on **every** confirm (`rewards_content.dart:53-59`; `confetti_burst.dart:45-48,68-75`); #15 history link `PressScale`+`tap`; #16 `BrandedRefresh`; #17 empty/error icon pop; #18 snacks (redeem result via `showHeroSnackBar`, refresh failure via `showFailureSnackBar`).
- **State-change:** loading→loaded is a hard cut then ~0.75s of entrance motion fires at once (header reveal400+countUp700+bar fills400+card cascade to 350+400+pill pops); empty=`EmptyStateView` `card_giftcard_outlined`; error=`ErrorView` directly, **no `FailureView`**, no offline contract (`rewards_body.dart:30-33`, CLAUDE.md §3.2 violation); signed-out=`SignedOutView`→`ErrorView`, red icon+"Retry" to login; stale/offline w/ data = **none**, no `DataFreshness`, no `ReconnectRefresh`, no stale notice; success (redeem)=haptic+confetti+snack+chip+ring all at once; blocked=empty-cart redeem gets the ordinary `tap` haptic + a snack, no blocked cue; locked card tap = nothing.
- **Gestures:** pull-to-refresh, card tap, scroll, back; no long-press.
- **Haptics:** `tap` on card press + `success` once applied; refresh arm `selection`; history link `tap`; **no `warning`** on a failed or blocked redeem.
- **Problems:** P1 most motion-dense screen in the group — a forever `GlowPulse` + up to 4 forever `FloatLoop`s (`maxFloating=4` doesn't count the glow) plus count-up/reveals/pops/bar-fills every open; P2 breaks the app's own "never count up on open" rule (`rolling_number.dart:7-8`; deliberate via `CountUpText.from`); P3 hard cut loader→content vs. Wallet/Loyalty/Profile's `FadeThroughSwitcher`; P4 wrong signed-out UI (red error+"Retry" instead of `HeroStateView.signedOut`, used by checkout/orders); P5 offline contract missing entirely; P6 locked card gives no feedback, `BlockedTapShake` unused here though cart/order-review use it; P7 applied ring snaps while the chip pops; P8 raw 70ms cascade step vs. `AppMotion.staggerStep`30; P9 confetti+haptic+snack+chip for a routine discount apply; P10 pill pop keyed to mount, card reveal to scroll-in — desynced choreography; P11 failed redeem uses `showHeroSnackBar` not `showFailureSnackBar(action:true)`, breaks the offline contract; P12 "Applied" chip re-pops on every open.
- **Perf risk:** `GlowPulse` rebuilds `Opacity`+`Transform.scale` every tick forever (`glow_pulse.dart:78-92`), runs offscreen once scrolled; up to 5 forever tickers mean no idle frame while the page is open (battery); `CountUpText` calls `.tr(namedArgs)` every frame for 700ms (`rewards_balance_card.dart:103-109`; `count_up_text.dart:58-69`); each float repaints inside a `ClipRRect` under a `BoxShadow`; an applying card runs sweep+dots together.
- **Opportunity:** drop count-up-from-0 on open, apply D20 directly (R08-27 favours a quick delta-roll over a spectacle for ordinary opens); cap the loop budget including the glow, gate all with `ambientBudget`+`OnScreen` (D14, D19; R06-35, R07-03); swap the hard switch for `FadeThroughSwitcher` (D17); adopt `HeroStateView.signedOut`+`FailureView`+`DataFreshness` (CLAUDE.md §3.2, matches Wallet/Loyalty); confetti only for a rare/earned moment, not every routine redeem (D16 kept-primitives list still has `Confetti*`, but R08-32 "celebration is earned when rare... make it skippable" — replace with border-tween+check+badge bump, same shape as the assistant's proposal-confirm fix in §9.6 (AI assistant motion spec) §2.6); reuse `BlockedTapShake` on a locked-card tap (D13); fix the failed-redeem snack to `showFailureSnackBar(action:true)` (CLAUDE.md §3).
- **Assets:** all tiers share one faded `card_giftcard` at 96dp — needs per-tier art; locked-tier art is a white veil+lock; no "programme unavailable" empty illustration; sign-in is a red error icon; brand points/star glyph (`checkout_points.svg`) unused; balance hero art is a plain star disc.

---

### 5. Settings — `lib/src/features/account/presentation/pages/mine_settings_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:23-30`) + `SettingsAppBar` title `ScrollReveal`; log-out leaves via `context.go(Routes.login)` (`settings_logout_tile.dart:39`), the login route's own transition.
- **Motion:** #1 3 groups `StaggerEntrance` 0-2 (`settings_body.dart:43-91`); #2 language `HeroSegmentedControl` thumb `AnimatedPositionedDirectional`+`AppSprings.calm`(~210ms), segment fade+ripple (`hero_segmented_control.dart:90-99`; `hero_segment.dart:40,56,68-80`); #3 `LocaleSwapVeil` fades in `fast`150 **linearly**→commit→`endOfFrame`→fades out `medium`250 (`settings_language_tile.dart:44-61`; `locale_swap_veil.dart:22-26`; `locale_swap_veil_view.dart:28-57,67-71`); #4 notifications `Switch.adaptive`, framework-owned, **not via `MotionGuard`** (`settings_switch.dart:30-39`); #5 clear-cache `FadeThroughSwitcher`+`BrandedDotLoader`24dp (`settings_clear_cache_tile.dart:30-35`); #6 row ripple (`settings_tile.dart:52-53`); #7 log-out dialog fade(**linear**)+scale1.1→1.0(decelerate) (`navigation.dart:50-81`); #8 log-out `CubitBusyOverlay`, ≥500ms, blocks taps+back (`mine_settings_page.dart:38-40`; `busy_overlay.dart:58-72,108-128,143-146`); #9 log-out card appears/disappears via plain `if`→`SizedBox.shrink` (`settings_logout_tile.dart:53-54`); #10 floating snack on cache-cleared/failure (`settings_feedback_listener.dart:19-31`).
- **State-change:** notifications write fails → switch animates back + snack (`setting_cubit.dart:64-68`); clearing→done → dots fade out + snack, row unchanged; language success → `Haptics.success`, whole app re-labels under the veil, all shell tabs rebuilt (`main_shell_page.dart:59-64`); signing out → busy overlay → `go(login)`, signed-out → log-out card gone with no transition.
- **Gestures:** scroll, row taps, switch drag (framework), dialog barrier tap, back blocked while busy.
- **Haptics:** `selection`→`success` on language change (`hero_segmented_control.dart:119`; `setting_cubit.dart:119`); `selection` on notifications toggle; log-out = `AppButton` `tap` + **`warning`** (heavy) right after (`settings_logout_tile.dart:36`); clear cache/rows: none.
- **Problems:** P1 language switch makes the user wait ~0.6s+commit with controls disabled (thumb spring~210+veil150+commit+1frame+veil250, `settings_language_tile.dart:49-51,66-68,77`), log-out waits under a busy overlay whose 500ms minimum does **not** add to the wait (`go(login)` fires as soon as `signOut()` returns); P2 double haptic on log-out — `tap` then heavy `warning` for a confirmed, user-chosen action; P3 ripple here vs. highlight-only on Mine rows; P4 clear-cache success is a snack only, no row state/haptic; P5 no reduced-motion route for the platform `Switch` (framework-owned); P6 dialog scales `decelerate`+fades **linearly** both ways, same for the locale veil, while pages use `signature`/`exit`; P7 log-out card pops with no transition, group cascade runs under the page slide; P8 language `success` haptic fires from the cubit, not a widget listener like every other haptic here.
- **Perf risk:** `LocaleSwapVeil` is a full-screen opacity layer over the heaviest frame in the app — the whole tree re-localises and `IndexedStack` rebuilds every tab underneath it; busy scrim is a full-screen `FadeTransition`; segmented thumb triggers a Stack relayout each frame, small.
- **Opportunity:** fix the log-out haptic to `warning`-once, drop the redundant `tap` (D21; R07-26 "don't use a [strong negative] pattern for a choice the user just confirmed" — the destructive-confirm mapping already exists in D21, this call site just needs to follow it); align the dialog/veil curves to `signature`/`exit` (D5); apply D22's consistent press language to Settings vs. Mine rows (ripple vs. highlight, a design-system decision, not covered by §9 (decision summary) — flag for approval).
- **Assets:** Material only (`translate`, `notifications_none`, `shield`, `lock`, `cleaning_services`, `info`, `logout`); nothing critical missing, a log-out dialog illustration is optional.

---

### 6. About — `lib/src/features/account/presentation/pages/mine_about_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:31-38`) + `SettingsAppBar` title `ScrollReveal`.
- **Motion:** #1 app logo **pops from scale 0 with overshoot on every visit**, `PopScale.onMount`, `medium`/`easeOutBack` (`about_header.dart:18`; `pop_scale.dart:37-51`); #2 links/follow/copyright `StaggerEntrance` idx1-3 (`about_body.dart:31-44`); #3 link rows ripple (`about_links_section.dart:25-56`); #4 social tile `PressScale`0.97+`selection`, floating snack after copy (`about_social_chip.dart:20,24-31,37-40`); #5 Licenses page = Material `showLicensePage` platform route, **not** `HeroTransitionPage` (`about_links_section.dart:41-45`); #6 "Rate us" = floating snack only, does nothing (`about_links_section.dart:51-55`).
- **State-change:** static page, no cubit, no loading/error/offline (`mine_about_page.dart:8-10`).
- **Gestures:** scroll, taps, back.
- **Haptics:** `selection` on social tiles only.
- **Problems:** P1 a static brand mark grows from zero with overshoot on every visit, during the page's own 300ms slide+fade; P2 Licenses uses the Material default route+chrome, the only account page with iOS edge-swipe back [inference]; P3 "Rate us" shows a thank-you snack and does nothing; P4 copy feedback is a snack here vs. an inline "Copied" flip on Delivery code; P5 stagger indices start at 1, the first group waits 30ms for nothing (minor).
- **Perf risk:** logo carries `AppShadows.high`+`ClipRRect`, shadow re-rastered for 250ms once during the pop; decode sized with `cacheWidth` (good).
- **Opportunity:** drop the every-visit logo pop, or gate it to first-ever visit (R08-08 "delight decays into distraction with repetition" — this is the textbook case); unify copy feedback with Delivery code's inline "Copied" flip (D13's `FlipValue`) instead of a snack (R08-21 inline persists, toast is worse for a11y); either wire "Rate us" to a real store link or drop the promise-snack (correctness fix, not a motion pattern).
- **Assets:** app logo 1024px PNG; social tiles use generic Material icons (`facebook_rounded`, `camera_alt_outlined`, `alternate_email_rounded`) — needs real brand social glyphs (check trademark rules).

---

### 7. Delivery code — `lib/src/features/account/presentation/pages/mine_delivery_code_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:39-46`) + `SettingsAppBar` title `ScrollReveal`; save bar is the Scaffold's `bottomNavigationBar` (`mine_delivery_code_page.dart:26`).
- **Motion:** #1 hero/editor/tips cards `StaggerEntrance`0-2 (`delivery_code_body.dart:28-32`); #2 saved digits `FlipValue` per digit, **likely fires on open too** (''→code, cubit loads async) (`delivery_code_digit_box.dart:37-43`; `delivery_code_cubit.dart:16-37`); #3 copy pill dip+tint+`FlipValue`×2 to "Copied", back after a raw **1800ms** hold (`delivery_code_copy_button.dart:29,34-42,62-104`); #4 editor slot border/fill `AnimatedContainer` (`delivery_code_cell.dart:27-41`); #5 save `AppButton` dip+ripple+`tap` (`delivery_code_save_bar.dart:45-49`); #6 after save: OS keyboard dismiss, floating snack, digits flip to the new code, slots turn green (`delivery_code_save_bar.dart:34-41`).
- **State-change:** loading = 4 empty tiles+disabled copy pill, no skeleton/loader; **error never renders** — no widget reads `status`/`failure` (grep: 0 hits), a failed load fails silently; success = green slots+snack+flip; offline/stale/signed-out n/a (local offline-catalogue value).
- **Gestures:** tap slots to focus (invisible `TextField`), type, scroll, back.
- **Haptics:** `selection` on copy; `tap` on Save; **no success haptic on save**, no per-digit haptic, no warning while incomplete (Save just disabled).
- **Problems:** P1 digits probably flip on open as if the code had changed [device check]; P2 no loading state, no error state, silent failure; P3 Profile save gives success haptic+check+hold, this is a snack only; P4 slots only change border colour while OTP's `AppSprings.calm` "typed digit" spec is used by OTP, not here; P5 raw 1800ms copied-hold value; P6 `bottomNavigationBar` save bar likely hidden by the keyboard while typing (Profile's rises with it) [device check]; P7 Save enable is a colour snap while Profile's Save fades.
- **Perf risk:** trivial — 4 flips + 4 `AnimatedContainer`s; invisible field under `Opacity(0)` skips paint.
- **Opportunity:** silence the flip on the very first load (never animate a value that hasn't actually changed, generalising D20's "never count up from 0 on open" to any glyph reveal); add a skeleton for the loading state and an error state (D18, CLAUDE.md §3.2 contract); align save success with Profile — success haptic + check (D21); move the save bar off `bottomNavigationBar` so it rises with the keyboard, matching Profile.
- **Assets:** needs an explanatory illustration ("rider at the door asks for this code") for the hero/tips card; shares the Mine scan-glyph mismatch noted in §1.

---

### 8. Edit profile — `lib/src/features/account/presentation/pages/profile_edit_page.dart`
- **Entry/exit:** shared `HeroTransitionPage` (`account_routes.dart:15-22`) + `ProfileEditAppBar` title `ScrollReveal`; leaves by itself after save (`context.pop()`, `profile_edit_listener.dart:41`).
- **Motion:** #1 screen switch loading/form/signed-out/error via `FadeThroughSwitcher` (`profile_edit_body.dart:37-53`); #2 loader disc (`profile_edit_body.dart:51`); #3 3 cards `StaggerEntrance`0-2 (`profile_form.dart:99-133`); #4 completion ring glides on change, `TweenAnimationBuilder`+`CustomPaint`, check `PopScale.onMount` at 100%, arc always clockwise, **not mirrored in RTL** (`profile_completion_ring.dart:69-108`; `profile_completion_ring_painter.dart:31-38`); #5 completion title `FlipValue` (`profile_completion_card.dart:120-128`); #6 field border `AnimatedContainer` on focus/error; #7 inline error `AnimatedSize`+`AnimatedSwitcher`; #8 refused field `ShakeX`8dp×3 (`profile_text_field.dart:34,85-88`; `shake_x.dart:36,42`); #9 gender chip fill fades+corners spring square→pill, `PressScale`0.96 `haptic:null` (`profile_gender_chip.dart:36-56`); #10 household `FlipValue`+`QtyStepperRoundButton` `PressScale`+`selection` (`profile_household_field.dart:47-81`); #11 date-of-birth sheet opens in year mode when empty, closes the instant a day is tapped (`profile_date_of_birth_sheet.dart:53-56`; `navigation.dart:30-42`); #12 save pill colour/label fade+dip+ripple (`profile_save_button.dart:46-93`); #13 saving: scrim+disc, saved: dots→drawn check via `CubitBusyOverlay` (`profile_edit_page.dart:43-47`); #14 after save: success haptic+**400ms hold**+snack+pop (`profile_edit_listener.dart:32-42`); #15 bonus hint inserted with **no transition** when the programme loads (`profile_bonus_hint.dart:23-31`); #16 date box ripple, household stepper dims via `Opacity` with no fade when disabled (`profile_value_box.dart:36-37`; `qty_stepper_round_button.dart:47-53`).
- **State-change:** loading(no confirmed customer)→form via fade-through, else form shows at once; signed-out=lock pop+green button; first-load error=`ErrorView` directly, **no `FailureView`** (`profile_edit_body.dart:47-50`); background-refresh/save failure=`Haptics.warning`(unless offline)+`showFailureSnackBar`, typed values kept; refused(invalid)=`Haptics.warning`+shake+refocus+a11y announcement; saving→saved=overlay→check→hold→snack+pop; 100% reached by typing=success haptic+check pop.
- **Gestures:** scroll (keyboard dismisses on drag), field taps, chips, stepper, sheet drag-to-dismiss, back blocked while busy.
- **Haptics:** `tap`(save), `success`(saved; completion 100%), `warning`(refused; online failure), `selection`(gender; stepper).
- **Problems:** P1 save makes the user wait: network+check+400ms hold+250ms pop, taps+back blocked, the 500ms overlay minimum overlaps the hold (only lengthens a save that fails under 500ms); P2 offline contract missing on first-load failure, same as Rewards; P3 bonus hint pops in and pushes the section down on the programme's first arrival of a run; P4 loading language inconsistent — a loader disc here vs. shape-matching skeletons on Wallet/Loyalty; P5 card cascade runs under the page slide; P6 ring doesn't mirror in RTL [needs a decision]; P7 two `success` haptics can land close together (100% then save); P8 date sheet closes the moment a day is tapped, no haptic, no selected-state frame.
- **Perf risk:** ring rebuilds `CustomPaint`+`FittedBox` text every frame for 400ms (in a `RepaintBoundary`); gender chips rebuild the surface every frame of two nested tweens; `ProfileCompletionCard`'s `BlocSelector` rebuilds the whole gradient+shadow hero on every completion/title change; `AnimatedSize` relays out the form for 150ms per error change; busy scrim full-screen.
- **Opportunity:** unify the loading language to a skeleton across account (D18, matches Wallet/Loyalty); adopt `FailureView`+offline contract on first-load error (CLAUDE.md §3.2); the 400ms hold + check pattern already matches R08-23 "confirm success only for significant tasks" — leave that part as is; RTL ring mirror needs an explicit decision (add to the D24 approval list); date-picker pick could get a `selection` haptic to match Profile's other selection-type interactions (D21).
- **Assets:** no profile avatar/photo placeholder (API has no picture, Mine shows an initial/person glyph); sign-in illustration shared with Wallet/Loyalty/Rewards; error/offline illustration shared; a completion-celebration asset is optional.

---

### 9. Splash — `lib/src/features/splash/presentation/pages/splash_page.dart`
- **Entry/exit:** first route, `HeroTransitionPage` with no push animation (`splash_routes.dart:11-15`), first frame repeats the native launch frame (`splash_player.dart:18-20`); exit `context.go(Routes.shell, extra: ShellEntrance.splash)` → `HeroFadeThroughPage`(fade+0.96→1 zoom,300ms signature, `shell_routes.dart:60-65`) — the shell fades in over a **frozen** splash frame because Flutter keeps the old route mounted until the new one is idle (`navigator.dart:4462,4563-4567`); no RTL direction to this motion.
- **Motion:** one clock drives one `CustomPaint`/`RepaintBoundary` (`splash_player.dart:59-62,151-158`), default variant `wordmark` 2000ms `AppMotion.splashWordmark`: #1 start gate waits `waitUntilFirstFrameRasterized` or `splashFirstFrameWait`600, holds `splashHandOffHold`250 (`splash_player.dart:105-121`); #2 crouch130/flight520/swing+36dp/rise64dp/lean−0.16, raw ms constants (`splash_assembly.dart:30-44,136-151`); #3 3 speed-line strokes (`splash_scene_painting.dart:104-136`); #4 cape wave/flight spin/fold (`splash_assembly.dart:185-195`); #5 3 drifting aurora blobs+arrival glow pulse, raw 4600-6400ms (`splash_ambient_painting.dart:28-32,41-65`); #6 ground/air rings (`splash_assembly.dart:207-218`); #7 letter deliveries, Latin4×80ms/Arabic2×150ms, landing squash+bag recoil (`splash_wordmark.dart:9,13`; `splash_assembly.dart:64-73,154-166`); #8 light sweep 560ms `machEaseInOut` inside a `saveLayer` (`splash_assembly.dart:81,221-226`; `splash_scene_painting.dart:58-63`); #9 confetti 18 pieces, gravity over 950ms, fades from 55% (`splash_assembly.dart:77,219`; `splash_confetti_painting.dart:22,35,66`); #10 post-arrival float bob 1700ms period; #11 tagline `FadeTransition`+`SlideTransition` on an `Interval`; #12 touch ring 700ms `splashTapRipple`; #13 glow leans toward the finger, raw 90ms exponential ease; #14 touch-on-bag hop+squash+cape flick 520ms `splashMarkHop`+`Haptics.tap`; #15 status-bar style flip (burst variant only); #16 exit fade-through (above).
- **State-change:** none; `onFinished` fires once, a failsafe timer at 2× duration+start delay guards against a hang (`splash_player.dart:84-88`); under reduced motion the clock jumps to 1 and a 700ms `splashReducedHold` timer hands off, touch disabled entirely (`splash_player.dart:96-99`; `splash_touch_surface.dart:35-36`).
- **Gestures:** tap/drag anywhere gives the ring+glow lean, tap on the mark gives the hop; touch **never shortens the intro**, no skip (`splash_player.dart:28-31`).
- **Haptics:** `tap` on a bag tap only.
- **Problems:** P1 makes the user wait — 0.25-0.85s start gate + 2.0-2.55s intro + 0.3s fade-through on every cold start, no skip, no Home-feed prefetch overlap (`HomeCubit` not created during splash, `app.dart`/`config/di/app_global_cubits.dart:16-47`; only auth restore+cart mirror start during it); P2 **confetti cut mid-flight in every variant** — wordmark Latin freezes at ~66% (starts 1370, runs to 2320, clock completes at 2000), Arabic/basket/burst all overrun similarly, the float bob+cape idle also freeze on that last frame under the fade; P3 RTL — the flight always swoops physical right (`flightSwing=+36`), speed lines trail back-left, no Directionality/RTL code anywhere though the Arabic wordmark delivers in reading order [open question if intended]; P4 all choreography timings are file-local raw ms constants, only the totals are `AppMotion.splash*` tokens.
- **Perf risk:** full-screen `CustomPaint` repaints every frame for ~2s (1 `drawRect`+4 large radial-gradient circles up to 0.85×shortest side×1.25 at pulse peak); a full-screen even-odd `clipPath` during deliveries (~690-1350ms); a `saveLayer` bounded to the lockup during the 560ms shine; burst variant adds a full-screen oval `clipPath` and paints the scene **twice** while 0<burst<1; scene isolated by its own `RepaintBoundary`, touch ticker rests when settled, nothing runs after dispose.
- **Opportunity:** overlap the intro with the first data fetch — this is §9 (decision summary)'s own explicit finding, not a new one (D23 "splash should overlap the Home load"; R08-15 "show something at once, keep progress indicators moving"); fix the confetti overrun by shortening its run or extending the total clock so it never freezes mid-burst (tokenise per D2/D3, keep `slow`400 as the functional ceiling but let the confetti/bob free-run inside the fixed total instead of past it); RTL mirroring of the flight direction needs an explicit decision (already flagged as approval-needed alongside "splash skip" in D24); a skip-on-touch affordance is already on the D24 approval list — this audit's non-skippable timing is the direct motivating case.
- **Assets:** all painted (`HeroMark`, `HeroGlyphs` Latin/Arabic paths, painted groceries, painted confetti); native launch asset `splash_mark.png` not audited; no GIF/Lottie; reduced motion paints the final lockup, needs no extra art. **No gaps found.**

---

### 10. Main shell — `lib/src/features/shell/presentation/pages/main_shell_page.dart`
- **Entry/exit:** from splash = `HeroFadeThroughPage` (`shell_routes.dart:60-65`); any bare `go(Routes.shell)` builds a `HeroTransitionPage` instead (`shell_routes.dart:66-79`) — callers: OTP success, closing sign-in as the whole stack, coupons "use", the Pro top bar. Because go_router keeps `extra` across pushes but `Page.canUpdate` needs the same `runtimeType`, a cold-start shell (`HeroFadeThroughPage`) is **replaced** by a new `MainShellPage` (`HeroTransitionPage`) on that first later `go` — every tab and its scroll reset to Home [static reasoning, confirm on device] (`navigator.dart:762-764`; `match.dart:607-613,891-903`). Pushed routes on top: the shell shows no secondary-animation motion (`hero_transition_page.dart:26`).
- **Motion:** #1 tab body switch = **none**, `IndexedStack` cuts instantly (`main_shell_page.dart:62-75`); #2 selected icon `AnimatedScale`1.0→1.12 `fast` (`shell_nav_item.dart:35,56-59`); #3 label colour/weight `AnimatedDefaultTextStyle` `fast` (`shell_nav_item.dart:78-86`); #4 icon **colour snaps** via `IconTheme.merge`, not tweened (`shell_nav_item.dart:63-66`); #5 press = passive `PressScale`0.96 over `InkWell` (`shell_nav_item.dart:46-48`); #6 Home tab: `HeroMarkIcon` morphs+hops, `TweenAnimationBuilder` over raw `popup`350ms, no mount animation (`hero_mark_icon.dart:25-36`; `shell_bottom_nav.dart:52`); #7 cart badge `PopScale(popKey:count)`, **restarts from scale0 on every change incl. first appearance**, and **cuts out with no exit** at count 0 (`shell_nav_badge.dart:20-21`; `pop_scale.dart:49,61,80`; `shell_nav_item.dart:69-74`); segment badge behaves the same (`shell_basket_segment.dart:62-65`); #8 fly-to-cart target registered here, `Opacity`-per-tick overlay, 400ms `slow`, skipped under reduced (`main_shell_page.dart:33-39`; `fly_to_cart.dart:143-146,186-199,60,81`); #9 cart-tab pill thumb `AnimatedAlign`, RTL-aware, `medium` (`shell_basket_switch.dart:45-62`); #10 segment label `AnimatedDefaultTextStyle` `fast`, segment **icon colour snaps** (`shell_basket_segment.dart:46-50,43`); #11 segment cart count reuses the same pop, one add pops **two** badges (`shell_basket_segment.dart:64`); #12 cart↔history body = **snap** (`shell_basket_tab.dart:98-107`).
- **State-change:** no data states of its own; a locale change recreates all tab elements (`ValueKey(languageCode)`, `main_shell_page.dart:59-64`) under the covering `LocaleSwapVeil`, so the rebuild is unseen; whether tab entrances replay was not verified.
- **Gestures:** tap only, no horizontal swipe between tabs; **no `PopScope`**, system back on Search/Cart/Mine leaves the shell/app instead of going Home (`PopScope` exists only in `busy_overlay.dart:144`, `address_edit_page.dart:80`, `checkout_note_sheet.dart:63`, `pdp_image_viewer_page.dart:91`); cart/history segments are `GestureDetector`s with no press feedback.
- **Haptics:** **none** on tab taps (passive `PressScale` fires nothing) — contradicts the `HapticKind.selection` doc "chip/tab" (`haptics.dart:18`); none on the cart/history segments either.
- **Problems:** P1 tab switch has no motion and no haptic, though the cart-pill thumb in the same shell slides and the coupons tabs swipe with `TabBarView`; P2 one tap produces three timings (icon snaps, label+scale `fast`, Home mark `popup`350); P3 badge vanishes to scale0 and regrows per change, twice when Cart is open; P4 shell enters two ways — vertical sheet after sign-in/coupons/Pro vs. fade-through after splash; P5 back on a non-home tab exits instead of returning Home, no in-app predictive-back animation (Android 16+ may play the system back-to-home animation as the app closes, `targetSdk 37`); P6 cart↔history thumb slides 250ms while the body cuts instantly; P7 segments have no press state/haptic unlike nav items; P8 badge enter/exit asymmetry (pops in from 0, cuts at 0); P9 `go(Routes.shell)` rebuilds the whole app underneath the user [static reasoning] — sign-in from Mine, coupon "use" and the Pro top bar all recreate every tab.
- **Perf risk:** hidden tabs are **not** muted by `IndexedStack` itself — each tab must self-gate (`indexed_stack.dart:104-109`); Home does via `HomeRevealScope.onScreenOf`+`TickerMode`+`VisibilityDetector`, Cart/history via `TickerMode(Visibility.of)`, Mine via lazy build+`Visibility.of` on its sweeps, Search has no loop; **residual**: Mine's one-shot `RollingNumber`/`FlipValue`/`PopSwitcher` are not gated, so a data change while Mine is hidden plays unseen, and any future ambient loop placed in Search/Mine would tick hidden (only `TickerMode`-gated primitives pause); a tab tap `setState`s and rebuilds every tab root's non-const widget (`main_shell_page.dart:41`; `shell_tabs.dart:10-12`; `shell_routes.dart:19-23`).
- **Opportunity:** §9 (decision summary) already answers the headline question — tab switch should get an **incoming-tab fade**, `fast`, and explicitly **no haptic** (D11 "Tabs: incoming tab fades fast; hidden tabs under `TickerMode(false)`; no haptic" — matches R09-02's fade-through-for-tabs pattern too); give the cart/nav badge an enter/exit via `ChangeBump`+roll-on-land instead of pop-from-0/cut-at-0, same shape as the add-to-cart pipeline (D16); unify the shell's arrival on one page type so `go(Routes.shell)` never replaces the route and resets tab state (D10 "top-level go = `HeroFadeThroughPage`" already covers splash→shell — extend it to every `go(Routes.shell)` caller; add to the D24 approval list as a behaviour change since it also changes the sign-in→shell transition's visual shape); predictive back / Home-first back on a secondary tab needs its own decision (D11's approval item covers predictive back generally).
- **Assets:** tab icon family is mixed (Material `search_rounded`/`person_rounded`, icon-font `HeroIcons.cart`, painted `HeroMarkIcon`), no active/inactive glyph pairs — selection is scale+colour only on the same glyph; order-history segment is a stock Material icon next to a Hero cart glyph.

---

### 11. Login — `lib/src/features/auth/presentation/pages/login_page.dart`
- **Entry/exit:** `HeroCrossFadePage`, fade only 300/250ms signature both ways, no direction (`auth_routes.dart:15-30`); exit to OTP `context.push(Routes.otpVerify)` cross-fades, header painted identically on both pages (keyboard-fold issue, see §12); top button pops (reverse cross-fade) or `go(Routes.shell)`→vertical `HeroTransitionPage` when sign-in is the whole stack (`auth_top_button.dart:29`).
- **Motion:** #1 route cross-fade; #2 `BrandBackdrop` reveal fade+settle0.94→1 over **raw 900ms** inside a full-canvas `saveLayer` (`brand_backdrop.dart:35,47-55`; `brand_backdrop_painter.dart:34,81-101,93-101`); #3 backdrop **endless** turn (raw 70s)+breath(raw13s) while keyboard is down (`brand_backdrop.dart:77-90`; `brand_backdrop_painter.dart:29-30,84-85`); #4 `HeroLockup` `IdleLoop` cape ripple+bob, `floatLoop`3.2s, endless while keyboard down (`hero_lockup.dart:39-41`; `brand_sheet_scaffold.dart:215-219`); #5 sheet rise, raw120ms delay+`sheetLarge`500ms emphasizedDecelerate (`brand_sheet_scaffold.dart:69-70,84-101,232-235`); #6 logo settle 0.92→1; #7 entrance cascade, 8 `AuthCascadeItem`=`StaggerEntrance` **raw50ms** step (not `staggerStep`30), last item done ~700ms after mount (`auth_cascade_item.dart:11-24`; `login_body.dart:106-156`); #8 keyboard fold: header→64dp strip, logo→0.42, `medium`signature, first layout set without animation (`brand_sheet_scaffold.dart:105-153,197-231`); #9 `BrandSheetFold` offer card `SizeTransition`+`FadeTransition`; #10 `HeroWavingMark` `IdleLoop` on the offer card **endless with no `running` flag**, even while the card is folded to zero height (`hero_waving_mark.dart:24`; `login_offer_card.dart:42`); #11 offer words `FadeThroughSwitcher` on a `GET /v1/init` bonus, 300ms/scale0.92→1, reduced=150ms plain cross-fade; #12 field ring focus/error `AnimatedContainer` `fast`; #13 valid check `PopScale.onMount` `snappy`, **disappears instantly** on re-invalidation; #14 phone error `AnimatedSwitcher` fade+size; #15 blocked Continue `ShakeX`8dp×3/250ms+`Haptics.warning`+error+refocus; #16 Continue `ReadyWipe` green wipe `drawOn`700ms, turns grey **at once** when not-ready while the label still fade-throughs 300ms; #17 `BusyOverlay` while sending; #18 social pills passive `PressScale`0.97+ripple; #19 "Other methods" chevron `AnimatedRotation`250+`CollapseReveal`250; #20 top button passive `PressScale`0.9; #21 snacks via `showHeroSnackBar`.
- **State-change:** initial→sending=busy scrim+disc, CTA keeps its green label; sending→codeSent=OTP pushed at once, login overlay stays until its 500ms minimum then leaves in 150ms under the fading OTP page; error=snack only, offline via `showFailureSnackBar(action:true)`; session-expired entry=`LoginExpiredBanner` replaces the offer card, no extra motion; welcome-bonus arrival=fade-through of the offer words.
- **Gestures:** scroll, tap; back blocked while sending; no iOS swipe-back (custom route).
- **Haptics:** `selection` on the valid 8th digit; `warning` on a blocked Continue; `tap` on Continue; **none** on social pills, "Other methods", the top back/close button, or the terms links.
- **Problems:** P1 three endless loops on an idle form (backdrop, lockup, waving mark) — the waving mark's ticker is the **only** thing still scheduling frames once the backdrop+lockup stop under the keyboard, because no `running` flag reaches its `IdleLoop`; P2 entrance ≈700ms (sheet620+cascade to700, running together) on a single-field screen, phone field not autofocused; P3 raw values outside `AppMotion`: riseDelay120, cascade step50, backdrop reveal900, turn70s/breath13s; P4 two stagger systems — Timer-based `StaggerEntrance` here vs. scope-bound `EntranceCascadeItem` elsewhere; P5 blocked-submit feedback differs from OTP Verify (login shakes+warns+explains, OTP does nothing — §12 P1); P6 haptics mixed on one sheet (Continue=tap, everything else=none); P7 `IdleLoop.stop` resets to 0, so the lockup's cape/bob **snap to rest** the instant the keyboard opens while the logo is still shrinking; P8 valid check pops in with a spring, leaves with a cut; P9 the `BusyOverlay` 500ms minimum does **not** delay the OTP push, it only leaves the scrim+disc on the page underneath while OTP cross-fades in [static reasoning]; P10 Continue wipes green over 700ms on valid, grey instantly on invalid, while the label still fade-throughs 300ms.
- **Perf risk:** backdrop `CustomPaint` is `Positioned.fill`, repaints a full-screen layer (gradient+glow+transformed Picture of ≤32 groceries) **every vsync indefinitely** while the keyboard is down, though only the header band is visible above the sheet; full-canvas `saveLayer` for 900ms during the reveal; keyboard fold is a **layout** animation, `AnimatedBuilder` moves `Positioned.top` and re-lays out the whole `CustomScrollView` for 250ms; sheet rise slides a `ClipRRect`+`AppShadows.barTop` shadow surface for 620ms; `ReadyWipe` uses clip+layers for 700ms.
- **Opportunity:** bound the three idle loops with `ambientBudget`+`OnScreen` per D19 (R06-35, R07-03, R08-09 — a sign-in form is exactly the "eyes drawn to it" case), and fix the missing `running` flag on the waving mark so it actually stops when hidden; collapse the two stagger systems onto `EntranceCascade`, tokenise the 50ms step to `staggerStep`30 (D14, D17); the asymmetric `ReadyWipe` (700ms in / instant out) is directionally right per R05-09/R09-25 "exits shorter than entrances" — leave that shape, just gate it consistently; tokenise the remaining raw values onto the D2/D3 ladder; give the valid check + Continue's grey-revert a matching exit instead of a cut (D13's `PopScale`/`ReadyWipe` already support an animated reverse, just isn't used here).
- **Assets:** painted backdrop/lockup/waving mark good; social logos are raster PNGs from a reference app, not vector brand marks (180×180, Apple one non-square 195×180); Kuwait flag is an emoji string, renders differently per OS/font; session-expired notice is a Material icon in a white disc, no illustration.

---

### 12. OTP verify — `lib/src/features/auth/presentation/pages/otp_verify_page.dart`
- **Entry/exit:** `HeroCrossFadePage` 300/250ms (`auth_routes.dart:31-44`); passes `rise:false` so the header paints at once, backdrop clock stays continuous (`otp_verify_page.dart:97`; `brand_sheet_scaffold.dart:191`; `brand_backdrop_clock.dart:18-26`) — but see P7. Exit on success: busy disc check→`Haptics.success`→`Future.delayed(successHold`400ms`)`→`router.go(Routes.shell)` (usually a **new** vertical shell, see §10 Entry) — `returnTo` (Pro page only) pushes on the **next frame**, so two sheets rise one frame apart (`otp_verify_page.dart:41-50,59-62`; `store_mode_routes.dart:11`). "Edit" pops (reverse cross-fade) or `go(login)` when the stack can't pop.
- **Motion:** #1 route cross-fade, keyboard fold set without animation on first layout; #2 cascade of 4 items, 50ms step, lead-in2, 100-250ms delays (`otp_body.dart:164-181`); #3 focus waits for the route to complete then opens the keyboard (`otp_body.dart:57-72`); #4 slot tone `AnimatedContainer` `fast`; #5 digit landing fade+scale0.85→1, `AppSprings.calm`, pasted code cascades at **raw35ms**/digit (`otp_code_slots.dart:29,80-84`; `otp_code_slot.dart:41,58-74`); #6 slot row `AnimatedSize` `medium`; #7 caret blink `repeat()` over **raw1000ms**, steady under reduced (`otp_slot_caret.dart:21-45`); #8 refused code `ShakeX`8dp×3+`Haptics.warning`+select-all; #9 error line `AnimatedSwitcher`; #10 Verify `HeroSubmitButton` `ReadyWipe`; #11 `BusyOverlay` verifying→drawn check; #12 resend row `FadeThroughSwitcher` waiting→ready→sending; #13 countdown "0:28" replaced every second with **no transition**; #14 whole-code arrival (paste/autofill/dev hint) = `Haptics.tap`+auto-submit after cascade+**raw250ms**; #15 exit slide-up of the shell; #16 **deleting a digit cuts** — `Text` swapped for caret/empty with no exit (`otp_code_slot.dart:124-140`); #17 keyboard drops then returns on entry [static reasoning: the push moves focus, hiding the login keyboard, and OTP only requests focus after its 300ms route settles — both headers' fold unfolds/refolds 250ms each].
- **State-change:** idle→verifying=scrim+disc, input freezes but keeps the keyboard; verifying→verified=check+success haptic+field read-only+400ms hold+shell slide; error: refusal=shake+red slots+message, anything else=snack (offline via `showFailureSnackBar(action:true)`); resent=field clears+snack.
- **Gestures:** type, paste, SMS autofill; back blocked while verifying/verified.
- **Haptics:** `tap`(code arrived whole), `warning`(refused), `success`(verified), `tap`(Verify press); **none** on Resend or Edit.
- **Problems:** P1 a disabled Verify tap gives no feedback, unlike Login's shake+warning+explanation; P2 the success exit is **two stacked vertical slides** when `returnTo` is set (new shell + Pro page one frame apart), while splash→shell uses a fade-through; P3 countdown digits snap each second while Home's countdown flips (`FlipValue`); P4 Resend has no haptic, its confirmation is a Material default snack; P5 raw values: 35ms cascade, 250ms auto-submit, 1000ms caret; P6 waiting after a correct code ≈0.7-1.0s of motion after the server says yes (400ms hold+300ms slide, +300 for `returnTo`), the busy-overlay 500ms minimum runs alongside the request so it doesn't add to this; P7 the header does **not** stay put on entry though the page type was chosen so it would — the keyboard drop/return refolds it around the cross-fade [static reasoning]; P8 digits land with a spring, leave with a cut.
- **Perf risk:** caret `repeat()` schedules a frame every vsync for as long as the field waits, own `RepaintBoundary`, opacity layer only changes twice a cycle; backdrop+lockup loops stop while the keyboard is up (normally the case here); a keystroke rebuilds only the slot row; resend row rebuilds once a second; `AnimatedSize` relays out the row on slot-count change.
- **Opportunity:** give the disabled-Verify tap the same treatment as Login's blocked Continue — `ShakeX`+`warning`+inline reason (D13, D21; matches P1's own cross-screen finding in §14); fold the two `returnTo` slides into one sequence or a single `HeroFadeThroughPage`, same fix family as §10's shell-arrival unification (add to D24); flip the countdown digits via `FlipValue` instead of snapping, matching Home (D13); fix the header-stays-put contract by carrying focus/keyboard across the push instead of dropping and re-requesting it (correctness fix, not a token change — the page-type choice already promises this); tokenise 35/250/1000ms onto the D2/D3 ladder.
- **Assets:** text-only header, no "code sent by SMS" glyph/illustration; success is only the loader-disc check, no signed-in/welcome moment asset.

---

### 13. Address list — `lib/src/features/address/presentation/pages/address_list_page.dart`
- **Entry/exit:** `HeroTransitionPage`, vertical slide+fade 300/250ms (`address_routes.dart:12-19`); row tap `context.pop(address)` reverse250ms exit; "New address"/edit push `Routes.addressEdit`, again vertical.
- **Motion:** #1 route slide-up; #2 skeleton `Skeletonized` shimmer1100ms, solid colour under reduced (`address_list_skeleton.dart:15-19`); #3 loading→loaded/empty/error/signed-out = **instant swap**, no fade-through (`address_list_body.dart:27-43`); #4 rows `StaggerEntrance(index)` fade+8% rise, 30ms×index clamp10, Timer-based, **plays for every row mounted incl. lazy-scroll and re-mounted rows**, kept rows don't replay after a delete (`address_row.dart:30-31`; `stagger_entrance.dart:54-65`; `address_list_view.dart:31-32`); each row a separately clipped `Material` slice, so the card's slices rise independently; #5 row press = passive `PressScale`+ripple, **also scales on an edit/delete icon press** because the `Listener` is passive (`address_row_tile.dart:21-25`); #6 edit/delete `IconButton` ripple only; #7 delete confirm `showHeroDialog`, scale1.1→1(decelerate)+linear fade, `medium`; #8 delete in flight = full-screen `BusyOverlay` ≥500ms (`address_list_page.dart:67-68`); #9 deleted row **snaps out** under the scrim, neighbours reflow, corner radii snap, then a snack; #10 `BrandedRefresh` pull disc on list+empty state; #11 empty/signed-out/error icons `PopScale.onMount`; #12 "New address" bar **appears/disappears instantly** on signed-out; #13 app bar `scrolledUnderElevation`0.5.
- **State-change:** loading=shimmer skeleton then a cut to rows+stagger; empty=cut to `EmptyStateView`+icon pop; error=cut to `ErrorView`, **not `FailureView`**, no offline contract on a failed first load (CLAUDE.md §3.2 violation); signed-out=`EmptyStateView` lock→`go(login)`; offline/stale=**no freshness signal**, no `DataFreshness`, no `ReconnectRefresh`; success(delete)=snack only.
- **Gestures:** pull-to-refresh, tap a row to pick, back=`Navigator.maybePop`; no swipe-to-delete, no iOS back-swipe.
- **Haptics:** `AppButton` `tap` incl. **the destructive delete Confirm, a light tap not `warning`**; Cancel none; **none** on a row pick or the edit/delete icons; `BrandedRefresh` `selection` at threshold.
- **Problems:** P1 offline/failed first load = generic `ErrorView` not the `FailureView` contract used elsewhere; P2 no stale/offline indicator on a device-copy list; P3 delete is pessimistic, **blocks the whole screen ≥500ms**, then the row cuts out, while the cart elsewhere is optimistic; P4 row staggers replay on lazily-built and re-mounted rows while scrolling, up to 300ms delay on rows ≥10, the grouped card's slices animate separately and the card "breaks" during entrance; P5 the stagger starts at mount **during** the 300ms route slide, hidden under the page's own motion because nothing waits for the route to settle; P6 status swaps cut instantly, unlike the login offer/OTP resend row's fade-through; P7 the destructive confirm gets a light `tap` haptic, picking an address gives no haptic and no selected-state motion before the pop; P8 the drill-in slides up vertically like a sheet, while other drill-ins use the horizontal shared-axis page; P9 a press on the edit/delete icon dips the whole row, the icon's own ripple and the row's scale play together.
- **Perf risk:** `ListView.builder`+`findChildIndexCallback` keep elements (good); each mounted row creates a Timer+`FadeTransition`+`SlideTransition` (up to 10 delayed); each row is a `Material` with `Clip.antiAlias`, so the entrance moves clipped content; skeleton shimmer shader runs while loading; `BusyOverlay` scrim covers the full screen.
- **Opportunity:** stop the row stagger from replaying on scroll-back/re-mount — direct D17 violation ("never on scroll-back, filter, sort, or under a route transition"), cap it to the first screenful and wait for the route to settle (D17); switch to an optimistic delete (remove at once, reconcile, roll back on failure) instead of a blocking scrim — this is exactly R08-18's pattern and matches the cart's own contract (CLAUDE.md §3.1); fix the destructive-confirm haptic to `warning` per the taxonomy (D21); adopt `FailureView`+`DataFreshness` (CLAUDE.md §3.2); switch the state swap to `FadeThroughSwitcher` (D17); consider the shared-axis page for a picker-style drill-in like other drill-ins use, flag as an approval item alongside the other page-type unifications (D24).
- **Assets:** label PNGs (`HeroAssets.labelHome/labelOffice/labelGathering/labelOther`, 72px, "other" one 70×72, from a reference app's set); empty book is a 56dp grey `HeroIcons.locationOutline` — needs an empty-addresses illustration; signed-out is a Material lock — needs a sign-in illustration; error/offline is a Material icon — needs an illustration; delete dialog is text only, no warning glyph.

---

### 14. Address edit (map) — `lib/src/features/address/presentation/pages/address_edit_page.dart`
- **Entry/exit:** `HeroTransitionPage`, vertical slide+fade 300/250ms, containing a GoogleMap platform view (`address_routes.dart:22-34`; `address_edit_view.dart:353-362`); save exits via `context.pop(saved)`+snack, fired at the status change with no wait for the busy minimum; back blocked while saving.
- **Motion:** #1 route slide-up with the map inside it; #2 new-address GPS fix (up to 6s, permission prompt may overlap the entrance)→native `animateCamera`, not moved if the controller isn't ready yet (`address_edit_view.dart:108-143`); #3 pan lifts the `CenterMarker` `AnimatedSlide`−0.08+growing shadow, `fast`/raw values −0.08/12:9/5:4/α0.18 (`center_marker.dart:22-25,84-93`); #4 candidate list dims to **raw0.45** `AnimatedOpacity` `fast` linear while nearby places load (`select_sheet.dart:65-67`); #5 candidate tap = passive `PressScale`+ripple then `animateCamera`; #6 map tap/long-press = `animateCamera`; #7 zoom±/"Locate me" = `animateCamera`, Material elevation-2 ripple-only buttons; #8 autocomplete dropdown **appears/disappears instantly**; #9 serviceability flip: map `AnimatedPositioned.bottom` `medium`, banner **appears instantly**, zoom/locate buttons **jump** (tied to the same height as plain `PositionedDirectional`s) (`address_edit_view.dart:343-349,407-425`; `select_sheet.dart:59-62`); #10 SELECT→FORM `AnimatedPositioned.top` goes `null→formTop` — an implicit tween can't start from `null`, so it **snaps** to full height though the class doc says it "rises" (`address_edit_view.dart:36-37,440-446`; Flutter `implicit_animations.dart:428-436`); #11 FORM→SELECT snaps back the same way; #12 tag chips `PressScale`+`PopScale(popKey:selected)`+`AnimatedContainer` — **every selection change pops both the new and previous chip from scale0**, all four pop on mount too, border width raw `1.5:1` (`label_chip.dart:29-50`); #13 field errors border **snaps** red, raw min heights `80:52` (`boxed_field.dart:30-41`); #14 default switch = platform `SwitchListTile.adaptive`; #15 save `BusyOverlay` ≥500ms, **no `doneOf` check**; #16 out-of-range snack; #17 candidate selection fill+`RadioDot` **snap**, no animation on `RadioDot`.
- **State-change:** editing→saving(scrim+disc)→saved(pop+snack, **no success motion or haptic**); invalid save=snack "fix errors"+inline errors, no shake, no warning haptic, no scroll-to-first-error; save failure=`showFailureSnackBar(action:true)`; a 404=refresh the book+pop; nearby loading=list dims; location permission/GPS failure=silent fallback to the base location, only visual is the raised pin+dimmed list.
- **Gestures:** map pan/pinch/tap/long-press (SELECT only); zoom/locate buttons; back always leaves the page (`canPop:!saving` only); FORM's X returns to SELECT; sheet grabber is decorative, no drag.
- **Haptics:** `AppButton` `tap`(Confirm location, Save); chips fire `tap` via the `PressScale` default though `profile_gender_chip.dart` uses `selection` for the same kind of pick; **none** on candidate rows, zoom, locate, pin drop, the switch or save success.
- **Problems:** P1 SELECT↔FORM snaps, the code's own doc promises a rise; P2 **reduced motion is not honoured by the map** — every `animateCamera` runs the native camera flight regardless of `MotionGuard`; P3 chips pop from 0 twice per tap (old+new) and again on mount, jars next to Profile's tint+snappy-spring gender chip; P4 chip haptic is `tap`, should be `selection` per the taxonomy and the profile chip's own precedent; P5 Confirm location is a **dead tap during network work** — awaits `HeroLbs.reverse` with no loading/busy state though `AppButton` supports `loading:`, a double tap is possible; P6 an invalid save gets only a snack+snapping red borders, Login's refused submit shakes/warns/explains; P7 save success has **no check** (`doneOf` absent) though OTP/Profile/checkout/order-review all show one; P8 candidate taps still dip+ripple while nearby places load, though the tap is swallowed — looks tappable, does nothing; P9 pin label text swaps with no transition, no landing settle, raw shadow-size literals; P10 on a serviceability flip the banner/buttons/map move out of step (snap/jump/250ms); P11 "Back" means two things in FORM — X returns to the map, system back leaves the page and drops the draft; P12 a platform-view map composites under a sliding/fading route (open question under Hybrid Composition); P13 candidate selection has no motion (fill+radio snap) and no haptic while the camera flies.
- **Perf risk:** a 481-line `State` calls `setState` on camera-move start/idle, nearby/search results, candidate taps and stage flips, rebuilding the whole `Stack` incl. the map widget each time; a serviceability flip **resizes the platform view every frame for 250ms**; the route slide/fade moves a platform view (composition cost, possible flicker); pin label `BoxShadow` blur8 composited over the native map, static sheet shadow blur16, zoom/locate elevation-2; `AnimatedOpacity` over the candidate column for 150ms; debounced 350ms search/nearby with sequence guards (good).
- **Opportunity:** SELECT↔FORM should use `SizeFadeSwitcher`/`CollapseReveal` instead of a null-origin `AnimatedPositioned` (D13 already has both primitives — this is a straight swap, not a new pattern); gate every `animateCamera` call behind `MotionGuard` (D7 — this is a direct rule violation, reduced motion must replace, never be ignored); unify the chip pattern with Profile's gender chip — tint+`ChangeBump`/spring instead of `PopScale`-from-0 both ways, and fix the haptic to `selection` (D13, D21); give Confirm location an `AppButton(loading:)` state to close the dead-tap window (the widget already supports it); add a `doneOf` check + haptic on save success, matching every other save flow in the app (D21, R08-23 confirm success on a significant task).
- **Assets:** icon-font back/close/location, Material zoom `+`/`-`; a painted `Container` pin, no brand map-pin asset; no map-loading placeholder (`hero_map.dart:93-94` comment says "neutral loading background" but sets `style: null`); no "locating you" state art; no location-permission-denied visual; no out-of-service-area illustration; search has no "no results" state; chip glyphs have no selected-state variant.

---

### 15. Assistant buddy layer (shell overlay) — `lib/src/features/assistant/presentation/pages/assistant_buddy_layer_page.dart` → `.../widgets/buddy/assistant_buddy_layer.dart`
- **Entry/exit:** not a route, rides the shell's own transition; launcher greets on Home only, appears on Home/Search/Mine, never Cart (`shell_routes.dart:31-32`).
- **Motion / state-change / gestures / haptics / problems / perf / assets:** full detail in Appendix A §1 (23 motion rows, 13 problems incl. loops-while-nobody-asked, artificial "thinking" dots before a proactive line, Arabic per-grapheme reshaping, mouth-flap loop, timers not TickerMode-aware, greeting countdown that can close as *ignored* under a pushed page). Headline facts kept here: launcher slides+scales on `launcherShown` flips (`assistant_buddy_launcher.dart:91-101,145-151,332-341`, moves via `Positioned` = re-layout every frame, not paint-only); mascot blinks every 3-7s/glances 15-25s for 30s after any touch (`assistant_mascot.dart:63-78`); a thought bubble runs a cadence of up to 8 lines/visit at 45s (`assistant_buddy_cubit.dart:70-83`); greeting drops per the nudge policy (≤1/day, 3-day snooze, 7-day back-off).
- **Opportunity:** superseded by §9.6 (AI assistant motion spec) §0 rules, §2.1 ("Idle state and the buddy's presence"), §3 (`BuddyMotionGate`, the full "when the buddy MAY/MUST stay still" tables) and approval items #1-9 — do not re-derive here, its recommendations win. Key shape: a *wake window* (one blink per `wakeBlinkGap`8s inside a 5s `ambientBudget`) replaces the endless ambient scheduler; autonomous glances retired; `AssistantMascot` defaults to still (`alive:false`) like `AssistantAvatar`; every movement gated by `BuddyMotionGate.mayMove`.
- **Assets:** §9.6 (AI assistant motion spec) §5 rows 1-2, 14 (per-tool glyph set, thought-topic glyph set, an AI-identity glyph pairing the sparkle with a label).

---

### 16. Assistant chat (conversation, SSE stream, composer + voice) — `lib/src/features/assistant/presentation/pages/assistant_chat_page.dart`
- **Entry/exit:** `HeroSlideUpTransitionPage` (`assistant_routes.dart:18`), full-height slide-up+fade, `page`300 signature in / `medium`250 exit-curve pop, no drag-to-dismiss, no predictive back (plain `PageRoute`).
- **Motion / state-change / gestures / haptics / problems / perf / assets:** full detail in Appendix A §2 (30 motion rows) and §3 (composer+voice, 19 rows). Headline problems kept here: header avatar never still (`alive:true` while typing/reading/recording, `assistant_chat_title.dart:26`); mouth-flap loop through the whole "thinking" wait, contradicting the deliberately-steady stream caret; thinking→first-word **snaps** (height+avatar); confetti on **every** confirmed proposal (not rare/earned) while a product-tile add flies to the cart instead — two different "went into the cart" motions on one screen; offline first-load = red `ErrorView`, offline send = a transport-error `showHeroSnackBar` not `showFailureSnackBar`; composer hint `Timer.periodic(4s)` ticks while typing/recording/covered/backgrounded; voice hold-start haptic is `success` (wrong semantics), discard is heavy `warning` for a chosen action; character counter snaps in and pushes the composer up.
- **Opportunity:** superseded by §9.6 (AI assistant motion spec) §2.2-2.11 (per-interaction Do/Timing/Haptic for thinking state, streaming reveal, bubble entrance, chips, cart-proposal cards, tool indicators, errors/retry, voice, feedback thumbs, handoff) and approval items #9-18, #20-22 — its recommendations win, do not re-derive. Key shape: `AssistantWordReveal` for streamed text (D-token `fast` word fade, network mode trails ≤500ms); proposal confirm = `FlyToCart`×≤3+badge bump/roll+`cartAdd` `selection`, **no confetti** (approval #10); voice hold-start haptic → `selection` at pointer-down (approval #13).
- **Assets:** §9.6 (AI assistant motion spec) §5 rows 1, 3-7, 10-11 (tool glyphs, mascot moods thinking/oops/handing-over, handoff illustration, signed-out/store-off/offline states, mic-permission illustration).

---

### 17. Assistant history — `lib/src/features/assistant/presentation/pages/assistant_history_page.dart`
- **Entry/exit:** `HeroTransitionPage` (`assistant_routes.dart:31`) over the chat, same family as the chat it sits on (slide-up over a slide-up); reduced→cut; no swipe-back/predictive back; picking a row pops the id back, the chat shows its loading skeleton.
- **Motion:** #1 skeleton shimmer while loading (`assistant_history_skeleton.dart:19`); #2 empty/signed-out icon `PopScale.onMount`; #3 first-load failure = `FailureView`/`HeroStateView` (checking→offline/error), the app-standard contract, correctly used here; #4 stale note "Updated … ago"; #5 `BrandedRefresh` pull disc; #6 load-more `AppLoader.inline`/retry `TextButton`; #7 row press = `InkWell` ripple only.
- **State-change:** loading→loaded/empty/error/signed-out = **snap** (plain `switch`, `assistant_history_body.dart:34-60`); rows appear all at once, no entrance; reconnect via `ReconnectRefresh`; failure snacks via `ScreenFailureListener`.
- **Gestures:** pull-to-refresh, scroll+next-page sentinel, tap a row; no swipe-to-delete, no long-press, no swipe-back.
- **Haptics:** none of its own (InkWell rows; `BrandedRefresh` has its own selection click at threshold).
- **Problems:** P1 snap between states while Ledger and Cart cross-fade with `FadeThroughSwitcher`; P2 signed-out uses `EmptyStateView`+lock while Orders/Checkout use `HeroStateView.signedOut`; P3 no press feedback beyond ripple, no haptic, on the only action (open a chat); P4 row grouping computed in `build` on every rebuild (`assistant_history_list.dart:23`, `AssistantHistoryRows.of(..., DateTime.now())`).
- **Perf risk:** low — `ListView.builder`, no per-row animation, shimmer only while loading, route fade over the whole page.
- **Opportunity:** the offline/error contract here is already correct (`FailureView`+stale notice+`ReconnectRefresh`) — the pattern the rest of the app should copy, not the other way round; swap the plain `switch` for `FadeThroughSwitcher` to match Ledger/Cart (D17; R09-02 fade-through for unrelated states); swap `EmptyStateView`+lock for `HeroStateView.signedOut` to match Orders/Checkout; compute the date grouping once per data change, not per rebuild (perf, not motion).
- **Assets:** empty history is a 56px grey Material `forum_outlined` — needs a "no chats yet" illustration (mascot+empty speech bubble, §9.6 (AI assistant motion spec) §5 row 8); signed-out needs the shared branded illustration; status chips (with support/closed) have no glyphs (§5 row 9).

---

### 18. Assistant tour (onboarding sheet) — `lib/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_sheet.dart`
- **Entry/exit:** `showHeroBottomSheet(large:true)`→`sheetLarge`500ms signature in, `medium`250 exit out, transparent background, Material default drag-to-dismiss (`sheet:37`).
- **Motion / state-change / gestures / haptics / problems / perf / assets:** full detail in Appendix A §5 (16 motion rows: perched mascot spring-drops raw240/0.5, page-drag lean±0.25rad/±8dp, per-step demo timelines 1.4-3.6s that **rebuild the whole scene every frame**, confetti 36pc from the cart corner vs. the chat's 28pc from centre). 9 problems kept: emoji hero glyph (platform-dependent, not brand art); per-grapheme typing in the ask demo (same Arabic-reshaping issue as the buddy thought); 4 different stagger/lead constants in one sheet (70/160/60ms + 180ms lead); demos replay on every return to a page; **perch tilt flips sign mid-swipe** — `lean=(page-page.round())*forward` jumps +0.5→−0.5 at every half-swipe, a jarring snap in the tour's main gesture (`assistant_onboarding_perch.dart:146`); **the step you leave resets while still half on-screen** — `onPageChanged` fires at the swipe's half-way point and the timeline jumps to 0 while that page is still visible [PLAUSIBLE].
- **Opportunity:** superseded by §9.6 (AI assistant motion spec) §2.12 ("Tour sheet") and §3.6 (`AssistantEntrance` retirement) — its recommendations win: demos play once per sheet open, not on every return; the perch drop uses `AppSprings.calm` replacing the raw 240/0.5 spring; the cart demo shows `FlyToCart`+badge, not confetti, matching the real chat's fixed flow; the typed demo moves to `AssistantWordReveal` local mode (fixes the Arabic per-grapheme issue). The **lean-flips-sign bug** (problem 8, confirmed by the arithmetic) and the **leaving-step reset** (problem 9, PLAUSIBLE) are correctness fixes independent of any token choice — continuous interpolation across the page boundary, and delay the reset until the page is fully off-screen (R02-04's "continuously interactive, never cancelled mid-gesture" is the general principle these two bugs violate).
- **Assets:** §9.6 (AI assistant motion spec) §5 row 12 ("no new asset: use the mascot's painted wave" for the emoji hand) and row 13 (tour product-tile illustrations, cleaner/bulb/coffee currently Material glyphs).



Source: Appendix A (cart preview, cart tab, checkout, checkout
vouchers, my coupons, coupon history), Appendix A
(home, search, content, offers, notifications), Appendix A (orders,
order tracking, order invoice, order review, customer-service hub, help topics, rider chat),
Appendix A (PDP image viewer, product detail, recipe detail, recipes,
Pro membership). One block per screen (23), all audit-numbered problems kept, file:lines kept per
item where the audit gave one. Numbering continues from Appendix A (18 screens, 1-18) so the
two files merge cleanly later. Tokens/primitives per §9 (decision summary) (`D#`). Evidence IDs
(`Rxx-yy`) from research_log_2026.md; `PB-xx`/`CC-xx` from Appendix B/Appendix C. Where an
idea repeats a Part-1 backlog candidate's root cause, the candidate id (`B1-xx`) is cited directly
instead of re-deriving the finding.

---

### 19. Cart preview (pushed cart) — `lib/src/features/cart/presentation/pages/cart_preview_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up 100%+fade 300ms signature / pop 250ms exit; `RoundBackButton` PressScale 0.9; empty-state "Start shopping" pops; pushing to checkout, the cart stays still (`secondaryAnimation` ignored) so the shared-axis outgoing leg is missing on that side (`config/routes/feature_routes/checkout_routes.dart:16-23`, `cart_preview_page.dart:27`).
- **Motion:** C1-C40 — `FadeThroughSwitcher` body scale .92 over the pinned deals strip+bar (C1); block loader (C2); busy "Clear" overlay ≥500ms (C3); line fold via `SliverAnimatedList`+`ListItemTransition` (C4); pending-line whole-row opacity dim, linear curve (C5); stepper↔"Remove" `FadeThroughSwitcher` (C6); qty `RollingNumber` (C7); minus↔bin `AnimatedSwitcher`, linear (C8); line note/sync banner `CollapseReveal` (C9/C10); card `AnimatedSize` (C11) with summary/express/ETA rows appearing via a **plain `if`** inside it (C11b); coupon/loyalty `ChangeBump` (C12/C13); express `Switch.adaptive` ungated (C14); Pro nudge `SizeFadeSwitcher` **nested inside** C11's own `AnimatedSize` (C15); violet Pro tag `PopScale.onMount` on **every cart open**, not only when free delivery is earned (C16); total `FadeThroughSwitcher` (C17); deals strip `CollapseReveal`+headline `FadeThroughSwitcher`+`ChangeBump` on **every** amount change (C18/C19); track fill+milestones (C20/C21); sticker buttons (C22); block-reason `CollapseReveal` (C23); bar total cross-fade+roll, struck price/delivery note **snap** (C24/C24b); basket disc `PopScale(popKey:count)` pops on **every mount and on a count drop** (C25); blocked-tap shake (C26); pull-refresh (C27); dialogs/sheets (C28-C32); deal-card press, **not scrolled into view** when selected (C33); deal-grid `FadeThroughSwitcher` (C34); fly-to-cart (C35); shelf add-control swap + **static** grid stepper, no press state (C36/C36b); image fade ungated (C37); ink (C38); failure snack (C39); route/back (C40) (`cart_view.dart`, `cart_body.dart`, full table `cart_preview_page.dart` §1).
- **State-change:** loading→loaded scales the pinned bars with the body; empty fades to a static plate; clear = dialog→busy≥500ms→zero-duration fold→empty; no error bucket, a cart failure is a snack only, background sync failures offline stay silent; offline opens the sync banner+block-reason+dims pending lines; signed-out is a hard `go(login)` stack swap with no in-page prompt; success (coupon) = haptic+sheet-pop+bump+card-grow+roll, success (all deals) = fade-through headline+bump+an emoji-only "🎉" string (`cart_view.dart:40-59`, `cart_lines_sliver.dart:90-91,110`).
- **Gestures:** vertical scroll+`BrandedRefresh`; horizontal deal-card scroll; sheet/dialog default dismiss; no swipe-to-delete, no long-press; back button/system, no predictive preview.
- **Haptics:** selection (stepper, clear link, coupon remove, loyalty, express, pull-arm, deals-grid add); tap (apply press, checkout/add-item/Pro-nudge/deal-card `PressScale` default, deals-grid remove, deals-sheet close — **two haptics per coupon apply**); warning (clear confirm, refused code, blocked checkout); success (all-deals). None on a line's "Remove" or the sync banner's "Retry".
- **Problems:** P1 pinned strip+bar zoom on every loader/empty/content swap (`cart_view.dart:85`); P2 deals headline runs a full fade-through+scale on every amount change while the bar one row below only rolls digits (`cart_deals_strip.dart:59-62`); P3 summary/express/ETA rows snap via plain-`if` inside an eased card, and the bar's struck price/delivery note also snap next to a rolling total (`cart_totals_summary.dart:45-59`, `cart_bar_summary.dart:69-84`); P4 no haptic on line "Remove" vs checkout's selection on the same action (`cart_line_row.dart:54-58`); P5 deal-card fires `tap` not `selection` like sibling selection controls (`cart_deal_card.dart:51`); P6 no reduced-motion fallback on image fade or the express `Switch.adaptive`; P7 unverified reduced-motion `SizeFadeSwitcher` assertion risk, shared with checkout, nested two-deep here (`cart_pro_nudge.dart:39`, `cart_section.dart:28-29`); P8 linear curve on C5/C8/C24/the C33 pointer; P9 slide-up cart vs shared-axis checkout, outgoing leg missing; P10 four disagreeing empty/error state families across cart/checkout/deals-sheet; P11 deals sheet opens at 500ms vs the coupon sheet's 300ms; P12 signed-out hard stack swap, no in-page moment; P13 "best deal" reward is emoji text + a 1.15 bump only; P14 grid stepper (C36b) static/instant vs the line stepper's roll+fade (C7/C8); P15 basket disc+Pro tag replay on every open including a count **drop**; P16 struck price/delivery note snap inside an otherwise-animated bar (`cart_preview_page.dart` §1 Problems 1-16).
- **Perf risk:** opacity on a full pending row incl. its image, several at once under rapid taps; C1 fades+scales the whole cart subtree incl. pinned bars per bucket change; nested `AnimatedSize` (C15 inside C11) relayouts twice; `FlyToCart` rebuilds a `Positioned` per tick via `Opacity`, not `FadeTransition`; deals-sheet `ClipRRect` clips the whole 90%-height sheet incl. the scrolling grid; C33 lerps `boxShadow` per selection; `BusyOverlay` disc carries a shadow and springs over a full scrim (`cart_view.dart:160-168`).
- **Opportunity:** unify money/qty motion on one `RollingNumber` family incl. the grid stepper (D13, D20; R08-27/28); size-transition the summary/struck-price rows instead of a plain-`if`/snap (R10-22, same family as the Part-1 Wallet finding); gate the Pro-tag and basket-disc pop to real changes, not every mount (D13 `ChangeBump`; matches D20's "never fake a change" rule already applied to Delivery Code — same root cause); fix the shared reduced-motion `SizeFadeSwitcher` risk once at the core rather than per-screen bypass (CC-01 family); tokenise the deals-sheet 500ms vs coupon-sheet 300ms onto one D2/D3 rung; route the image fade and `Switch.adaptive` through `MotionGuard` (CC-24); leave the "all deals" emoji-text celebration as is unless research judges the moment genuinely rare enough for something larger (R08-32).
- **Assets:** empty-cart is a grey Material icon plate though the branded basket PNG already ships (`cart_view.dart:90-92`); Material coupon/points/express glyphs vs checkout's branded SVGs for the same concepts; Material gift icon vs the existing `HeroAssets.offerGift`; Material `cloud_off` for the sync banner; no "best deal" celebration mark beyond emoji; deals-sheet empty/error art is generic; Pro nudge uses Material `workspace_premium`.

---

### 20. Cart tab (shell) — `lib/src/features/cart/presentation/pages/cart_tab_page.dart`
- **Entry/exit:** no route animation of its own — instant `IndexedStack` cut into shell tab 1; inside, the Cart↔history pill thumb glides (`AnimatedAlign` medium/signature) while the **two views themselves swap instantly** under it (`shell_basket_tab.dart:98-107`, `shell_basket_switch.dart:45-50`).
- **Motion:** the same `CartView` C1-C39 as §19, minus C40 (no title bar/back), plus T1 pill thumb glide + label ease (fast, not medium) + icon-colour **snap**; T2 fly-to-cart lands on the tab icon; T3 the whole cart is `TickerMode`-muted while hidden; T4 the cart-segment count bubble `PopScale(popKey:count)` pops on change and on mount (`shell_basket_switch.dart:45-50`, `shell_basket_segment.dart:33,43,62-65`, `main_shell_page.dart:38`, `cart_view.dart:67-68`).
- **State-change:** as §19, except changes made off-tab land with no list animation while hidden; a `FadeThroughSwitcher` started while hidden ends already settled under a muted ticker; signed-out replaces the whole shell via `go(login)` (`cart_lines_sliver.dart:94`, `cart_view.dart:40-42`).
- **Gestures:** pull-to-refresh+vertical scroll+sheets/dialog as §19; no back gesture (root tab); the Cart↔history pill is tap-only with no press state.
- **Haptics:** as §19; **none** on the Cart↔history pill, while checkout's segmented control and the coupon tabs both fire selection for the equivalent gesture (`shell_basket_segment.dart`, `hero_segmented_control.dart:119`, `coupons_tab_pill.dart:44`).
- **Problems:** all of §19's P1-P8, P10-P16 apply here too, plus P14 tab entry is an instant cut while only the pill thumb animates and the Cart↔history bodies underneath snap (`shell_basket_tab.dart:98`); P15 three disagreeing segmented-thumb motions across the app (this `AnimatedAlign`, checkout's spring, coupons' `TabController`), only the latter two carry a haptic; P16 no press state or haptic on the Cart↔history segments; P17 half-animated segment — the label eases 150ms, the icon colour snaps, the thumb takes 250ms, three timings in one tap (`shell_basket_tab.dart` §2 Problems 14-17, extending §1's).
- **Perf risk:** as §19 while visible; muted while hidden (T3); the tab stays mounted so every off-tab "+" rebuilds cart slices with no animation; the thumb animates a `boxShadow` through `AnimatedAlign` with no `RepaintBoundary` (`shell_basket_switch.dart:54-58`).
- **Opportunity:** give the tab entry the D11-mandated fast incoming fade and pair it with the pill-thumb move so the two halves of "switch to Cart" finally agree (D11, needs approval; R09-02 documents fade-through as the answer for bottom-nav tabs); collapse the three segmented-thumb implementations onto one primitive+token (D14; CC-26 "tab switch gets 3 different treatments," reference directly); give the pill a press state + selection haptic to match checkout's own control (D22; R08-02).
- **Assets:** as §19; the history pill mixes `HeroIcons.cart` with Material `receipt_long_rounded` (`shell_basket_switch.dart:68,76`).

---

### 21. Checkout — `lib/src/features/checkout/presentation/pages/checkout_page.dart`
- **Entry/exit:** `HeroSharedAxisPage` in/out 300/250ms signature/reverse; the covering leg is missing when entered from the Cart tab or pushed cart (both `HeroTransitionPage`, ignore `secondaryAnimation`); on success `pushReplacement` drops checkout with **no exit animation at all**, so it vanishes the instant the push to tracking starts (`checkout_routes.dart:24-31`, `checkout_page_listeners.dart:70`).
- **Motion:** K1-K38 — bucket `FadeThroughSwitcher` over the whole body+pinned bar (K1); loader waits **up to 1200ms** for the cross-sell rail (K2); busy+confetti+done-check on place (K3/K4); mode-toggle spring (K5); address↔branch `SizeFadeSwitcher`, **bypassed under reduced motion** (K6); blocked-tap shake to the target row (K7); destination dots (K8); ETA `FlipValue` (K9); express badge **bumps in but snaps out** (K10); ETA card `CollapseReveal`+`FadeThroughSwitcher` (K11); maintenance banner (K12); rail add+`FlyToCart` to the bar total (K13/K14); issue banner (K15); thumb `PopSwitcher`+`ChangeBump` (K16-K18); unlock tag `PopSwitcher` (K19); savings figure `FadeThroughSwitcher`+`CountUpText`, **inconsistent** — a code applied this visit counts up on every later re-price, a code already present at open never moves (K20); points row (K21); receipt `CollapseReveal`×5 (K22); receipt total `FadeThroughSwitcher` (K23); min-order notice (K24); payment `OptionRow`+radio spring (K25); auto-switch-to-cash row bump (K26); bar total roll (K27); fact line rotates **every ≈3.3s for the whole visit** (K28); place-pill phases (K29); blocked-place scroll+shake/sheet/snack (K30); savings hint floats **6×1600ms ≈9.6s** (K31); sheets incl. a **stacked** timing→slot sheet (K32); slot chip (K33); items-sheet auto-close (K34); freeze after placing (K35); snacks (K36); image fade ungated (K37); ink-theme mismatch, InkSparkle on the page vs the documented flat tint (K38) (`checkout_page.dart` full table).
- **State-change:** loading waits up to 1.2s for the rail then fades the whole body in a **second** time (route entrance + K1 stack); error is a static plate for **any** failure incl. offline, no `FailureView`/`ReconnectRefresh`; offline swaps the bar's fact line for "You're offline" with no motion; signed-out/empty are static plates; success fires check+confetti+`pushReplacement` in **one** listener call, so most of the done-check is hidden behind the incoming tracking page [inference]; the title bar snaps taller with no transition when the store/branch name arrives (`checkout_page.dart:91,158-180`, `checkout_page_listeners.dart:57-71`, `checkout_title_bar.dart:26-33`).
- **Gestures:** one vertical scroll (keyboard dismiss on drag) + horizontal rail scroll; any scroll dismisses the savings hint; sheets drag/tap-strip dismiss; no pull-to-refresh, no long-press; back blocked while placing, no predictive preview.
- **Haptics:** selection (mode toggle, option rows, slot chip, rail add/remove, items "Remove", points switch); tap (place); warning (blocked place); success (placed); warning/success (code sheet); deliberately none on the express badge or the payment-row bump.
- **Problems:** P1 up to 1.2s wait for the rail with no fallback layout; P2 double entrance, route+K1 both scale the whole body; P3 half shared-axis from the cart tab/pushed cart; P4 success check hidden by a same-frame `pushReplacement`; P5 the fact line loops next to "Place order" for the whole visit with no user control (WCAG 2.2.2 question); P6 pinned-fact↔offline and rotating-line swaps snap inside an otherwise animated bar; P7 title-bar re-layout on arrival; P8 offline contract missing entirely on first-load error; P9 the "blocked CTA" language disagrees screen to screen and vs cart; P10 items-sheet snaps rows vs cart's fold; P11 the timing sheet's radio never animates because its state applies after the pop; P12 `CheckoutInkTheme`'s own doc vs its sheets-only reality; P13 up to 7 simultaneous motions can fire on one coupon/points change; P14 empty-state icon mismatch vs cart; P15 the pickup-branch sheet has no empty state; P16 image fade/`Switch.adaptive` ungated; P17 sheet-close control style drift; P18 stacked timing→slot sheets; P19 asymmetric express badge (bumps in, snaps out); P20 inconsistent count-up between a new code and a pre-existing one (`checkout_page.dart` §3 Problems 1-20).
- **Perf risk:** two nested `FadeTransition` opacity layers over the whole page for 300ms; K1's one-time whole-body opacity+scale; `ChangeBump` has no `RepaintBoundary` and several fire together on a totals change; `CollapseReveal` relays out the sliver per frame, several at once; `CheckoutSheetFrame` rebuilds on every keyboard-inset frame; the success window overlaps `BusyOverlay`+`LoaderDoneMark`+36-piece confetti+the incoming route's opacity for ≈300-1400ms; K20's `CountUpText` rebuilds `Text` every frame for 700ms with no `RepaintBoundary` (`checkout_page.dart` §3 Perf risk; `hero_shared_axis_transition.dart:46-50`, `count_up_text.dart:58-69`).
- **Opportunity:** give the fact-line rotation a pause affordance or move it away from the primary CTA (flag for approval, WCAG 2.2.2); adopt `FailureView`+the offline contract to match CLAUDE.md §3.2 and Home/Offers (n/a architecture rule, matches B1-04's root cause); sequence the up-to-7 coupon/points-change motions instead of firing at once (D17 extended; R08-27 favours one quick delta over a stack); unify the blocked-CTA shake+scroll-to-field language across cart/checkout (D13; same shape as B1-18's OTP/Address fix); fold the stacked timing→slot sheets into one flow (K32; CC-13 page-type-drift family); tokenise the ≈3.3s fact-line rotation and the 9.6s hint float onto the D2/D3 ladder (CC-23 wrong-token-use family).
- **Assets:** branded SVGs exist (checkoutVoucherDisc/Points/Cash/Wallet/ExpressBolt) but the bar fact line still draws Material `delivery_dining` instead of the branded rider PNG the cart bar already uses; empty-basket/signed-out/error illustrations share the cart's own gap; no branch-sheet empty art; the maintenance banner is an info icon only.

---

### 22. Checkout — Coupons & offers (vouchers) — `lib/src/features/checkout/presentation/pages/checkout_vouchers_page.dart`
- **Entry/exit:** `HeroSharedAxisPage` over checkout, both legs play; on success the code sheet pops and the page **pops itself in the same beat**, so the two exits overlap ≈250ms rather than running back to back (`checkout_routes.dart:32-44`, `checkout_code_row.dart:27-34`).
- **Motion:** V1-V12 — hard loader→content swap, no switcher (V1); first-screen `EntranceCascade` 4 slots staggerStep30 (V2); applied-coupon `CollapseReveal` (V3); "✓Applied" `PopSwitcher` (V4); offer `PopSwitcher`+progress bar (V5/V6); per-second countdowns on a shared `SecondClockScope` (V7); code sheet (V8); refused shake+`CollapseReveal` (V9); apply-pill phases, the success check visible **only during the sheet's own exit** (V10); success exit — sheet-pop overlapping page-pop, then checkout's own 700ms count-up (V11); InkSparkle despite the flat-tint doc (V12) (`checkout_vouchers_body.dart` table).
- **State-change:** loading→snap→cascade; **no error/offline state at all** — a failed read renders as "ready, no offers," so offline the page says "No offers are running" as plain text, not the truth; empty is the same text only; an offer becoming applied **jumps** between two separately-keyed slivers with no motion (`checkout_offers_state.dart`, `checkout_vouchers_footer.dart:41-47`, `checkout_vouchers_body.dart:88-109`).
- **Gestures:** vertical scroll only; no pull-to-refresh; code sheet drag/tap-strip dismiss; back button/system, no predictive preview.
- **Haptics:** warning (refusal, too-short code on the disabled pill); success (apply); selection (remove); tap (apply-pill press); the code-row tap itself is silent.
- **Problems:** P1 loader→content is the only unswitched bucket change on this flow vs cart/checkout's fade-through; P2 success is ≈0.95s of two overlapping exits then a 700ms count-up on checkout, not "back to back"; P3 an unlocked offer jumps sections with no continuity cue; P4 cascade steps 30ms here vs the wallet's raw 60ms; P5 offline/failed-read shows the same "no offers" text as genuinely empty; P6 InkSparkle contradicts the `CheckoutInkTheme` doc; P7 no predictive back (`checkout_vouchers_body.dart` §4 Problems 1-7).
- **Perf risk:** any cart change rebuilds the whole `CustomScrollView` because the body reads `now` at build; the code sheet rebuilds on every keyboard frame; otherwise well-contained — one shared 1s timer, ≤4 cascade controllers, checkout below muted (`checkout_vouchers_body.dart:43-57`, `checkout_sheet_frame.dart:80,84`).
- **Opportunity:** swap the hard loader→content swap for `FadeThroughSwitcher` to match cart/checkout (D17); give an unlocking offer a shared continuity cue instead of a section jump (R09-06 hero/zoom-continuity principle, adapted); wire a real offline/error state through `FailureView` instead of the misleading "no offers" text (CLAUDE.md §3.2, matches B1-04's root cause); tokenise the 60ms coupon-card cascade step onto staggerStep30 (D2/D3, CC-03).
- **Assets:** every ticket shares one SVG headline glyph though the cart's own deal cards already distinguish delivery/gift/voucher art; no "no offers"/offline/error illustration; the "unlocked" moment is only a Material check inside V5's pop.

---

### 23. History coupons — `lib/src/features/coupons/presentation/pages/history_coupons_page.dart`
- **Entry/exit:** a second 100% `HeroTransitionPage` slide-up stacked on My coupons, which stays static underneath; this is a drill-in inside one flow yet does **not** use `HeroSharedAxisPage`, whose own doc reserves it for exactly that case; pop 250ms, no predictive preview (`coupons_routes.dart:18-24`, `hero_shared_axis_page.dart:6-9`).
- **Motion:** H1-H10 — skeleton shimmer then hard swap (H1); title `ScrollReveal` (H2); scrolled-under shadow ungated (H3); section headings `ScrollReveal` (H4); faded-ticket `ScrollReveal` capped at 5, raw 60ms step (H5); stamps pop on **every mount** (H6); card press→rule sheet (H7); empty-history pop+**infinite float** (H8); error pop (H9); back press (H10).
- **State-change:** loading→loaded is shimmer→snap→rise/pop; empty floats forever; error is a popping icon; offline/stale/signed-out/success n/a (local catalogue data).
- **Gestures:** vertical scroll only; no pull-to-refresh; rule sheet drag-dismiss; back button/system, no predictive preview.
- **Haptics:** selection on card tap; tap on "Got it"; none on back or the rule-sheet ✕.
- **Problems:** P1 skeleton→snap jarring, same as My coupons; P2 stamps/tickets replay on scroll-back because the lazy `SliverList` disposes off-screen items; P3 empty state floats forever for no reason; P4 a stacked slide-up used for what is really a drill-in; P5 the expired group continues the used group's stagger index, so on a long first screen every expired card waits the max 300ms; P6 raw 60ms cascade step; P7 no in-app predictive-back preview; P8 History creates its own `CouponsCubit` and reloads the same local data, showing a second undelayed shimmer flash for data already on screen in My coupons (`history_coupons_page.dart` §6 Problems 1-8).
- **Perf risk:** every ticket paints a `ClipPath`+`MaskFilter`-blur shadow inside a `RepaintBoundary`, plus a 400ms `ScrollReveal` opacity layer per card as it enters; every unrevealed item listens to scroll position until it plays, bounded.
- **Opportunity:** route History through My coupons' already-loaded `CouponsCubit` instead of a second local read, removing the duplicate shimmer flash (n/a architecture); switch the drill-in to `HeroSharedAxisPage` to match its own documented purpose (D8/D9, CC-13 page-type-drift family); cap the stagger to "first load only" and stop the cross-group index carry-over (D17; matches B1-08's exact root cause); gate the empty-state float with ambientBudget+OnScreen (D14, D19; R06-35, R08-09); tokenise the 60ms step onto staggerStep 30 (shared with §22).
- **Assets:** empty-history illustration is a Material glyph in a disc; error illustration generic; same branded-coupon-glyph gap as My coupons.

---

### 24. My coupons — `lib/src/features/coupons/presentation/pages/my_coupons_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop; "Use" leaves via `go(Routes.shell)`, which — because go_router keys a page by path — **keeps** the existing shell route and pops My coupons with its own 250ms exit (reads as "back"), landing on the tab the user came from, not Home [inference, verify on device]; no predictive preview (`coupons_routes.dart:10-16`, `my_coupons/coupons_tab_list.dart:49`).
- **Motion:** M1-M23 — undelayed skeleton shimmer (M1) then hard swap (M2); app-bar title rise (M3); scrolled-under shadow ungated (M4); back/History press (M5); savings-card `StaggerEntrance` (M6); "Save up to" `CountUpText` **from 0 on every open** (M7); badge `GlowPulse` forever (M8) + pop on mount (M9); tab-bar drop-in (M10); tab thumb via `TabController.animateTo` fixed at creation-time **300ms `Curves.ease`** vs the pill's own `emphasizedDecelerate` (M11/M12); count bubble pops on mount only, but hidden under the tab bar's own fade (M13); `TabBarView` pages stay at the fixed 300ms/`Curves.ease` even when the mid-visit reduced-motion toggle is honoured by the thumb (M14); ticket `ScrollReveal` 60ms step capped 5 (M15); ticket press→rule sheet (M16); stub `CountUpText` **from 0** (M17); "Use" pill `LightSweep` on the first 3 cards (M18); USED/EXPIRED stamp pop (M19); empty tab pop+`FloatLoop` forever (M20); rule-sheet header pop (M21); error pop (M22); "Got it" press (M23) (`my_coupons_content.dart` table).
- **State-change:** loading→snap→about six primitives start inside the first ≈700ms (cascade+count-up+pops+reveals+stub count-ups+sweeps); empty shows a static summary + forever-floating tab icon; error is a popping icon with retry; no offline/stale/signed-out/success states (local catalogue) (`coupons_state_switch.dart:20-34`).
- **Gestures:** horizontal swipe between the 3 tab lists (thumb+pages mirror in RTL); vertical scroll; rule sheet drag-dismiss; no pull-to-refresh, no long-press; back button/system, no predictive preview.
- **Haptics:** selection on the tab pill (none if already selected) and on card tap; tap on "Use"/"History"/"Got it"; none on back or the rule-sheet ✕.
- **Problems:** P1 jarring skeleton→snap then an unorchestrated burst of overlapping entrances; P2 "Save up to" contradicts the app's own "never count up on open" rule that checkout itself follows for a pre-existing code; P3 two infinite loops for no reason — glow forever, float on empty tabs; P4 `TabBarView`'s non-keep-alive lazy list means reveals/count-ups/stamp-pops/empty-pops/sweeps all replay on every tab revisit and scroll-back [framework behaviour, verify]; P5 token drift — raw 60ms ticket step vs staggerStep30, raw 30ms `StaggerEntrance` default, and the "Use" shine borrows `sheen` 3600ms though the grounded CSS reference is `shineSweep` 2000ms; P6 Timers not `TickerMode`-aware (low impact, confirmed mostly harmless); P7 double entrance — the 400ms title rise plays during the 300ms route slide; P8 the reduced-motion toggle is honoured by the thumb mid-visit but not by the `TabBarView` pages, which also keep `Curves.ease` vs the thumb's `emphasizedDecelerate`; P9 three disagreeing segmented-thumb motions app-wide; P10 inconsistent empty/error language vs cart/checkout/coupons-sheet; P11 no haptic on back or the rule-sheet ✕; P12 skeleton flash with no delay for data that is already local and near-instant; P13 badge/tab-bubble pops mostly hidden under their own parents' fade-in; P14 "Use" pops the shell route and feels like "Back," landing on the origin tab not Home [inference]; P15 nested `PressScale` on card+pill can both scale on one held press [verify] (`my_coupons_content.dart` §5 Problems 1-15).
- **Perf risk:** each tab pill rebuilds `PressScale`+`FittedBox`+`Text`+colour-lerp on every frame of a swipe; the moving thumb carries a shadow with no `RepaintBoundary`; `GlowPulse`'s `Opacity`+`Transform.scale` rebuilds every frame forever inside a blurred-shadow card; `CountUpText` defeats the ticket's own `RepaintBoundary` for 700ms per available card, ≈3-4 at once on open and again on every remount; `LightSweep` double-clips and keeps sweeping for cards inside the list's cache extent while off-screen (`coupons_tab_pill.dart:33`, `glow_pulse.dart:78-91`, `coupon_card.dart:55-62`).
- **Opportunity:** drop count-up-from-0 on "Save up to" and the stub amounts, roll from the real value on a real change only (D13, D20; R08-27/28 — same root cause as B1-15's delivery-code fix and Rewards' own count-up problem, one pattern app-wide); cap+gate the badge glow and empty-tab float with ambientBudget+OnScreen (D14, D19; matches B1-02); stop entrance replay on tab revisit/scroll-back via keep-alive or a "seen" set (D17; matches B1-08's exact root cause); tokenise the 60ms/30ms raw steps onto staggerStep 30 and fix the `sheen`-vs-`shineSweep` mismatch (D2/D3; CC-23 wrong-token-use family); route the `TabBarView` pages' duration through the same mid-visit reduced-motion check the thumb already uses (CC-24 four-reduced-motion-idioms family).
- **Assets:** illustrated empty states per tab are today a Material glyph in a gradient disc; error illustration generic; branded coupon glyphs (`checkoutTicket`/`VoucherDisc`) exist but unused here; summary card has no rewards/savings hero art beyond a code-drawn glow.

---

### 25. Home — `lib/src/features/home/presentation/pages/home_page.dart`
- **Entry/exit:** shell tab 0; `Routes.shell` from splash uses `HeroFadeThroughPage` (fade+zoom 0.96→1); `Routes.shell`/`Routes.home` otherwise use `HeroTransitionPage` slide-up; tab switch in/out of Home is an instant `IndexedStack` cut; any push leaves Home static underneath (`shell_routes.dart:60-78`).
- **Motion:** 48 items H1-H48 — header collapse, scroll-linked (H1); rotating search hint, raw 80ms/letter (H2); bell press/unread pop/ring (H3-H5); assistant disc (H6); ETA/Pro-badge pops (H7/H8); delivery-line/search-pill press (H9/H10); the launch cascade `HomeReveal`, its own raw 70ms beat + 700ms clock (H11-H13); waving hand, raw 1200ms (H14); day-part disc `HomeLoop` (H15); announcement ticker/dots (H16-H18); banner auto-advance+parallax+neighbour-scale (H19-H21); category shelf auto-glide, raw `Curves.linear`/26px-s + aurora wash forever (H22/H23) + column-pop entrance (H24); press family (H25/H26); occasion float (H27); campaign-arrow/deadline-tag loops (H28/H29); promo/Pro-banner sweep (H30); countdown `FlipValue` (H31); add choreography — flight+"+1"+bump+confetti (H32/H33); shelf add-control swap (H34); quick-look sheet (H35); Pro-slot fade-through (H36); min-order bar rise/sink (H37) + bag pop+wiggle (H38); marketing popups, linear-fade dialog with an ungated inter-popup gap (H39); pull-refresh (H40); back-to-top (H41); skeleton (H42); state plates (H43); stale pill (H44); image fade ungated (H45); nested card+button press (H46); popup picture fade lands after the dialog settles (H47); "Save" badge static here vs pop-in on shop listings (H48) (`home_page.dart` full table).
- **State-change:** skeleton→feed is a hard `switch` with no switcher, and the **header remounts on every loading↔loaded↔error swap** because each bucket is a different widget type with its own `HomeHeaderSliver`, so the ETA pill/Pro badge pop a second time, the bell re-rings and the search hint restarts at step 0 [verify], the same replay happens on every language switch; the min-order bar rises 400ms when `/v1/init` lands after the feed and shrinks the viewport mid-cascade [verify ordering]; empty drops the header entirely (loading/error keep it); error/offline (nothing saved) is `FailureView`'s checking→offline/`ErrorView`, instant swaps between them; the stale pill fades in and shifts the feed down with no size ease; failed refresh over data is a snack; success/first-add stacks H32+H33+success haptic+H37's collapse on one tap; an ended deal countdown freezes at 00:00:00 while the deadline tag keeps heartbeating (Offers instead hides its chip); quick-look "View details" pops the sheet and pushes the PDP in the same call, so the sheet's 250ms fall and PDP's 300ms rise run together [verify]; no signed-out state (public feed); **confirmed** — no basket bar when the cart has items (`show = isEmpty && minOrderKd>0`) (`home_body.dart:71-92`, `home_cart_bar.dart:30`).
- **Gestures:** pull-to-refresh with no `edgeOffset` under the pinned header [verify] and dead on the non-scrollable empty state [verify]; horizontal swipes (banners/rails/shelf, touch stops the glide); long-press a card→quick-look; tap greeting→wave; no swipe-to-dismiss on popups; back is root-tab only.
- **Haptics:** tap on delivery line/search pill/greeting/quick-look long-press/quick-look "−"/every default `PressScale`; selection on banner-drag/pull-arm/quick-look "+"; success on first add; **direct `HapticFeedback`** on every later add (selectionClick) and remove (lightImpact), bypassing the `Haptics.enabled` mute; `AppButton` self-ticks on the popup CTA/empty-state refresh/offline retry; none on product/recipe-card open, promo-band/campaign-header body, popup close, min-order info button, quick-look "View details," error-view retry.
- **Problems:** P1 loops run while Home sits behind another shell tab because `IndexedStack` does not mute tickers and `HomeReveal.onScreen`'s geometry stays true for a hidden laid-out tab; P2 12 independent ambient loops on one screen with no user control; P3 first-add stacks 5 motions+a haptic on one tap; P4 steppers have no press feedback and the count snaps, each "+" re-runs the whole add choreography, tile haptics bypass the mute; P5 the same add gesture gets two different treatments (rail flight+confetti vs quick-look pop-only); P6 long-press gives the same light haptic as a tap; P7 skeleton→feed is a hard cut then a blank beat before the post-frame-measured cascade starts; P8 the launch cascade makes the first screen wait ≈1s on a raw 70ms beat vs the 30ms token; P9 entrances replay on scroll-back because the lazy sliver disposes blocks with no keep-alive [verify]; P10 the banner carousel visibly rewinds on wrap with no position indicator; P11 the empty state loses the header and cannot be pulled; P12 the pull disc sits under a pinned sliver header with no `edgeOffset`; P13 tappable bands (promo strip, campaign header) have no press feedback while sibling cards tick; P14 popups use a 250ms linear-fade dialog instead of the documented but unused `AppMotion.popup` 350ms token, the close "×" has no press state/haptic, a URL CTA closes the popup and does nothing, the inter-popup delay ignores reduced motion; P15 the stale pill height-snaps the feed; P16 the unread dot pops in but exits by snapping, and the bell only rings on the false→true edge so a second new notification is silent; P17 raw motion values everywhere (70ms beat, 1200ms wave, 80ms/letter, linear/26px-s glide, FlyToCart 120px/0.7) plus three near-duplicate primitives (`HomeReveal`≈`ScrollReveal`, `HomeCountdownText`≈`SecondClock`, `HomePressable`≈`PressScale`); P18 reduced-motion gaps on image fade, banner scale/parallax during a manual swipe, and the announcement ticker (screen-reader only, not reduced motion); P19 two independent search entries animate differently (header pill push vs instant tab); P20 two independent assistant entries animate independently on one screen; P21 delivery-place change snaps with no cue; P22 header entrance plays twice (loading→loaded swap, not a real change); P23 three unsynchronised 3s rhythms (hint/ticker/banners) drift against each other despite a shared-rhythm doc comment; P24 tokens borrowed from unrelated meanings (`drawOn` for reveal/bell/burst, `sheen` fractions for every `HomeLoop`, `glowPulse` for the aisle wash), so retuning one purpose silently retimes Home; P25 the countdown keeps its 1s timer for the block's life even scrolled away; P26 nested press on card controls stacks three scale motions on one tap; P27 an ended deal keeps its urgency cues; P28 a popup can land visually empty before its 500ms picture fade catches up to the 250ms dialog entrance; P29 the "Save" badge animates on shop listings but is static on the identical Home card (`home_page.dart` §1 Problems 1-29).
- **Perf risk:** H23's aurora wash repaints every built category tile every frame forever, H22 relayouts/recomposites the shelf's scroll offset every frame per leg, H27 is one continuous controller per occasion tile — all three keep running on hidden shell tabs; opacity widgets per scroll frame in the pinned header and per flight frame in `FlyToCart`; clip on moving content (banner parallax, hint/ticker `ClipRect`); every built `HomeReveal` adds a post-frame callback+`localToGlobal` per scroll tick; `HomeHeroDelegate.shouldRebuild` is always true on any header-sliver rebuild because it compares closures that are new every build, even on an unrelated feed refresh; the bottom-bar `SizeTransition` relayouts the feed viewport for 400ms during the flight+confetti; carousel/ticker/hint/countdown Timers are not lifecycle-aware [inference] (`home_page.dart` §1 Perf risk).
- **Opportunity:** gate every ambient loop (H2/H15/H16/H19/H22/H23/H27-H31/H38) with `AmbientLoop`+`OnScreen`+ambientBudget, including muting hidden shell tabs at the framework level (D14, D19; matches B1-02's exact root cause, the single biggest instance of it in the app); collapse the three near-duplicate primitives onto the core ones (`HomeReveal`→`EntranceCascade`, `HomeCountdownText`→`SecondClock`, `HomePressable`→`PressScale`) and tokenise the raw 70ms/1200ms/80ms/26px-s values (D2/D3, D14; CC-02/CC-03/CC-04/CC-10/CC-11 — five duplicate-primitive families land on this one screen); stop cascade replay on scroll-back with a keep-alive or "seen" set (D17; matches B1-08's root cause); fix the header-remount-on-bucket-swap so one-shot arrival cues fire once per real change, not per state swap (n/a architecture, extends D20's "never fake a change" rule); route the direct `HapticFeedback` calls through `Haptics.*` (D21; CC-19 "add-to-cart duplicated across 7+ sites" family); reserve confetti+full choreography for the genuinely first add, consider a lighter cue on every later "+" (R08-32, R07-29 "avoid motion on frequent taps"); give the popup queue a token-based entrance and honour reduced motion on the inter-popup delay (CC-23 wrong-token-use family); fix the pull-to-refresh `edgeOffset`+empty-state scrollability to match Offers (n/a mechanical, same-app precedent already shipped).
- **Assets:** empty storefront is a bare Material icon needing an illustration; offline/error/checking plates need the shared illustration set; the day-part disc is four Material glyphs for the hero "hello" moment; min-order bag uses Material `shopping_bag_outlined` though branded cart PNGs exist; ETA pill uses Material `rocket_launch` though a rider glyph exists; Pro banners use Material `workspace_premium` with no crown mark; assistant header disc uses Material `auto_awesome` though a painted mascot exists; category-less tiles fall back to a generic Material glyph; occasion tiles/announcement discs map to 28 Material glyphs though the occasion tile "is" the artwork; the greeting hand is a Material glyph; first-add celebration has no "added" glyph beyond code confetti.

---

### 26. Search — `lib/src/features/search/presentation/pages/search_page.dart`
- **Entry/exit:** shell tab 1 is an instant `IndexedStack` cut; `Routes.search` (from the Home pill/Offers bar) is a separate `HeroTransitionPage` slide-up with its own cubit and a `RoundBackButton` only in this mode; autofocus races the 300ms slide-up in route mode [verify], and cannot take focus in tab mode under `ExcludeFocus` [verify]; commit pushes `ProductListingPage` and unfocuses in the same frame (`shell_routes.dart:80-87`, `search_body.dart:46-47`).
- **Motion:** S1-S11 — discover↔suggestions `FadeThroughSwitcher` (S1); clear "×" fade (S2); recent-chip/category/brand press (S3-S5); row/see-all/refine ink only (S6); the CLAUDE.md-sanctioned 2dp indeterminate bar (S7); 3-bone skeleton (S8); back-button press (S9); thumbnail fade ungated (S10); keyboard-dismiss-on-drag (S11) (`search_body.dart` table).
- **State-change:** discover first load has **no loader/skeleton at all** — the body is blank white until the device copy or server answers, and categories/brands land as two separate jumps; a failure while typing or on discover is only logged, no error/offline/empty view, no stale note anywhere in the tree; no-matches and a server error both end as `suggestions=[]`, so a genuine "no matches" message never shows; recents removal is instant with no exit motion; typing keeps old rows+progress bar and swaps keyed rows with no list animation.
- **Gestures:** drag dismisses the keyboard; horizontal brand rail; no pull-to-refresh (reconnect-only refresh); back is `RoundBackButton`/system in route mode, no predictive preview; no long-press to delete a single recent term.
- **Haptics:** selection on recent chips; tap (`PressScale` default) on category/brand tiles; none on suggestion rows, term rows, see-all, refine arrow, clear "×", keyboard submit, back button, or the recents "Clear" link.
- **Problems:** P1 the same screen has two entry motions — instant tab swap vs slide-up route with its own cubit; P2 blank discover on first load and on failure with zero feedback; P3 a two-step layout jump as categories then brands arrive; P4 no "no matches" state, a server error looks identical to zero matches; P5 mixed press language — chips/tiles scale+tick, rows only ripple; P6 the 2dp bar is a sanctioned exception per CLAUDE.md §3, kept as fact only, not a problem; P7 suggestion rows swap instantly on every reply; P8 clearing recents has no undo or exit motion; P9 keyboard rise/fall races the 300ms slide-up/results-push [verify]; P10 the identical "category tile" concept animates richly on Home (aurora+pop+press) and flat on Search; P11 no stale note on cached discover blocks unlike every sibling screen; P12 image fade ungated (`search_body.dart` §2 Problems 1-12).
- **Perf risk:** `BlocBuilder` with no `buildWhen` rebuilds the whole body switcher on every keystroke and every reply; both subtrees are laid out+painted together during the 300ms fade-through; non-lazy `ListView(children:)` for discover/suggestions, fine at current sizes [inference]; no loops, nothing runs offscreen.
- **Opportunity:** give discover a real loading/empty/error/offline state through `FailureView`+skeleton instead of a blank body (CLAUDE.md §3.2, D18; matches B1-04's root cause); unify the tab-vs-route entry into one motion (n/a architecture, needs a product decision first, flag for approval); add a stale note to match Home/Offers/Content/Notifications (D18 pattern, no new token); give Search's category tile the same entrance/press language as Home's, or document why they diverge (D14, D22; R08-02 press-state parity).
- **Assets:** no "no matches for …" illustration; no discover empty/first-run/offline art (blank body today); "search needs a connection" is an inline Material wifi glyph only; image-less categories/brands fall back to a first-letter tile with no placeholder art.

---

### 27. Content (CMS page) — `lib/src/features/marketing/presentation/pages/content_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop, pushed from Settings/About/login-terms/checkout-info/Pro trust line; Material `AppBar` default back with ripple only; no swipe/predictive back (`marketing_routes.dart:22-35`).
- **Motion:** C1-C7 — route slide (C1); loader disc after `loaderDelay` (C2); checking→offline/error plate (C3); empty icon pop (C4); stale-pill fade (C5); back ripple (C6); long-press text selection handles (C7).
- **State-change:** loader→text and the fallback-key→CMS title are both hard cuts; error/offline/checking swap instantly; stale pill fades in, height snaps; a language switch reloads with the page kept on screen (no full re-show unless nothing was already showing); no signed-out/success states.
- **Gestures:** vertical scroll; long-press text selection; back button/system; no pull-to-refresh (reconnect-only); no back-to-top on long legal text.
- **Haptics:** none of its own — the shared state views decide (offline-plate retry ticks, error "Retry" is silent, back is a plain Material ripple).
- **Problems:** P1 no pull-to-refresh unlike every other cached screen in this set; P2 loader→text and fallback→CMS title are both hard cuts; P3 back affordance is Material `AppBar` here and on Notifications vs `RoundBackButton`/`RoundOutlinedButton` everywhere else; P4 a reading page reached as a flow step (About→Terms, Login→Terms) slides up full-screen instead of the shared-axis type its own sibling routes reserve for "a step inside a flow"; P5 stale-pill height snap (`content_page.dart` §3 Problems 1-5).
- **Perf risk:** minimal — no loops, loader ticker only while loading; a long `SelectableText` lays out the whole body in one non-lazy frame, possibly during the route's last frames [inference].
- **Opportunity:** add pull-to-refresh to match Home/Offers/Notifications (n/a mechanical, matches the cached-screen pattern already shipped); route content reached as a flow step through `HeroSharedAxisPage` per its own documented purpose (D8/D9; same CC-13 page-type-drift family as §23/§34's fix); unify the back control to `RoundBackButton`/`PressScale` (D22).
- **Assets:** empty state is a bare Material `article_outlined`; no per-kind header art (About/Contact/FAQ/Privacy/Terms are a plain text wall); offline/error illustrations shared-need with every other screen.

---

### 28. Offers — `lib/src/features/marketing/presentation/pages/offers_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop, pushed only from the assistant's offers card; back is a `RoundOutlinedButton` in the pinned bar; no swipe/predictive back (`marketing_routes.dart:12-19`).
- **Motion:** O1-O13 — route slide (O1); scroll-linked top-bar tint (O2); hero heading/subtitle rise (O3); 🔥 wiggle raw 900ms (O4); back/search press (O5); skeleton shimmer (O6); first-frame `StaggerEntrance` cascade raw 30ms capped 6 (O7); countdown chip ticks with no flip (O8); "View cart" pill rise/sink (O9) + press/count-pop/roll (O10); pull-refresh with correct `edgeOffset` (O11); back-to-top (O12); shared state plates (O13).
- **State-change:** skeleton→loaded is a one-frame swap then O7's cascade on first-frame cards only, cards added later (scroll/refresh) intentionally get no entrance; empty/error use the shared plates; stale note height-snaps; refresh failure is a snack; an offer ending only drops its countdown chip and the card keeps looking active; **the pinned bar and hero never remount across loading/error/empty/loaded** because all four swap only the content sliver inside one `CustomScrollView` — the one screen in this set that gets this right, unlike Home's header-remount bug; the cascade hand-off re-creates each first-frame card's element (same key, different widget type) when the cascade timer ends, restarting its `CountdownChip` timer though nothing visible changes [inference].
- **Gestures:** pull-to-refresh, vertical scroll, back-to-top, tap 🔥, back/search buttons, system back (no swipe/predictive); offer cards are deliberately not tappable, no press state.
- **Haptics:** `PressScale` default tap on back/search/view-cart/back-to-top; tap on 🔥; selection on pull-arm.
- **Problems:** P1 countdowns animate three different ways across Offers/Home/the unused core `SecondClock`; P2 the stagger step is duplicated as a raw 30ms literal instead of the token; P3 the opening motion stacks — 300ms slide, then a 400ms hero rise, then the 🔥 wiggle at 400-1300ms, then the cascade, so the heading is only fully readable after the page has already arrived; P4 the "View cart" bar policy and timing differ from Home's own basket-bar rule — Offers shows the pill while Home explicitly hides it, and the bar takes 250ms here vs Home's 400ms for the same "rise from the bottom" idea; P5 skeleton→list is a hard cut before the cascade; P6 an ended offer only loses its chip and keeps looking active; P7 raw 900ms emoji wiggle (`offers_page.dart` §4 Problems 1-7).
- **Perf risk:** hero entrance animates through an `Opacity` widget for 400ms during the route transition; one `Timer.periodic`+`setState` per visible countdown chip, `TickerMode` checked only in `didChangeDependencies`; up to 6 `StaggerEntrance` controllers+timers at open, well-contained lazy sliver otherwise; app-bar tint rebuild is narrow.
- **Opportunity:** unify the countdown treatment with Home's `FlipValue` or route both through the unused core `SecondClock` (D13; one fix for both screens' countdown finding); tokenise the raw 30ms stagger step and 900ms wiggle onto D2/D3; sequence the opening motion — page, then hero, then cascade — instead of stacking three starts (D17; R09-25 exits-shorter/entrances-paced principle applied to entrances too); the "View cart" bar vs Home's "no basket bar" is a deliberate, evidence-respected difference per this task's own constraint — **leave that policy as is**, but align the two bars' rise duration to one token (D2/D3).
- **Assets:** reward-type Material glyphs duplicate SVGs the cart deal cards already ship (`offerDelivery`/`offerGift`/`offerVoucher`); no percentage/fixed-amount SVG; no "no offers right now" illustration; 🔥 emoji is the hero's only art, rendering per-platform; offline/error art shared-need.

---

### 29. Notifications — `lib/src/features/notifications/presentation/pages/notifications_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop, pushed from the Home bell and Mine menu; Material `AppBar` default back; signed-out "Log in" replaces the whole stack via `go(login)` onto a `HeroCrossFadePage`; no swipe/predictive back (`notifications_routes.dart:11-17`).
- **Motion:** N1-N11 — route slide (N1); loader disc (N2); pull-refresh on list+empty (N3); row ink only (N4); empty-inbox bell pop (N5); signed-out lock pop (N6); checking/offline/error plate (N7); stale pill (N8); load-more dots/retry (N9); "all read" Material snack (N10); mark-all icon colour snap (N11).
- **State-change:** loader→list is a hard cut, a saved inbox paints at once; unread→read on tap is optimistic and snaps title weight/colour/dot/caption in one frame; mark-all restyles every row at once + a snack; a **live SSE push prepends a row with no entrance at all** and pushes the list down with no scroll anchoring [inference] — the one event that rings the Home bell arrives silently here; the "Live" chip and its dot toggle with no transition; empty/signed-out/error/offline/stale/load-more-failed all swap instantly.
- **Gestures:** pull-to-refresh; tap a row (deep-links to tracking/support); back; no swipe actions (mark-read/delete), no long-press.
- **Haptics:** none of its own beyond the pull-arm selection; silent row tap, mark-all, load-more retry, error retry; the signed-out "Log in" and the offline-plate retry both tick (`AppButton`).
- **Problems:** P1 loading shows a disc, not the list skeleton Home/Offers/search use for a first list load; P2 read-state changes snap everywhere — row, caption, mark-all; P3 a live notification arrives with zero motion while Home rings its bell for the same event; P4 the "Live" indicator toggles statically; P5 signed-out uses a feature-local `EmptyStateView`+lock instead of the shared `HeroStateView.signedOut` checkout/orders use, different icon+label+pop behaviour; P6 rows are ripple-only with no press scale/haptic, same gap as Search; P7 back affordance is Material `AppBar` (same as Content) vs round back buttons elsewhere; P8 load-more retry is a bare Material `TextButton`; P9 a feature-local empty view duplicates `EmptyStateView`'s layout+pop instead of reusing it; P10 the Home bell dot vanishes with no exit once read here — cross-screen (`notifications_page.dart` §5 Problems 1-10).
- **Perf risk:** low — lazy `ListView.builder` with `findChildIndexCallback`, `buildWhen` on the body, cached `DateFormat`, no loops.
- **Opportunity:** give the live-push insert a short entrance (fade+rise, matching `EntranceCascade`'s single-item mode) instead of a silent prepend, and consider echoing Home's bell cue in-inbox too (D13; R08-30 "surface the latest update first," a status-tracker guidance applied to an inbox); adopt a skeleton for first load to match Home/Offers (D18); switch the signed-out view to the shared `HeroStateView.signedOut`+`FailureView` contract (CLAUDE.md §3.2, matches B1-04's root cause); give rows a `PressScale`+consistent haptic (D22).
- **Assets:** kind icons mix `HeroIcons` with Material across 11 kinds; no empty-inbox illustration; no signed-out illustration; offline/error art shared-need.

---

### 30. Order invoice — `lib/src/features/orders/presentation/pages/order_invoice_page.dart`
- **Entry/exit:** `HeroSharedAxisPage` from tracking (also shared-axis), so both legs play — tracking slides toward the start and fades while the invoice comes in from the end, mirrored in RTL (`orders_routes.dart:26-30`).
- **Motion:** 6 items — bucket fade-through (1); block loader disc (2); stale pill `Opacity`-only fade with the height snapping in and out (3); offline pop/checking dots with a hard cut between them (4); failure snack over a saved invoice (5); back-button dip+ripple (6).
- **State-change:** loading→loaded fades the disc through to the document; stale pushes the whole document down in one frame in both directions; error/signed-out are the shared plates; offline is a hard checking→offline cut; there are no user actions so no success state, a reconnect just updates the document in place.
- **Gestures:** scrolling only, **no pull-to-refresh** even though the stale pill says the data is old — the only refresh path is reconnect or Retry on an error; no share/download; back button/system, no predictive preview.
- **Haptics:** none anywhere on this screen, including the link that opened it.
- **Problems:** P1 a centred disc for a structured, top-aligned document vs the list's skeleton next door; P2 the stale note snaps the layout in and out with no gesture to clear it; P3 the invoice link gives no press feedback beyond a ripple; P4 reduced motion flashes the loader for at least one frame instead of skipping the wait; P5 checking→offline is a hard cut; P6 otherwise calm by design — nothing moves once loaded, no issue there (`order_invoice_page.dart` §3 Problems 1-6).
- **Perf risk:** low — a lazy sliver with a cached section for the lines, only ticking work is the loader dots while loading and a one-off 150ms stale-pill fade, nothing per-frame once loaded.
- **Opportunity:** size-transition the stale pill's insertion instead of snapping it in and out (D13 `SizeFadeSwitcher`/`CollapseReveal`; R10-22, same root cause as the Part-1 Wallet finding); fix the reduced-motion loader flash so `DelayedLoaderDisc` truly skips its wait when reduced (n/a core bug, shared identically with §31/§32/§33); smooth the checking→offline swap with a short cross-fade (n/a, matches `FailureView`'s own documented contract elsewhere).
- **Assets:** payment-method icons are text only though `checkout_cash.svg`/`checkout_wallet.svg` already exist; loyalty note uses Material `stars_rounded` instead of `checkout_points.svg`; no receipt-header brand mark; "paid" status is a coloured dot, not a glyph; error/offline/signed-out illustrations shared-need.

---

### 31. Order review — `lib/src/features/orders/presentation/pages/order_review_page.dart`
- **Entry/exit:** `HeroSharedAxisPage`, pushed from the orders list (`HeroTransitionPage`) or the shell (`HeroFadeThroughPage`/`HeroTransitionPage`) so the covering half is missing — a 90ms dead start; on success the page pops itself at once, a 250ms reverse (`orders_routes.dart:21-25`, `order_review_page.dart:32-36`).
- **Motion:** 11 items — bucket fade-through (1); block loader (2); per-star spring pop that cascades when several fill/empty at once via staggerStep30 intervals (3); star ink+tooltip (4); submit pill grey↔green (5); blocked-submit `BlockedTapShake` (6); busy scrim→done-check drawn over its last 65% (7); success snack+pop (8); thumbnail fade ungated (9); partial-failure snack (10); back press (11).
- **State-change:** rating plays the spring-pop/cascade above; submitting locks every tile with **no visual change at all** because the star icons carry explicit colours that make a disabled `IconButton` look identical to an enabled one; success fires `Haptics.success`+snack+`context.pop()` in the same listener call, so the shared-axis exit (fading over the first 70% of its 250ms reverse, ≈175ms) finishes before the busy overlay's held-back 105ms+400ms spring check could ever be seen — the class doc's own claim that "the check shows as the page closes" does not hold; partial failure is a snack only, stars/comment kept; error/offline/signed-out as the block loader's shared plates.
- **Gestures:** scrolling, keyboard dismisses on drag; tap stars, long-press shows a Material tooltip; back blocked while submitting, no predictive preview.
- **Haptics:** selection per star; warning on a blocked submit; tap on submit; success on done — **the most complete haptic set of these 23 screens.**
- **Problems:** P1 the success check is effectively invisible under a page that is already leaving, contradicting the class's own doc comment; P2 locked tiles give no cue at all during and after a submit — no per-product "sent" mark; P3 a star gets triple feedback (ink splash+spring pop+haptic), noted as a style question not a defect; P4 the thumbnail fade ignores reduced motion; P5 the shared-axis dead start on push from the list; P6 the orders-list "Review" pill stays stale afterward because nothing refreshes it — cross-screen with §33; P7 the submit label colour snaps grey→ink while the pill's fill animates over 150ms around it, minor; P8 reduced motion flashes the loader (`order_review_page.dart` §4 Problems 1-8).
- **Perf risk:** up to 40-50 idle `AnimationController`s allocated across the ≈8-10 built star-button tiles plus cache extent (5 per tile), cheap while idle; rebuild scope is well-contained per tile and per star button; the busy scrim covers the whole route during submit.
- **Opportunity:** hold the done-check visible for a beat before popping, or let the pop's own transition carry the check instead of racing it (n/a — a sequencing fix, no new token, directly contradicts the class's own documented intent so it is as much a correctness fix as a motion one); give a locked/sent tile an explicit "sent" mark instead of relying on identical-looking disabled colours (D13 `PopScale`/`FlipValue`-style check); fix the "Review pill stays stale" gap by refreshing the orders list on return from a review, same root cause as §33's problem (n/a architecture, cross-reference).
- **Assets:** stars are Material, not the HeroIcons stroke set; no thank-you/review-sent illustration beyond the toast; no per-product "sent" check glyph; product thumbnail placeholder is a generic Material image icon, not a brand doodle; no "already reviewed" state art (an empty `lines` just renders an empty list).

---

### 32. Order tracking — `lib/src/features/orders/presentation/pages/order_tracking_page.dart`
- **Entry/exit:** `HeroSharedAxisPage`; the covering half is missing from every non-shared-axis entry point (list, notification, assistant) — a 90ms dead start; from checkout, `pushReplacement` drops the checkout page with **no exit animation at all**, so the page under it (the now-emptied cart) shows during those 90ms while the confetti plays over it [device check] (`orders_routes.dart:16-19,33-44`, `checkout_page_listeners.dart:57-70`).
- **Motion:** 19 items — bucket fade-through (1); block loader (2); status headline fade-through keyed by status (3); "when" line `CollapseReveal`+fade-through **keyed by the changing ETA string itself** (4); the journey stepper sweeps on first mount after a 300ms hold then breathes 3× (5/6) but never on the last step, folds on cancellation (7); last-known/cancellation/picking/delivery notices `CollapseReveal` (8-11); cancel button folds (12); busy overlay (13); cancel sheet (14); cancelled snack (15); invoice link ripple (16); offline/checking hard cut (17); failure snack (18); back press (19).
- **State-change:** loading→loaded always routes through the fade-through because the order lands via stream after the first frame; a poll updates the body in place — headline cross-fades, the when-line cross-fades **on every ETA-number change** (violating the app's own "key by a status bucket, never by data that changes while shown" rule, and using a fade instead of the `RollingNumber`/flip checkout uses for the identical ETA-minutes value), notices open/fold, the stepper refills and breathes again; delivered is terminal with **no success moment and no haptic**; cancelled fires five motions at once (headline→red, when-line folds, stepper folds, cancellation notice opens, cancel button folds) plus a snack, with the busy overlay fading out on top; error/not-found offers a Retry on an order that no longer exists; error↔signed-out share one bucket so a swap between them is a rare hard cut; offline/stale shows a saved copy with the last-known pill.
- **Gestures:** scrolling only, **no pull-to-refresh** on a live screen though `refresh()` exists; no swipe/long-press; cancel sheet drag-dismiss; back blocked while cancelling, no predictive preview.
- **Haptics:** selection/tap in the cancel sheet; none on Cancel, a status change, delivered, cancel success, Retry, or the Invoice link; arrival from checkout still carries checkout's own success haptic.
- **Problems:** P1 the ETA fade-through is keyed by changing data against the app's own documented rule, and checkout shows the identical value with a flip instead; P2 no success moment or haptic on delivered; P3 no haptic or attention cue on any live status change, only a 300ms cross-fade; P4 five simultaneous reveal/fold motions plus a snack plus the overlay exit on cancel; P5 the step arrives late — a 300ms hold plus a 700ms sweep after the body lands before the current step is even drawn; P6 the sweep re-runs on every open, an open question against the app's own "no count-up on open" spirit; P7 a 90ms dead start on three of four entry paths, and a full drop with no exit at all from checkout; P8 loading pattern (a centred disc) differs from the list's skeleton next door; P9 no pull-to-refresh on a live screen; P10 destructive-confirm haptic is `tap`, no press scale on Cancel; P11 Retry is offered on a dead, not-found order; P12 reduced motion flashes the loader for at least one frame; P13 checking→offline and error↔signed-out are both hard cuts inside the error bucket (`order_tracking_page.dart` §2 Problems 1-13).
- **Perf risk:** the stepper is well-contained — `CustomPaint` inside a `RepaintBoundary`, bounded ticks; up to 5 `CollapseReveal` notices relay out the same sliver at once on cancel; the cancel sheet here is rebuilt fresh on every keyboard frame because the builder creates a new instance each time, unlike the list's own `CancelOrderSheet.show` which builds once; rebuild scope otherwise narrow and well-selected; offscreen tickers muted, polling stops via `RouteAware`+lifecycle.
- **Opportunity:** key the when-line and roll/flip the ETA value instead of fading on every change, matching checkout's own primitive for the identical data (D13 `RollingNumber`/`FlipValue`, D20's "key by bucket not data" rule made explicit; R02-19/R08-28 numeric-content-transition guidance, R05-16/R05-17 Live-Activity numeric-transition rules); give delivered a genuine, bounded success moment — check+haptic, no confetti overload — matching the significance Apple HIG reserves for completed tasks (R07-33, R08-23); sequence the five cancel motions instead of firing at once, or fold them into one state-swap primitive (D17 extended to state transitions; R05-17 "move elements, don't rebuild"); add a live-status haptic, and flag for approval whether Android 16 Live-Update/iOS Live-Activity-style progress framing suits delivery tracking given R01-32/R05-20/R05-21/R05-22 (a bigger product decision, not a token swap); fix the shared reduced-motion loader flash (n/a core bug).
- **Assets:** no per-stage status art for the header (placed/confirmed/picking/ready/out-for-delivery/delivered/cancelled are text only); no delivered/success illustration; stepper segments are unlabelled bars with no stage icons, only semantics text; the driver row uses Material `delivery_dining_outlined` though `HeroAssets.globalRider` exists and is used elsewhere; the destination card uses a generic Material pin though branded address-label icons exist; no order-not-found illustration; picking-change/cancellation icons are generic Material, off the HeroIcons stroke set.

---

### 33. Orders (list) — `lib/src/features/orders/presentation/pages/orders_page.dart`
- **Entry/exit:** as a route it is `HeroTransitionPage` slide-up/pop; embedded as the Cart tab's history view it sits in an `IndexedStack`, so switching between cart and history is an instant cut with only the switch pill animating (`shell_routes.dart:88-94`, `shell_basket_tab.dart:98-107`).
- **Motion:** 18 items — bucket `FadeThroughSwitcher` (1); skeleton shimmer (2); first-screen `EntranceCascade` capped 6 (3); card press 0.98 (4); card ink (5); card `AnimatedSize` on action change (6); status-tag fade-through (7); pull-refresh (8); load-more fade-through+dots (9); stale pill `Opacity`-only fade (10); nested busy overlays for cancel/reorder ≥500ms (11); cancel sheet (12); offline pop/checking dots (13); reorder snack (14); failure snack (15); cancel-sheet offline confirm snaps in one frame (16); back dip (17); sheet-✕ ripple (18).
- **State-change:** loading→loaded layers three entrances at once (route slide, fade-through-with-scale, and the first ≤6 cards' cascade — the first 105ms of which plays invisible under the fade-through); refresh updates cards in place with no insert motion for a new top order, the list just jumps; empty/error/signed-out are static plates; **checking→offline is a hard cut** because the verdict builder just rebuilds with the new state while the switcher's key stays `error`; the stale pill pushes the list down in one frame, and back up in one frame when it clears; a load-more failure offline swaps the footer height with no transition; cancel success is silent — no snack, no haptic — while tracking's own cancel does show a snack, cross-screen inconsistency; cancel failure gets a failure snack; reorder success is a busy overlay (≥500ms even for an instant reply) then a toast only, no cart-side motion.
- **Gestures:** pull-to-refresh on the list and the empty state; paging at scroll end; card tap opens tracking and refreshes on return; no swipe/long-press; back is `RoundBackButton`/system, blocked while either overlay is up, no predictive preview.
- **Haptics:** selection on pull-arm and per cancel-reason row; tap on the cancel-sheet confirm and the signed-out sign-in button; **none on a card tap, the action pills, or a cancel success**, and the destructive cancel confirm fires `tap` not `warning`.
- **Problems:** P1 a layered entrance stacks route+fade-through+cascade, the first 105ms of the cascade is invisible; P2 the card's `PressScale` is a passive listener around the whole card including its action pills, so pressing Cancel/Reorder shrinks the whole card and the pill itself gets no press scale of its own; P3 no haptic on a card tap, the action pills, or cancel success, and the destructive confirm fires `tap` not `warning`; P4 a reorder dims and locks the whole list, back included, for at least 500ms even when the cart answers at once; P5 cancel feedback disagrees between the list (silent) and tracking (a snack); P6 reorder feedback is only a toast while every other add-to-cart surface flies to the cart; P7 the stale note snaps the layout in both directions while tracking's own equivalent note animates via `CollapseReveal`; P8 the empty state is a dead end — a static icon with no action, and it enters differently from the offline view (static vs pop); P9 the embedded Cart-tab view hard-cuts between cart and history while only the pill above slides; P10 "Review" stays stale on the card after a review is sent because pushing over the shell does not flip the tab's `active` flag and nothing refreshes it — cross-screen with §31; P11 Material ripple and the SnackBar both ignore `MotionGuard`; P12 checking→offline is a hard cut; P13 the cancel-sheet offline confirm snaps its pill from red to grey with dots in one frame and the offline note is inserted with no size/fade motion, growing the sheet in one frame; P14 the load-more footer swaps height with no transition when a page fails offline (`orders_page.dart` §1 Problems 1-14).
- **Perf risk:** rebuild scope is good throughout — bucket-only page rebuilds, cached cards, per-flag selectors; the fade-through scales the whole list viewport for 300ms; `StaleAgePill` rebuilds an `Opacity` widget on each of its 150ms frames; the busy disc carries a shadow and springs during its animation; two nested `BusyOverlay`s each own a selector+`PopScope`+Stack; tickers stop in a hidden tab via an explicit `TickerMode` wrapper the SDK's `IndexedStack` does not provide itself.
- **Opportunity:** unify the cancel-success feedback with tracking's own snack, and give the reorder success a `FlyToCart` moment instead of a toast-only confirmation, matching every other add-to-cart surface in the app (D13 `FlyToCart`; R08-20 "persistent feedback beats transient fade-outs," R05-31/R05-33); fix the destructive-cancel-confirm haptic to `warning` (D21; R07-26, the same B1-family fix already scoped for Settings' log-out and Address-list delete — same root cause across the app); refresh the orders list (or at least the reviewed card) on return from a review so the stale pill and stale "Review" pill both clear (n/a architecture, cross-reference §31); size-transition the stale pill and the load-more footer instead of snapping (D13 `SizeFadeSwitcher`; R10-22, same wallet-family fix); give card action pills their own press scale independent of the passive card-wide one (D22).
- **Assets:** empty state is a grey Material receipt icon with no way forward; signed-out/offline/error plates are the shared generic Material icons; the status tag is text+colour only with no glyph per state; the two-line item preview has no product-thumbnail placeholder, so a card has no visual anchor; reorder-added has no glyph or cart cue beyond a toast.

---

### 34. Customer-service hub — `lib/src/features/support/presentation/pages/customer_service_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop; the page below is static; no RTL question, no predictive preview (`support_routes.dart:11-18`).
- **Motion:** 7 items — FAQ-row `StaggerEntrance` with a raw 30ms default step (1); row press 0.96 passive (2); row/hotline ink (3); the two `AppButton`s press+tick (4); hotline tap opens a "calling…" stand-in snack (5); shop-logo fade ungated (6); back `IconButton` ripple only, no press scale/haptic (7).
- **State-change:** the body **ignores `status`/`errorMessage` entirely** though the cubit emits both, so loading and error look identical — an empty FAQ card with only the hotline+chat button showing; the recent-order card **pops into the top of the list with no motion** once the offline source answers, pushing everything else down (likely hidden under the still-playing route transition today since the source is local, but will surface once the hub reads the live API) [device check].
- **Gestures:** scrolling and taps; the search field's → arrow is a bare `GestureDetector` with **no visual feedback at all**; back is a plain `IconButton`/system, no predictive preview.
- **Haptics:** tap on the two `AppButton`s only; none on the FAQ rows (passive `PressScale`), the hotline row, the search submit, or back.
- **Problems:** P1 missing loading/error feedback — the error state is entirely invisible; P2 the recent-order card snaps in above the content with a layout jump; P3 the entrance stagger is spent mostly under the 300ms route transition, not at rest until ≈400ms; P4 press depth (0.96) disagrees with orders' 0.98/0.97 convention, and the hotline row — a sibling of the same look — gets no press scale at all; P5 the search arrow gives zero feedback; P6 a forward flow (hub→topics→chat) uses the slide-up modal motion while orders uses shared-axis for its own forward steps; P7 back affordance is a plain `IconButton` here vs `RoundBackButton` on orders; P8 the hotline tap only shows a "calling…" snack and does nothing, a broken promise; P9 the hub's two entry paths into topics both lose their context — a search submit's typed text never seeds the topics' own field, and "Get help with this order" passes an order id the topics page never matches, so both open unfiltered (`customer_service_page.dart` §5 Problems 1-9).
- **Perf risk:** negligible — the `BlocBuilder` has no `buildWhen` so the whole list rebuilds on each of the 2 emissions per open; each FAQ row allocates a Timer+controller that fire even when the route is covered, harmless; no loops.
- **Opportunity:** wire the existing `status`/`errorMessage` into a real loading/error view — a missing-state bug more than a motion gap, flag for the offline contract (CLAUDE.md §3.2, matches B1-04's root cause exactly); size-transition the recent-order card's insertion (D13 `CollapseReveal`, same family as every other "card appears late" finding in this set); give the search arrow and the hotline row a `PressScale` to match the rest of the hub (D22); switch the forward flow to `HeroSharedAxisPage` to match orders' own convention (D8/D9, CC-13 page-type-drift family, same fix as §23/§27).
- **Assets:** all 6 hub rows share one `HeroIcons.help` glyph though 8 distinct topics exist downstream; no hub header illustration; no loading skeleton or error/offline art at all; the recent-order card has no placeholder when the shop logo is missing.

---

### 35. Help topics (FAQ) — `lib/src/features/support/presentation/pages/customer_service_question_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop (`support_routes.dart:20-30`).
- **Motion:** 8 items — topic-card `StaggerEntrance` keyed by topic, replaying on any filter shift (1); header press 0.96 wrapping only the header row (2); `AnimatedAccordion` = `AnimatedSize`+`AnimatedOpacity` (3); chevron 180° rotation (4); no-results icon pop (5); the two `AppButton`s (6); header ink (7); back ripple (8).
- **State-change:** **no loading or error views** — the body ignores `status`/`errorMessage`; while loading, the empty match set renders "No results" (with its icon pop and chat CTA) until the offline data arrives, one frame at the very start of the route slide, so probably invisible [device check]; on an actual error it stays stuck on "No results," misreporting what happened; a pre-opened topic (arg from the hub) mounts already expanded because the listener runs before the builder, so it skips its own open animation and only joins the entrance stagger; each keystroke rebuilds the list — rows that no longer match vanish in one frame, but because the `ListView.builder` has keyed rows with **no `findChildIndexCallback`**, any row whose index moves is re-created and **the whole cascade replays for every row after the first shifted one**, not only new matches; collapsing blanks the answer text at the **start** of the 250ms shrink (unlike `CollapseReveal`, which keeps drawing the closing child); opening one topic closes the previous one, two `AnimatedSize`s at once.
- **Gestures:** scroll, tap a header, type; the keyboard **does not dismiss on scroll**; the clear ✕ is a bare `GestureDetector` that snaps with no feedback; back button/system, no predictive preview.
- **Haptics:** tap on the two `AppButton`s only; **none** on expand/collapse, clear, or typing.
- **Problems:** P1 the collapse blanks its content before folding, and the app runs two disagreeing expand/collapse primitives, `CollapseReveal` vs `AnimatedAccordion`; P2 the header scales inside a white card that itself stays put, because `PressScale` wraps only the inner row; P3 no loading or error state at all, "No results" misreports both; P4 the stagger replays on every filtering keystroke that shifts a row's index, contradicting the app's own "once per item" comment and the "no cascades on rebuild" rule; P5 filtering animates rows arriving but not rows leaving, inconsistent within one interaction; P6 the clear button snaps while Search's own clear button fades; P7 no haptic on the accordion toggle unlike the comparable `OptionRow` selection haptic elsewhere; P8 the filter itself runs inside `build` on every keystroke, a CLAUDE.md §7 business-logic-in-widget issue noted for the clean-code pass (`customer_service_question_page.dart` §6 Problems 1-8).
- **Perf risk:** `AnimatedSize` relays out the list every frame for 250ms, up to two regions at once; every tile listens to the shared `_expanded` notifier so a toggle rebuilds all 8, small; each keystroke re-runs `.tr()` twice per topic and re-creates every shifted row (new element+Timer+controller+`AnimatedSize` render object); no loops.
- **Opportunity:** fix the missing `findChildIndexCallback` so filtering does not re-create and re-stagger unaffected rows (n/a — a correctness fix that directly removes the replay problem, same root cause as B1-08's "stop cascades replaying"); collapse the two disclosure primitives onto one so an answer's text does not blank before the height shrinks (D13, CC-07 "show/hide by height+fade" duplication family); wire a real loading/error state (CLAUDE.md §3.2, same B1-04 gap as the hub); give the accordion toggle a selection haptic to match `OptionRow` (D21).
- **Assets:** no-results illustration is a grey help glyph in a circle; the same per-topic-icon gap as the hub; the "still need help" card is a glyph-in-circle, not an agent illustration; no loading-skeleton bones for the topic cards.

---

### 36. Rider chat (IM) — `lib/src/features/support/presentation/pages/im_chat_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop (`support_routes.dart:32-39`).
- **Motion:** 5 items — bubble `StaggerEntrance` keyed by absolute message index, raw 30ms step, capped so a 10th+ message waits 300ms before its own 250ms fade (1); post-send `ScrollController.animateTo` **through `MotionGuard.duration`, which is `Duration.zero` under reduced motion** (2); quick-reply chip press 0.96 passive (3); chip/send/camera/back/phone ink and `IconButton` ripples (4); "attach photo"/"calling…" stand-in snacks (5).
- **State-change:** open plays the 4 scripted bubbles staggered 0/30/60/90ms under the route slide; a send appends **both** the customer bubble and the scripted "Got it" reply **30ms apart**, with no typing indicator and no reply delay at all; the send button switches grey↔green with **no transition**; the app-bar title snaps from the hardcoded English fallback "Rider" to the resolved name when it loads, probably hidden under the transition today [device check]; no loading/error/offline/empty states exist — the thread is entirely local/scripted.
- **Gestures:** scroll the thread, scroll the chips sideways, tap, type, keyboard "send"; the keyboard **does not dismiss on scroll** and the thread **is not anchored to the bottom** when the keyboard opens, so the latest messages fall below the shrunk viewport until the next send; no long-press (no copy); back is a plain `IconButton`/system, no predictive preview.
- **Haptics:** **none anywhere** — send, quick replies, attach, call, back are all silent.
- **Problems:** P1 **reduced motion can throw** — `_jumpToEnd` calls `animateTo` with a MotionGuard-zeroed duration, and Flutter's `DrivenScrollActivity` asserts duration > 0 when the target is not already reached, a real crash risk with OS-level "remove animations" on, matched by the clean-code pass's own CC-01 finding for this exact site; P2 the scripted reply lands 30ms after the customer's own bubble with no typing/"rider is typing" state at all; P3 a message can wait 300ms plus 250ms of fade once the thread passes 10 messages, and this **replays on scroll-back** through the recycled `ListView.builder`; P4 no haptics anywhere and the send button colour snaps, while the assistant's own chat animates its send button's colour+icon; P5 every bubble's entrance direction ignores the sender — the assistant chat's own entrance follows reading direction while recycled rows mount at rest, this screen has neither; P6 keyboard handling — the thread does not follow the keyboard and does not dismiss on drag; P7 the title snaps from an untranslated English fallback to the real name; P8 attach/call promise a snack and then do nothing — this is a stub screen end to end, the whole thread is scripted (`im_chat_page.dart` §7 Problems 1-8).
- **Perf risk:** a send `setState`s the whole `ImChatBody`, rebuilding visible bubbles+chips+composer, small; the send button rebuilds on every keystroke via a `ValueListenableBuilder`; each bubble carries a `RepaintBoundary`+`Timer`+controller; the keyboard resizes the Scaffold so the list relayouts every keyboard frame; no loops.
- **Opportunity:** **fix the reduced-motion crash risk first** — branch to `jumpTo` when `MotionGuard.reduced`, mirroring the correct pattern already used at `pdp_loaded_view.dart:82-86` and four other sites (CC-01, this is the review's own flagged real bug, a correctness fix ahead of any styling); give the scripted rider reply a brief typing indicator before "Got it" lands, and route send/quick-reply/attach/call through `Haptics.*` (D21; R06-33's "blinking caret as the loader" is the closest evidence-backed shape for a lightweight typing cue); align the entrance direction and send-button motion with the assistant's own `AssistantEntrance`/`assistant_send_button.dart` so the app's two chat surfaces read as one family (D13, CC-32 "god animation widgets in the assistant buddy" family — extending its motion vocabulary here is the same fix in spirit); anchor the thread to the keyboard (n/a mechanical fix).
- **Assets:** the rider avatar is a grey `HeroIcons.delivery` circle though `HeroAssets.globalRider` exists and is unused here; no typing-indicator asset/motion at all; no message-status ticks (sent/delivered/read) under customer bubbles, only the time; no system-event row glyph (a "rider picked up your order" moment renders as a normal scripted bubble); no chat-start/empty-thread illustration for a future real thread; no attachment placeholder/thumbnail frame.

---

### 37. PDP image viewer — `lib/src/features/product_details/presentation/pages/pdp_image_viewer_page.dart`
- **Entry/exit:** `HeroSlideUpTransitionPage` 300/250ms signature both legs, plus **the app's only shared-element `Hero`** flying the tapped photo gallery↔viewer (turned off under reduced motion via `HeroMode`); on pop the gallery jumps to the left page synchronously before the reverse flight's post-frame start looks for its target, so it should land correctly — still worth a device check (`product_details_routes.dart:31-46`, `pdp_photo.dart:29-43`, `pdp_gallery.dart:65-67`).
- **Motion:** 11 items — route slide+fade (1); the Hero flight (2); pager swipe with the dot easing between positions (3); thumbnail-tap jump via `animateToPage` (4); thumbnail strip auto-scroll to the current thumb (5); selected-ring `AnimatedContainer` (6); thumbnail press 0.96 (7); double-tap zoom glide (8); pinch/pan `InteractiveViewer` (9); close-button press 0.92 (10); photo fade-in ungated (11).
- **State-change:** none of its own — no cubit, a not-yet-loaded photo shows the grey placeholder then fades in over 500ms.
- **Gestures:** horizontal swipe between photos, pinch, double-tap zoom, tap a thumbnail (pager locks while zoomed); back is `PopScope(canPop:false)` routed to a custom close, which **turns off the Android predictive-back preview** on this route entirely and there is no iOS edge swipe (route type); **no drag-to-dismiss** on a full-screen photo viewer and no long-press.
- **Haptics:** selection on a thumbnail tap; tap on close (`PressScale` default); nothing on double-tap zoom or at the zoom limits.
- **Problems:** P1 back is button/system only — `PopScope(canPop:false)` blocks the predictive-back preview and the route type has no iOS edge swipe; P2 no drag-to-dismiss on a full-screen photo viewer, a missing gesture with no downward exit feedback; P3 the photo flies from its gallery rect via `Hero` while the rest of the viewer independently slides up 100% and fades — two motions in different directions at once, whether this reads well cannot be judged statically; P4 the image fade-in is ungated for reduced motion; P5 the close glyph is Material `close_rounded` though `HeroIcons.close` already exists and is used elsewhere; P6 a far thumbnail jump lights every in-between thumb on the way because `onPageChanged` fires per page passed, low severity (`pdp_image_viewer_page.dart` §1 Problems 1-6).
- **Perf risk:** low overall — the dots repaint from the controller with no rebuild; `setState` runs only at the rounded page change, not per tick; the zoom glide writes to the `TransformationController` with no `setState`; raster is one `FadeTransition` over the full-bleed page plus the `Hero` shuttle compositing above it; no always-running tickers.
- **Opportunity:** add drag-down-to-dismiss to match the "full-screen presentation" pattern research points to for photo viewers (R09-05 "vertical equals modal," R09-06 "hero/zoom continuity: the tapped item can be dragged back" — this screen already has the Hero half of that story, just not the drag-back half; flag for approval since it changes an interaction, not just a token); swap in `HeroIcons.close` for wiring-only consistency (D13, no new asset needed); leave the flight-vs-slide direction question open pending a device check, as the audit itself does.
- **Assets:** no branded photo placeholder for the pre-load moment — today a flat grey `ColoredBox`; no first-use hint for "double-tap/pinch to zoom," the only hint is the zoom itself.

---

### 38. Product detail (PDP) — `lib/src/features/product_details/presentation/pages/product_detail_page.dart`
- **Entry/exit:** `HeroSlideUpTransitionPage` 300/250ms signature both legs; no shared element from the tapped card itself (only gallery↔viewer has one); the tapped card's preview paints in the same frame while the detail loads (`product_details_routes.dart:17-29`, `pdp_body.dart:71-89`).
- **Motion:** 25 items — route slide (1); gallery swipe+dots (2); photo flight (3); gallery 0.4 parallax lag under the sheet (4); scroll-linked top-bar fade+title rise (5) with a **snapping** shadow toggle (6); back/cart press (7); cart badge pops on change **and on every mount** (8); block `StaggerEntrance` cascade raw 30ms up to 7 blocks (9); description more/less `AnimatedSize` (10); offer note+promo-tag pop (11); size-card press+edge thicken (12); rating-tap scroll (13); rail tiles — card sink+add-morph+fly-to-cart from the tile centre, not the photo or the "+" (14); buy-bar CTA press+morph label (15); "Added ✓" tick pop (16); bar-stepper count roll (17); bar-stepper press (18); bar price — digits roll+marker draws on+"Save N%" pops **also on mount**+block eases height (19); fly-to-cart arc to the top-bar cart (20); loaders (21); not-found/error/offline pops (22); stale pill (23); photo/rail fade ungated (24); rail "+" sinks **inside** the already-sinking card (25) (`product_detail_page.dart` table).
- **State-change:** the loading preview paints the tapped card with an undelayed inline dots loader; loading→loaded swaps two different widget types in the same slot, so the scroll offset resets to 0 and the top-bar notifiers are recreated (the gallery alone survives via a page-level `GlobalKey`) — the class doc's "nothing jumps when the detail arrives" holds for the gallery, not for a scroll made during load; then the block cascade plays and the **buy bar snaps in from `SizedBox.shrink()`**, shrinking the viewport in the same frame — inconsistent with Pro's own bottom bar, which slides up over 400ms; a variant tap re-rolls the price/marker/Save-pop/height but the stock note **snaps** in or out and moves everything below it; a preview-only error shows "Checking…"→offline/`ErrorView` with no transition; a bare error with no preview shows a back-button-less `FailureView`, but it is unreachable today — no caller uses the bare constructor; reviews (loader→list→empty/error/"show more") snap at every step; success morphs the CTA to "Added ✓" for a **raw 1200ms hold that blocks further taps**, then to the stepper, while the thumbnail flies and the badge pops.
- **Gestures:** gallery swipe (RTL-aware, dots mirror), gallery tap→viewer, vertical scroll with platform bounce, horizontal rails; **no pull-to-refresh, no long-press, no iOS edge swipe/Android predictive-back preview, no drag-to-dismiss** despite the route's own doc calling PDP a full-screen "presentation."
- **Haptics:** tap on bar-add (the CTA's own `PressScale` is haptic-null); selection on the bar stepper, rail add, size card, more/less; tap on rail remove; tap on round back/cart buttons; **no `Haptics.success` anywhere on the add path.**
- **Problems:** P1 the "Added" hold blocks input for a raw 1200ms — a customer wanting 2 pieces waits over a second; P2 the buy bar snaps in when the detail lands, inconsistent with Pro's 400ms slide; P3 preview→loaded resets the scroll frame though the gallery itself is protected by its `GlobalKey`, low severity; P4 the top-bar badge pops at t=0 while the thumbnail lands ≈400ms later, contradicting `FlyToCart`'s own doc that the badge should pop on landing, and it also pops on every page open whenever the cart is non-empty; P5 the block cascade plays mostly unseen — no wait for the route to settle, and runs for blocks far below the fold in a non-lazy sheet; P6 several snaps — the top-bar shadow, the stale note (which also shifts content), every reviews transition, the stock note on a variant tap; P7 inconsistent haptics for the identical action — add is `tap` in the bar and `selection` in a rail, remove is `tap` in a rail and `selection` (the −) in the bar; P8 several tappables have no press feedback at all — link/brand/bundle/rating rows, the recipes rail cards, the rail steppers' −/+; P9 no back gesture on a full-screen page; P10 image fade ungated; P11 the close/back glyph is Material instead of `HeroIcons.back`; P12 raw motion values — `StaggerEntrance`'s 30ms/0.08 defaults, FlyToCart's −120/0.7/56; P13 the inline dots loader shows at once with no `loaderDelay`, so a fast network answer flashes the dots; P14 many motions fire for one add — CTA morph+tick+flight+badge, and a variant tap adds four more, flagged for Phase 1 judgment rather than as an outright defect; P15 two steppers on one page behave differently — the bar stepper rolls+sinks, the rail steppers are static+bare `GestureDetector`s; P16 the "+" at the stock limit is fully silent with no blocked-tap feedback though `BlockedTapShake` exists and is used elsewhere in the app (`product_detail_page.dart` §2 Problems 1-16).
- **Perf risk:** the whole `PdpLoadedView` including every block rebuilds on each variant tap (per tap, not per tick); scroll-linked work stays narrow (two `ValueListenableBuilder`s+one layer transform); an `Opacity` wraps the top-bar title every scroll frame in the fade band; the route `FadeTransition` covers the full-bleed gallery page; `FlyToCart`'s `Positioned` rebuilds every frame in the root overlay; `RollingGlyph` clips per glyph; offscreen tickers — the reviews block's inline dot loader keeps repeating off-screen in the non-lazy sheet, up to 7 one-shot `StaggerEntrance` controllers run for off-screen blocks, and the 700ms lime-marker controller runs on mount even with no active deal.
- **Opportunity:** shorten or remove the "Added" hold that blocks a second tap, letting the stepper appear sooner (R07-29 "avoid motion on frequent interactions," R08-07 "high-frequency actions get no animation"); slide the buy bar in like Pro's own bar instead of snapping (D2/D3, matches the cross-screen "sticky bottom bar entrance" inconsistency already flagged against Pro in §41); fix the badge-pops-on-every-mount and badge-pops-before-the-flight-lands bugs so the badge behaves as `FlyToCart`'s own doc promises (n/a correctness, direct contradiction of the primitive's documented contract); add `BlockedTapShake` to the stock-limit "+" (D13, matches cart's `cart_checkout_bar.dart:126` and order review's `review_submit_bar.dart:30` — same primitive, just unused here); give the rail steppers the same `RollingNumber`+press-scale treatment as the bar stepper, one stepper family app-wide (D13, D14 — matches the identical `CatalogPillStepper` static-count finding across §19/§25/§39/etc., one cross-cutting candidate); unify the add haptic to one kind across bar/rail (D21).
- **Assets:** no not-found illustration beyond a 56dp Material glyph; no "no reviews yet" illustration; no reviews offline/error glyph beyond a text row; no branded photo placeholder/shimmer for the gallery or rail cards, flat grey today; no "no photo" product placeholder beyond a Material icon; the added-to-cart check is Material, not a branded mark; low/out-of-stock notes use Material glyphs off the HeroIcons stroke set.

---

### 39. Recipe detail — `lib/src/features/recipes/presentation/pages/recipe_detail_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop; reached from the recipe list and the PDP recipes rail with slug only, no preview (`recipes_routes.dart:20-32`).
- **Motion:** 9 numbered items plus 2 unmarked snaps — route slide (1); loader disc (2); the collapsing `SliverAppBar` photo header, Material's own parallax+fade, **ungated by MotionGuard** (3); "Add all" press+tick (4); success snack (5); not-found pop (6); checking/offline/error plates (7); stale pill (8); header/ingredient photo fade ungated (9); plus an ingredient "+"↔stepper swap that is a **plain ternary with no motion at all**, and a static-text stepper quantity.
- **State-change:** loading shows a full-screen disc with **no preview of the tapped card, no skeleton, and no back button at all**; loaded content then **snaps** in with no fade or cascade; error is the same bare-no-back snap; not-found gets `EmptyStateView` with Back; stale snaps in and pushes content; success (add all) shows a snack while **every ingredient row flips to a stepper in the same frame with no motion and no fly-to-cart**.
- **Gestures:** vertical scroll with the collapsing header; no pull-to-refresh, no long-press; **back exists only as the loaded `SliverAppBar`'s Material `BackButton`** — loading and error states have no on-screen back at all, and with no iOS edge swipe (route type), an iOS user on the error screen has no way back except Retry.
- **Haptics:** **all direct `HapticFeedback`, bypassing `Haptics` and its mute** — selectionClick on "Add all" (**plus** a second `Haptics.tap` from the `AppButton` itself — two haptics for one press), selectionClick on an ingredient add, lightImpact on remove.
- **Problems:** P1 no way back while loading or on error, and iOS has no swipe-back either — a user can get trapped; P2 no preview during load unlike PDP, which does paint the tapped card; P3 ingredient add is a hard snap with no fly-to-cart, inconsistent with both the PDP rail's morph and the PDP bar's morph; P4 haptics bypass the system entirely and "Add all" double-fires with no success haptic on a bulk add; P5 "Add all" has no visual confirmation beyond the snack — no fly, no row feedback, no cart icon on this page to react to; P6 the collapsed bar has no title at all so the recipe name never appears, and the dark back glyph sits directly on the photo with no disc, contrast depending on the photo, unlike PDP's white round button+fading title; P7 the collapsing parallax is ungated for reduced motion though PDP's and Pro's own equivalents are gated; P8 no press feedback on the ingredient row, the "+" disc, or the −/+ steps; P9 the stepper quantity is static text while PDP's bar rolls it; P10 image fade ungated, stale note snaps (`recipe_detail_page.dart` §3 Problems 1-10).
- **Perf risk:** low motion load overall; the `FlexibleSpaceBar` fades its full-bleed image background via framework opacity while collapsing, scroll-linked raster work on a large image; each ingredient tile rebuilds alone through its own selector, good; no always-running tickers.
- **Opportunity:** **give loading and error states a back affordance** — a trap on iOS specifically, treat as a correctness fix ahead of any styling (n/a, no token involved); route the ingredient add through the same `ShelfAddControl` morph PDP already uses so all three "add" surfaces agree (D13, matches §38's cross-screen "add to cart: three behaviours" finding, same root cause); fix the haptics to go through `Haptics.*` with one call per press, adding a success haptic to "Add all" (D21; CC-19/CC-20 "add-to-cart duplicated across sites"/"haptic decided in the wrong layer" families); gate the `FlexibleSpaceBar` parallax through `MotionGuard` like PDP's own gallery and Pro's own hero already do (D7, CC-24 "four reduced-motion idioms" family); give ingredient rows and stepper buttons a press state and roll the stepper's quantity (D13/D14, same `CatalogPillStepper` cross-cutting gap as §38).
- **Assets:** not-found illustration is Material `soup_kitchen_outlined`; no header placeholder before a photo loads (grey today); no "ingredients added" success visual beyond the snack; the time/servings meta line is text only with no glyphs, and step numbers have no styled discs.

---

### 40. Recipes (list) — `lib/src/features/recipes/presentation/pages/recipes_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop (`recipes_routes.dart:11-18`).
- **Motion:** 9 items — route slide (1); loader disc (2); pull-refresh with the Hero loader (3); empty pop (4); checking/offline/error plates (5); load-more dots (6); stale pill (7); thumbnail fade ungated (8); Material back/Retry ripples (9). **There are no feature-local motion primitives at all** — a grep for `Animat|MotionGuard|PressScale|Stagger` across `features/recipes` finds nothing beyond the shared core widgets.
- **State-change:** loading→loaded is a **hard swap from a centred disc to the full list — no skeleton, no entrance cascade of any kind**, unlike every sibling list (Offers, Orders, Coupons); empty pops its icon; error is the shared plates; load-more footer snaps between nothing/dots/Retry/offline-note and the new rows snap in with no motion; the stale pill fades in at the top and pushes the list down with no size easing; refresh just spins `BrandedRefresh` while the list stays in place.
- **Gestures:** vertical scroll; pull-to-refresh works on the loaded list; auto load-more at 500dp from the end; **the pull is dead on the empty state** because `BrandedRefresh` wraps a non-scrollable `EmptyStateView` directly — Pro's own unavailable view gets this right by wrapping its empty state in a `SingleChildScrollView`; no press feedback on a row tap; no long-press, no iOS swipe-back/predictive back.
- **Haptics:** only the pull-arm selection; **nothing on a row tap.**
- **Problems:** P1 no skeleton and no entrance cascade at all, inconsistent with Offers/Orders/Coupons which all pair a skeleton with a cascade; P2 rows have no press state and no haptic while PDP rail tiles and Pro brand tiles sink; P3 load-more Retry is a plain Material `TextButton` while PDP reviews use `AppOutlineButton`; P4 back is the Material `AppBar`'s `BackButton` with a ripple only, unlike PDP's `RoundOutlinedButton`, and its glyph differs from `HeroIcons.back`; P5 the stale note shifts the list with no size easing; P6 no iOS edge swipe or predictive back; P7 image fade ungated; P8 **pull-to-refresh does nothing on the empty state** — the spinner never even appears, so a pull is silently swallowed; P9 the load-more footer snaps between states and changes the list's end height with no transition (`recipes_page.dart` §4 Problems 1-9).
- **Perf risk:** low — a lazy `ListView.builder`, the `BlocBuilder` rebuilds only on feed/screen change, the load-more row selects its own state, the only looping ticker is the load-more dots, no per-frame work.
- **Opportunity:** add a skeleton+`EntranceCascade` to match Offers/Orders/Coupons, the one list in this audit set with neither (D14, D17, D18 — matches Offers' own O7 pattern directly, same fix, same token); fix the dead pull on empty by wrapping it in a scrollable, mirroring Pro's own already-correct pattern in the same codebase (n/a mechanical, reference `pro_unavailable_view.dart:16-28` as the same-app precedent); give rows a `PressScale` (D14/D22, matches the `CatalogRecipeCard` cross-screen gap noted from PDP's own rail); unify Retry's button style and the back control to the app's `AppOutlineButton`/`RoundOutlinedButton`+`HeroIcons.back` convention (D22).
- **Assets:** empty-recipes illustration is Material `soup_kitchen_outlined`; thumbnails have no placeholder (grey today); the meta line (time/servings) is text only with no glyphs; offline/error states use the shared generic Material icons.

---

### 41. Pro membership (paywall / member hub) — `lib/src/features/store_mode/presentation/pages/pro_membership_page.dart`
- **Entry/exit:** `HeroTransitionPage` slide-up/pop; signing in from the paywall routes through `go(login)` onto a `HeroCrossFadePage`, and **coming back re-creates the page so every entrance replays** (`store_mode_routes.dart:9-16`, `pro_join_button.dart:52-55`).
- **Motion:** 35 items — route slide (1); loader (2); lockup pop **every mount, during the route slide** (3); plan-tab drop-in raw 30ms default from above (4); thumb glide (5); pill colour+label (6); "Save N%" chip pop **then a forever `LightSweep`** (7); hero-band gradient tween (8); headline lines `StaggerEntrance`×2 at a **raw 80ms** step, replaying per plan with no cross-fade (9); a 1100ms painted arch that **redraws on every plan tap** (10); a `GlowPulse` glow that **breathes forever** behind the bag (11); the bag rises once then **floats forever** then lags on scroll (12); greeting-card `ScrollReveal` (13); member-card sheen (15) beside brand-tile press (19, listed out of sequence in the audit); ending-notice pop (16); free-delivery `ScrollReveal` (17); **two brand rows that drift forever in opposite directions** via a raw-24dp/s per-frame `jumpTo` ticker (18); perk-card `ScrollReveal` at a raw 60ms step (20); "On" pill pop (21); bottom-bar 400ms slide-up once (22); points `CountUpText` **from 0 on every open** (23); CTA press+ripple+**forever shine**+label flip (24); underlined-link press (25); paywall↔member-hub `FadeThroughSwitcher` that replays the bag/lines/arch on every standing change (26); busy overlay (27); confirm dialog (28); confetti (29); a welcome sheet+crown pop **700ms after the reply, regardless of network time** (30); cancelled toast (31); pull-refresh (32); stale pill (33); unavailable pop (34); welcome-sheet button press (35) (`pro_membership_page.dart` table).
- **State-change:** loading→loaded fires **up to 9 entrances in the same moment** (lockup, tabs, Save-chip+its sweep, headline, arch, bag, greeting card if in view, bottom bar, points count-from-0); brands arrive later via a separate cubit and **snap** in, pushing the perk cards down; a **plan switch fires about 8 concurrent animations** from one tap (thumb, pill colours, band gradient, headline re-stagger, 1.1s arch redraw, glow recolour, price count, CTA label flip), with the billing line under the price swapping with no transition; subscribe runs confirm→busy(≥500ms, first part of the confetti can play *under* the still-up scrim if the reply is fast)→confetti+success haptic in one emit→a welcome sheet 700ms later→behind the sheet's scrim the top **fades through to the member hero and snaps ≈84dp shorter** at the end of that fade, while the bottom bar collapses, the greeting card swaps content+height, and the perks gain a header, all with no transition; cancel runs confirm→busy→a snack, replaces the cancel button with a popping ending notice while the card height **snaps**, and the hero fades through again with its lines re-staggering; a signed-out guest sees the full paywall with the CTA flipped to "Sign in to join," and **every entrance replays** on return from login.
- **Gestures:** vertical scroll; pull-to-refresh on both the paywall and the (correctly scrollable) unavailable view; horizontal drag on each brand row pauses its drift until release; plan-tab scroll past 3 plans; welcome-sheet drag-dismiss; no long-press, no iOS swipe-back/predictive back; back is a close `IconButton`, blocked while busy.
- **Haptics:** selection on an unselected plan pill; tap on the CTA, brand tiles, welcome-sheet button; success on subscribed; **none on close, cancel renewal (a destructive action), the confirm-dialog buttons, or the underlined links.**
- **Problems:** P1 many infinite loops on one screen — glow, float (its documented `count` param goes unused), up to 2 `LightSweep`s, two brand marquees, none of them ever stops; P2 the brand rows auto-move with no pause control beyond hold/reduced-motion/screen-reader, a WCAG 2.2.2 concern; P3 `ProKeepAlive` keeps the top section's and greeting card's loops ticking even scrolled far out of view, because a keep-alive does not touch `TickerMode`; P4 a marquee still calls `jumpTo` every frame while built inside the cache extent under an unrevealed, opacity-0 `ScrollReveal`; P5 a jarring, busy entrance — the route rises while the tabs drop from above and up to 9 entrances land together, replaying in full after every sign-in round trip; P6 one plan tap fires ≈8 concurrent animations including a 1.1s arch redraw, and the headline hard-cuts rather than cross-fading between plans; P7 points count up from 0 on every open, contradicting the app's own documented "cached balance never counts up" rule that PDP itself follows; P8 the ending notice pops on every open for an already-cancelled member though its own doc says it should pop "right after the cancel"; P9 the "On" pills pop while still hidden by their own unrevealed `ScrollReveal` parent; P10 four different control styles for comparable actions — close is a bare ripple `IconButton`, cancel renewal is a `TextButton`, the confirm dialog is a stock `AlertDialog`, and the CTA gives double feedback (scale+ripple) where PDP's CTA gives scale only; P11 the welcome sheet waits a flat 700ms regardless of reply time, and a fast reply's confetti+fade-through mostly plays hidden behind the busy scrim and the sheet's own scrim; P12 three unrelated stagger rhythms (80/60/30ms raw) plus raw marquee speed/step constants; P13 a destructive cancel has no warning haptic or visual cue; P14 a very heavy screen gets only a spinner while loading, no skeleton, the entrances mask the snap; P15 subscribe and cancel both snap several layout changes at once — the bottom bar's collapse, the greeting card's content+height swap, the perks header's arrival, and the top section's ≈84dp height drop at the end of its fade-through; P16 brand rows that arrive late snap in at full height and push the perk cards down (`pro_membership_page.dart` §5 Problems 1-16).
- **Perf risk:** `GlowPulse`, `FloatLoop`, two marquee tickers, and up to two `LightSweep`s together keep the engine producing frames at the display refresh rate for as long as the paywall is open, including off-screen via `ProKeepAlive`; each marquee relayouts its horizontal `ListView` and dispatches scroll notifications every frame; two nested `ClipPath`s wrap the pulsing/floating/parallaxing hero band and the marquee band; the bottom bar's blur-20 shadow moves during its 400ms slide; `CountUpText` rebuilds and relayouts its `Text` every frame for 700ms, once for points on open and again for price on every plan tap; off-screen/backgrounded tickers are muted by `TickerMode` as expected, and a pending `LightSweep` rest-timer fires once then goes idle correctly.
- **Opportunity:** cap every loop's lifetime and gate all of them (glow, float, both sweeps, both marquees) with `ambientBudget`+`OnScreen`, including through `ProKeepAlive` — the single biggest opportunity on this screen, a direct match for B1-02's exact root cause across the whole app; drop points count-up-from-0 on open, same fix and evidence as My Coupons' §24 and Delivery Code's B1-15 (D13, D20; R08-27/28 — one cross-cutting candidate spans all three); replace the plan-tap's 8-way simultaneous choreography with a smaller, sequenced set — the arch redraw and glow recolour in particular could drop out or shorten without losing the "plan changed" signal (D17; R05-09 "functional vs auto motion families, exits shorter than entrances" argues for trimming this to the functional family); fix `FloatLoop`'s unused `count` param so the bag genuinely stops (n/a correctness, matches B1-03's sibling `FloatLoop` fix — reference it directly); unify close/cancel/confirm-dialog controls onto the app's own `RoundOutlinedButton`/`PressScale`/`Haptics.warning` conventions, adding a warning haptic to the destructive cancel (D21, D22; R07-26); make the welcome-sheet delay reply-time-aware instead of a flat 700ms, or shorten it enough that the fade-through is genuinely seen (n/a timing fix, no new token); flag for Phase 1/approval whether a subscription paywall specifically should get a smaller ambient budget than a browse screen — §9 (decision summary)'s `ambientBudget` rule already answers "how long," not "should this screen type get less."
- **Assets:** no welcome/subscribed illustration or GIF, a Material crown in a gradient disc today; three perk illustrations are Material glyphs in discs; no "Pro unavailable" empty-state illustration; the member card and success sheet reuse Material `workspace_premium` with no branded Pro crown mark; no "ending/lapsed welcome back" glyph; brand tiles with no logo fall back to an initial letter only, no placeholder art.

---



Source: Appendix A (brands, categories, category, product_listing), Appendix A
(route map, sheets, dialogs, snack bars, connectivity banner, stale/offline notices, locale veil, shell tab bar, cart bars,
brand sheet), Appendix A (loaders, busy overlay, pull-to-refresh, skeletons, state views,
product cards, steppers/add controls, add-to-cart path, light sweep, brand backdrop, brand marks, images). Numbering
continues from Appendix A (screens 19-41), so the three files merge cleanly. Four shop-page blocks (42-45) come
first, then one block per shared surface named in the brief: sheets & dialogs, snack bars, connectivity banner, stale
notices, locale veil, tab bar + cart bar, route→transition map, loaders, skeletons, state views, product
cards/shelves/steppers, add-to-cart path, ambient/brand widgets, images (46-59). A09's shared:brand-sheet folds into
ambient/brand widgets (58) since it is the same login/OTP ambient-loop family as `BrandBackdrop`/`HeroLockup`; A10's
shared:busy-overlay and shared:pull-to-refresh fold into loaders (53) as the submit- and refresh-flavoured members of the
same loading-feedback family. Tokens/primitives per §9 (decision summary) (`D#` = that file's numbered item). Evidence
IDs (`Rxx-yy`) from research_log_2026.md; `PB-xx`/`CC-xx` from Appendix B/Appendix C, found by grep against
those files' headline titles. Where an idea repeats a Part-1/Part-2 backlog candidate's root cause, the candidate id
(`B1-xx`/`B2-xx`) is cited directly instead of re-deriving the finding.

Two shop-internal shared surfaces are hosted once and cross-referenced rather than repeated: **S-L** (the listing body,
grid, tiles, skeleton, reveal clock — used by categories, category and product_listing) is defined in full inside block
45 (ProductListingPage); **S-R** (the category rail fold, circles → chips) is defined in full inside block 43
(CategoriesPage). Both are cited by their audit item ids (M1…, R-M1…) from blocks 43/44/45.

---

### 42. BrandsPage — `lib/src/features/shop/presentation/pages/brands_page.dart`
- **Entry/exit:** `HeroTransitionPage` (`config/routes/feature_routes/shop_routes.dart:23-30`): push `AppMotion.page` 300 ms
  `signature`, slide up from 100% + fade; pop `AppMotion.medium` 250 ms `exit`. Reduced motion → instant cut
  (`hero_slide_fade_transition.dart:75`); route below never moves (secondaryAnimation ignored, `hero_transition_page.dart:26`).
  Callers: home "view all" (`home_section_view.dart:95`), search (`search_brands_section.dart:25`), Pro
  (`pro_delivery_section.dart:90`).
- **Motion:** first-load `AppLoader` → `DelayedLoaderDisc` waits 150 ms then fades (signature) + springs 0.7→1
  (`AppSprings.snappy`) over `AppMotion.slow` (`brands_body.dart:40`; `delayed_loader_disc.dart:21-36`); pull-to-refresh disc
  (loaded state only, `:44-45`); stale pill fade-in on the first row (`:73-77`); brand logo fade-in, **ungated**
  (`brand_tile.dart:49`); empty/error/offline icon `PopScale.onMount` (`:56-59`; via `FailureView`, `:41-42`); back/search
  `PressScale` (`catalog_app_bar.dart:44-59`); title cross-fade on a language switch only; `CatalogCartBar` rise/sink + pill
  (nothing on this page adds to cart, so no flight ever lands here — refuted by the verifier). **`BrandTile` itself has no
  motion at all** (`brand_tile.dart:22-24`); the list has no entrance and no back-to-top.
- **State-change:** loading → loaded/empty/error is a plain `switch`, **no cross-fade** (`brands_body.dart:37-93`); a
  language-switch reload keeps the list; retry from the full-screen error goes error → disc → list; the failure-verdict swap
  snaps; the stale pill snaps its height open.
- **Gestures:** pull-to-refresh in loaded/empty only, not on `FailureView`; back via the round button or system back;
  **no in-app predictive back and no iOS edge-swipe** — `CustomTransitionPage` has no Cupertino mixin and there is no
  `pageTransitionsTheme`; `targetSdk = 37` only opts Android 16+ into the *system-level* back-to-home preview.
- **Haptics:** tap (lightImpact) on back/search/view-cart via `PressScale`, selection on pull-armed. **None on a brand
  tap** (`brand_tile.dart:22-24`).
- **Problems:** B1 missing press feedback + haptic on brand rows, unlike `search_brand_tile.dart:29` and
  `pro_brand_tile.dart:36`; B2 a spinner-style loader on a list page while the listing uses grid bones — two loading
  languages in one feature; B3 no cross-fade between loader/list/empty/error; B4 no pull-to-refresh on the error state; B5
  ungated logo fade + the verdict-swap snap + the stale-height snap (L12/L13/L14, shared with S-L); B6 the same
  `shop.no_brands` message uses `Icons.workspace_premium_outlined` here vs `Icons.sell_outlined` in the brand filter sheet
  (`listing_brand_sheet.dart:32-35`); B7 full-height slide-up for a drill-down, no predictive back, route below stays still;
  B8 no back-to-top on a list that can be long, unlike the listing.
- **Perf risk:** lazy `ListView.builder` + narrowed `buildWhen`; `HeroImage.circle` is a `RepaintBoundary` + `ClipOval`
  (fine); the shared `CatalogCartBar` `SizeTransition` relayout applies here too; no idle tickers.
- **Opportunity:** row press + haptic parity → B1-16 (standardise press-feedback language); replace the switch with
  `FadeThroughSwitcher` → B1-06 (same "hard-cut bucket swap" family); unify the two loading languages (disc vs bones) on
  this feature → new, no direct backlog id (folds into a new B3 candidate, see `backlog_cand_3.md`); B6's glyph drift →
  leave as is (a copy/asset consistency bug, not a motion one).
- **Assets:** network brand logos or an initial-letter grey circle; `chevron_right` auto-mirrors; empty
  `workspace_premium_outlined` 56 dp grey; error `error_outline_rounded`; offline `wifi_off_rounded` plate; stale
  `schedule_rounded`; cart pill `HeroAssets.globalCart`/`globalCartFull`. **Lacking/weak:** no "no brands" illustration
  (`brands_body.dart:56-59`, why: every empty state app-wide is a Material icon, see block 55); no brand-logo placeholder
  mark (flat grey tile, `hero_network_image.dart:122-123`, bare-letter fallback `brand_tile.dart:50-55`); no offline/error
  illustration (shared `FailureView`); B6's inconsistent no-brands glyph.

---

### 43. CategoriesPage — `lib/src/features/shop/presentation/pages/categories_page.dart`
Hosts **S-R**, the shared category rail fold (circles → chips), used identically by block 44 (CategoryPage). Files:
`features/shop/presentation/widgets/browse/category_rail_header.dart` (+`_delegate`), `category_rail.dart`,
`category_rail_item.dart`, `category_rail_compact.dart`, `category_rail_chip.dart`, `category_chips.dart`, `category_chip.dart`.
- **Entry/exit:** `HeroTransitionPage` (`shop_routes.dart:15-22`), same tokens/reduced-motion/no-predictive-back as block 42.
  Pushed from home "view all" (`home_section_view.dart:87`).
- **Motion — S-R (R-M1…R-M10):** R-M1 fold: circles ride up+fade over the first half, chips rise 8 dp+fade over the second
  half, hairline at full fold, scroll-linked via `Opacity`×2 + `Transform.translate` inside a `SliverPersistentHeaderDelegate`
  (`category_rail_header_delegate.dart:47-56,61-68,70-111`; reduced → hard swap at halfway, `:49-56`). R-M2 rail glides the
  picked circle to centre on `ScrollController.animateTo` (page 300, emphasizedDecelerate, `category_rail.dart:71-75`; jump
  under reduced, `:68-70`). R-M3 picked circle grows 0.92→1 + ring/label lerp (`AnimatedScale` `easeOutBack`, **not through
  `MotionGuard.curve`**, `category_rail_item.dart:52-55,56-70,91-101`). R-M4 circle press `PressScale` 0.97 selection
  (`:44-47`). R-M5 folded chip fill `AnimatedContainer`, **label `Text` not animated** (`category_rail_chip.dart:42-58,78-88`).
  R-M6 folded chip press + selection (`:38-41`). R-M7 folded row brings the open chip into view with **no duration**
  (`category_rail_compact.dart:42-56`). R-M8 pick from folded chips glides the list to 0 (sheetLarge 500,
  emphasizedDecelerate; jump under reduced, `category_rail_header_delegate.dart:120-132`). R-M9 level chips fill+label
  lerp+press+selection (`category_chip.dart:31-58`). R-M10 level chips row centres the pick (`ensureVisible`, page 300,
  emphasizedDecelerate, `category_chips.dart:37-53`). Plus (own to this page): tree first load `AppLoader`
  (`categories_body.dart:42`); tree empty/failure `PopScale`/`FailureView` (`:47-50,43-46`); **top-level tabs
  (`CategoryTab`) have no motion at all** — a plain `GestureDetector`, the indicator border colour swaps, the label style
  snaps, no controller, never scrolls the picked tab into view (`category_tab.dart:27-51`, `category_tab_bar.dart:44-60`);
  the shared listing motion S-L M1-M22 (see block 45; toolbar shown).
- **State-change:** tree loading/error/empty replace the whole body with no cross-fade, then snap to rows + grid bones (a
  second loading language) before the ≈0.83 s S-L reveal — worst case route 300 ms → 150 ms wait → 400 ms disc pop → snap →
  bones → snap → cascade; the tab row is empty inside its fixed 48 dp while the tree loads, then snaps in; tab/rail/chip
  picks restart the listing under S-L's L2 + (deep-scroll) L17; there is **no stale note for the tree**, only the products'
  (`product_listing_body.dart:141-147`); a tree refresh failure over data is **silent** — no `ScreenFailureListener` on
  `CategoryBrowseCubit` (`categories_body.dart:33-61`).
- **Gestures:** pull-to-refresh (both reads) in listing states only, **none** while the tree loads/fails/is empty
  (`categories_body.dart:42-50` sit outside `BrandedRefresh`); rail/chips/toolbar scroll horizontally; **no swipe between
  top-level tabs**, tap only; sheets drag-dismiss; back as block 42.
- **Haptics:** rail/chip picks → selection via `PressScale` (also on a no-op re-tap, R10); **top-level tabs → none**
  (`category_tab.dart:27-29`); S-L listing haptics (direct `HapticFeedback`).
- **Problems (own to this page):** C1 top-level tab bar is the odd one out — no press/haptic/scroll-into-view, unlike the
  collection tabs in the same feature which glide an ink bar, click and centre (`collection_tab_strip.dart:77-84,114,142-147`);
  C2 two loaders in a row (disc for the tree, then grid bones) — the longest wait-to-content in this group; C3 R1-R10 (rail
  fold, below) + L1-L18 (S-L, block 45) apply; C4 no pull-to-refresh and no feedback for a silent tree-refresh failure while
  the tree loads/fails/is empty; C5 page transition/back as B7; C6 (new) a tab pick while scrolled deep restarts under the
  current offset, with no back-to-top glide unlike the folded chips' R-M8 [PLAUSIBLE].
- **Problems — S-R (R1…R10):** R1 rest mid-fold leaves one row part-faded or (near 50%) the header blank, no snap
  configuration [PLAUSIBLE]; R2 the 108 dp header/chips row snap in with no size animation when the tree arrives or the top
  tab changes; R3 rail content swaps instantly (keyed by id) + scroll jump on a new parent; R4 many concurrent motions per
  pick (glide 300 + scale 250 + ring/label lerp + chips snap + grid→bones snap + shimmer + ≈0.83 s cascade + one haptic); R5
  the 500 ms back-to-top glide (R-M8) runs while the list restarts to bones underneath, scroll extent shrinks mid-glide
  [PLAUSIBLE]; R6 level chip lerps its label style, folded rail chip snaps it, in the same header area; R7 `easeOutBack`
  overshoot on the deselecting circle's shrink too; R8 a label weight lerp reflows neighbouring pill widths for 150 ms
  (rail circles are exempt, fixed 76 dp box); R9 (new) `CategoryChips` keeps the old row's scroll offset on a new parent
  (unlike the rail, which resets) and then glides 300 ms to "All" [PLAUSIBLE]; R10 (new) a no-op re-tap still fires the
  selection haptic, and re-tapping the open folded chip still glides the whole list to the top.
- **Perf risk:** the delegate's `build` runs every scroll frame while `shrinkOffset` changes, re-creating
  `CategoryRail`/`CategoryRailCompact` and rebuilding visible (non-const) items (`category_rail_header_delegate.dart:84,102-106`);
  two `Opacity` widgets over network-image subtrees add saveLayer per fold frame; `AnimatedDefaultTextStyle` weight lerp
  re-layouts text for 250 ms on two circles; a tab pick fan-outs rebuilds across the rail/chips/tab-bar `BlocSelector`s + the
  header sliver swap + the grid restart; no idle tickers; S-L perf (block 45) applies to the grid.
- **Opportunity:** unify the tab-bar/rail/chips/collection-tabs selected-item language (glide vs snap, haptic vs none,
  label lerp vs snap) → CC-26 (tab switch gets 3 different treatments) + B2-09 (collapse the three segmented-thumb
  implementations, needs a ruling first); orchestrate the R4 concurrent-motion pile-up on a pick → B2-03 (sequence
  simultaneous state-change motions); size-transition the late tree/chips insertion instead of a snap → B2-05 (D13
  `SizeFadeSwitcher`/`CollapseReveal`); silent tree-refresh failure → B1-04 (adopt the offline contract wherever missing);
  R9's stale scroll offset → leave as is unless research favours a reset-vs-glide rule (D17 extension candidate).
- **Assets:** tabs are text-only; rail/chip artwork from the backend, missing artwork shows `category_outlined`
  (`category_rail_item.dart:77-81`, `category_rail_chip.dart:68-72`); "All" reuses the parent's artwork or the same glyph;
  empty store `category_outlined`. **Lacking/weak:** no dedicated "All" glyph (can look identical to an artwork-less
  category, `category_rail.dart:122-127`); no category-artwork placeholder (flat grey while loading, generic glyph when
  missing); no empty-store illustration; offline/error illustrations shared with block 55.

---

### 44. CategoryPage — `lib/src/features/shop/presentation/pages/category_page.dart`
Uses S-R (block 43) + S-L (block 45) unchanged; tree and products load **in parallel**
(`category_page.dart:37-47`). Pushed from home, search, PDP category link and the assistant (`home_section_view.dart:86`,
`search_category_tile.dart:30`, `pdp_category_link.dart:25`, `assistant_categories_rail.dart:29`).
- **Entry/exit:** `HeroTransitionPage` (`shop_routes.dart:32-44`), same as block 42; an unknown `extra` renders
  `PlaceholderPage` with the same transition.
- **Motion:** page transition; title cross-fade from the caller's name to the backend name (medium, **linear default
  curve, not `signature`**, `category_browse_app_bar.dart:21-24` → `catalog_app_bar_title.dart:15-20`); S-R rail fold +
  rail/chips (block 43); S-L shared listing, toolbar on (block 45). No top-level tab bar on this page.
- **State-change:** products do not wait for the tree — if products arrive first, the rail header (108 dp) + chips row
  **snap in above** the grid (which may still be mid-cascade) and push it down (R2); **tree failure is invisible** —
  `CategoryBody` never reads the tree status, rows simply never appear, retried only on reconnect and pull-to-refresh with
  no loader/error cue (`category_body.dart:27-35`, `category_page.dart:28-33`); S-L state changes otherwise.
- **Gestures:** pull-to-refresh on all listing states (both reads); rail/chips/toolbar scroll horizontally; fold is
  scroll-driven; back as block 42 (no predictive back/iOS swipe).
- **Haptics:** as block 43 minus the tabs.
- **Problems:** K1 late rows push content down (R2) with no size/fade transition; K2 silent tree failure, retried only on
  reconnect or a pull with no cue; K3 R1-R10 + L1-L18 apply; K4 title cross-fade on the linear default curve, not
  `signature`; K5 page transition/back as B7 (block 42).
- **Perf risk:** as block 43 without the tab bar; the late 108 dp header insertion re-lays out the whole sliver list once.
- **Assets:** as block 43 (category-artwork placeholder, empty-store, offline/error illustrations); for a category with no
  artwork, the "All" circle shows the generic glyph (`category_rail.dart:124`, `parent?.image ?? ''`).
- **Opportunity:** silent tree failure → B1-04 (offline/failure contract, exact same root cause as K2 in block 43's C4);
  late row push-down → B2-05 (size-transition late-arriving content); K4's curve drift → D5 (use `signature` consistently);
  otherwise as block 43's Opportunity for S-R/S-L.

---

### 45. ProductListingPage — `lib/src/features/shop/presentation/pages/product_listing_page.dart`
Hosts **S-L**, the shared listing body/grid/tiles/skeleton/reveal, used identically by blocks 43 and 44. Files:
`features/shop/presentation/widgets/listing/product_listing_body.dart`, `product_grid_sliver.dart`,
`listing_product_tile.dart`, `listing_reveal*.dart`, `listing_grid_skeleton.dart`, `listing_viewport_skeleton.dart`,
`listing_load_more_footer.dart`, `listing_toolbar.dart`, `listing_filter_pill.dart`, `listing_sort_sheet.dart`,
`listing_brand_sheet.dart`, `listing_brand_row.dart`, `catalog_cart_bar.dart`, `catalog_cart_pill.dart`,
`catalog_app_bar*.dart`, `catalog_round_button.dart`; core `shelf_*.dart` (see block 56), `catalog_pill_stepper.dart`,
`catalog_step_button.dart`, `back_to_top_*.dart`, `branded_refresh.dart`, `refresh_disc_header.dart`, `view_cart_pill.dart`,
`cart_bar_summary.dart`, `cart_basket_badge.dart`, `hero_bar_total.dart`, `fly_to_cart.dart`. Two looks: **plain** (search
results, tag lists) and **collection** (a collection/brand slug, via `ListingCollectionScaffold`).
- **Entry/exit:** `HeroTransitionPage` (`shop_routes.dart:46-58`; search results `search_routes.dart:19-35`), same tokens as
  block 42. The collection top bar paints under the status bar with `SystemUiOverlayStyle.dark`.
- **Motion — S-L (M1…M22):** M1 listing entrance clock, **raw `Duration(milliseconds: 900)`** (`listing_reveal.dart:27-32`),
  on first load/error, sort/filter/category restart, retry — **not** pull-to-refresh; stands at 1 under reduced/screen-reader
  (`:38-47,61-62`). M2 count + first 7 cards fade+rise 8% staggered, raw step 0.07 (=63 ms)/span 0.5 (=450 ms)
  (`listing_reveal_item.dart:24-52`). M3 "Save N%" badge pops 0.6→1 late in the arrival (`shelf_save_badge.dart:25-32`,
  interval 0.45-1 `emphasized`). M4 lime marker draw-on under a deal price (`shelf_card_price.dart:61-67`,
  `shelf_marker_painter.dart:13,26-42`, RTL-aware). M5 loading bones shimmer 1100 ms, 2 rows
  (`listing_grid_skeleton.dart:13,26-35`). M6 card passive press-sink `PressScale` 0.97 (`listing_product_tile.dart:41-43`).
  M7 "+"→"− qty +" `AnimatedSwitcher` fade+scale from 0.6 (`shelf_add_control.dart:44-74`, RTL corner resolved). M8 "+"
  press `PressScale` 0.9 no haptic (`shelf_add_button.dart:34-38`). M9 add-to-cart flight `FlyToCart.flyFrom`
  (`listing_product_tile.dart:56-64`; slow 400 signature; skipped under reduced). M10 "View cart" bar rise/sink
  `AnimatedSwitcher` Size+Fade (`catalog_cart_bar.dart:24-41`, slow 400). M11 cart pill press+badge pop+total roll
  (`view_cart_pill.dart:53-55`, `cart_basket_badge.dart:54`, `hero_bar_total.dart:56-67`, roll on `flip` 280, not
  "fast/medium" as an earlier doc comment implied). M12 filter/sort pills fill+label lerp+caret half-turn
  (`listing_filter_pill.dart:42-82`). M13 sort/brand sheets (page 300 in / medium 250 out). M14 sheet-row ripple, **no
  haptic** (`listing_sort_sheet.dart:44`, InkSparkle). M15 back-to-top pop/shrink + glide (medium/sheetLarge 500,
  `back_to_top_button.dart:25-36`, `back_to_top_overlay.dart:33,58-59,70-74`). M16 pull-to-refresh disc
  (`branded_refresh.dart:56-74`). M17 load-more dots. M18 stale-age pill fade-in (`stale_age_pill.dart:59-64`). M19
  empty/error/offline icon `PopScale.onMount`. M20 product photo fade-in, `imageFade` 500, **ungated**
  (`retrying_network_image.dart:246`). M21 app-bar round buttons press 0.92. M22 app-bar title cross-fade (linear default).
  No motion in `ListingResultsCount`, `ListingSkeletonCard`, `ShelfTagPill`, `ShelfProPriceChip`,
  `CatalogUnavailableOverlay`, `LoadMoreOfflineNote`/`OfflineInlineNote`, `ReconnectRefresh`; no app-bar scroll-under
  elevation.
- **Motion — collection look only:** top-bar tint lerps cream→white with scroll (`collection_app_bar_delegate.dart:61-71`),
  hairline **snaps** at p=1; hero heading rises 16 dp+fades on mount (slow, emphasizedDecelerate,
  `collection_hero.dart:82-92`); emoji wiggles+grows 1.2× once after `slow`, again on tap with `Haptics.tap` — **raw
  `Duration(milliseconds: 900)`**, raw π literal, raw turn/scale values (`collection_hero_emoji.dart:29-88`);
  `CountdownChip` ticks once a second, digits **snap**, `TickerMode`-off (`countdown_chip.dart:46-50`); collection tabs ink
  bar glide (medium, emphasizedDecelerate) + label lerp + centring + shadow toggle, selection haptic skipped on the open tab
  (`collection_tab_strip.dart:77-147`); tab-pick-while-scrolled-past-hero → **instant `jumpTo`**, then L2 restart over
  viewport-tall bones (`listing_category_tabs.dart:49-60`); round back/search press 0.92 (`round_outlined_button.dart:38-40`,
  a near-duplicate of `CatalogRoundButton`).
- **State-change:** S-L: loading→loaded is a **switch with no cross-fade** — bones vanish in one frame, cards start at
  opacity 0 on the M1 clock (whole arrival ≈0.83 s) [CONFIRMED]; restart (sort/filter/category/tab) → bones **snap in**
  over the old grid → saved first page (if any) → full M1 cascade again, possible bone flash [PLAUSIBLE]; language switch
  keeps the loaded list; retry from the full-screen error → bones → cascade again; cache→server replacement rebuilds the
  grid with **no** clock replay, new/reordered cards **snap** [CONFIRMED]; empty/error/offline stack a **double entrance**
  (`ListingRevealItem` fade+rise plus the icon's own `PopScale.onMount`); the checking→verdict swap has **no transition**;
  stale pill height-**snaps** open with no fade-out; load-more swaps loader↔retry↔offline note with snaps; success (add) =
  M9 flight + M7 stepper + M11 badge pop/roll + (first add) M10 rise; not applicable: signed-out (public route). Collection
  only: tabs snap in as a 49 dp pinned row pushing the grid down when they arrive after their probes, clock does not
  replay; a tabs failure is silent by design; countdown-reaches-zero is a height snap.
- **Gestures:** pull-to-refresh wraps every listing state (`product_listing_body.dart:98-102`), selection haptic on armed;
  toolbar/rail/chips/tabs scroll horizontally; sheets drag-dismiss with **no drag handle** shown; no long-press on cards
  (home has one); back via round button/system, no predictive back/iOS swipe; status-bar tap-to-top not verified.
- **Haptics:** add (selection, direct `HapticFeedback`, bypasses the `Haptics.enabled` mute [CONFIRMED]); remove (light
  impact, same bypass); filter/sort pills (selection via `PressScale`); back/search/view-cart/back-to-top (tap, default
  `PressScale`); pull armed (selection); sort/brand sheet rows + load-more retry (**none**).
- **Problems — S-L (L1…L18):** L1 raw 900 ms clock/63 ms step/450 ms span, `StaggerEntrance`'s own raw 30 ms default (not
  actually wired to `AppMotion.staggerStep`) — a third feature-local entrance primitive; L2 jarring restart, every
  sort/filter/tab/rail/chip pick replays the ≈0.83 s cascade; L3 skeleton→content blank-band gap [PLAUSIBLE]; L4
  cache→server swap snaps; L5 haptics bypass the mute via direct `HapticFeedback` (also home, recipes); L6 the passive
  card press sinks the **whole card** including under the "+"/stepper, which have no press feedback of their own; L7
  quantity digit **snaps** here, unlike cart's/PDP's `RollingNumber`; L8 flight starts from the card centre via the
  `BlocSelector` builder context, not the "+", and every stepper "+" launches another flight; L9 first add into an empty
  basket flies to the covered shell's Cart tab icon since the page's own pill target is unmounted [PLAUSIBLE, matches A08
  L9]; L10 add feedback differs from home (no success haptic/confetti here, only selection+flight); L11 no shared-element
  continuity card→PDP (no `Hero` on the card); L12 no reduced-motion fallback for the photo fade (M20) or InkSparkle
  (M14); L13 double entrance on empty/error/offline (reveal+PopScale) + the verdict-swap snap; L14 stale pill height snap,
  fade-in only; L15 caret points up while a filter is active, not while its sheet is open, and its icon/caret colours
  snap while the fill animates; L16 sheet rows ripple with no haptic while pills give PressScale+selection, and a pick
  pops the sheet before the check mark shows; L17 (new) a restart while scrolled deep clamps the scroll position in one
  frame, viewport not reserved [PLAUSIBLE]; L18 (new) `maxAnimated = 7` assumes two columns — from 3 columns up, later
  visible cards appear at once while earlier ones still fade in.
- **Problems — collection look (P1…P10):** P1 the brand filter sheet waits for the **whole** brand read (cache+server)
  with no busy state on the pill [CONFIRMED]; P2 a double-tap during that wait opens an **empty** "no brands" sheet, then
  the first sheet opens later stacked on top [CONFIRMED]; P3 stacked entrances (route+hero rise+cascade+emoji wiggle,
  ≈1.3 s) + a late tabs-row push-down; P4 two countdown implementations (`CountdownChip` unaligned per-chip `Timer`, snap,
  per-second semantics vs `CountdownDigits`' shared aligned clock, per-minute semantics); P5 raw motion values in
  `collection_hero_emoji.dart` and the L1 clock; P6 instant `jumpTo` on a tab pick next to the tab bar's own glide; P7
  empty state always uses `search_off_rounded` even for a brand/collection/category or an emptied filter; P8 L1-L18 apply
  (L15/L16 plain look only); P9 page transition/back as B7 (block 42), search results lose continuity with the search
  field; P10 (new) the ink bar is measured mid-label-lerp, can end a few px off its tab [PLAUSIBLE].
- **Perf risk:** reveal — every piece/badge/marker is notified on **every** tick of the whole 900 ms clock via `drive()`,
  not only its own interval; the deal-card marker repaints the tile's `RepaintBoundary` every tick, up to ≈600 ms of
  `computeMetrics`/`extractPath` for 6-7 cards; the "Save" badge `ScaleTransition` also repaints the tile every tick;
  `ListingRevealItem.build` allocates new `drive()` chains per build; `CatalogCartBar`'s `SizeTransition` inside
  `bottomNavigationBar` relayouts the Scaffold body per frame for 400 ms; flight `AnimatedBuilder` rebuilds
  `Positioned`+`Opacity`+`Transform` per frame in the root overlay; page transition is a full-page `FadeTransition`+slide
  for 300 ms (shared app-wide); no idle tickers (shimmer/dots/stale-clock all gated). Collection: `CountdownChip`
  `setState` every second with no boundary of its own, **keeps ticking while the hero is scrolled off-screen**
  (`SliverToBoxAdapter` child stays mounted); `CollectionHero.build` schedules a post-frame callback on every build; the
  tab shadow toggles an `AnimatedContainer` decoration lerp.
- **Opportunity:** unify money/qty motion on one `RollingNumber` family incl. the grid stepper → B2-01 (exact match);
  collapse the three list-entrance systems (`ListingReveal`, `StaggerEntrance`, `EntranceCascade`) and tokenise every raw
  step → B1-07/CC-02/CC-03; stop replaying the cascade on every restart/filter, first-load only → D17 (extends B1-08's
  root cause to this non-scroll-back case); fix the L8/L9 flight-origin bugs → CC-33/PB-21 (FlyToCart internals); route
  the ungated photo fade + InkSparkle through `MotionGuard` → CC-24 (four reduced-motion idioms); size-transition the
  late tabs-row/rail-header insertion instead of a snap → B2-05; sequence the collection-look's stacked entrances (P3) →
  B2-03; fix the brand-filter wait + double-tap race (P1/P2) → new, no direct backlog id (candidate for `backlog_cand_3.md`);
  unify the two countdown implementations (P4) → CC-11 (countdowns tick on private timers, `SecondClock` exists for this).
- **Assets:** product photos on a flat grey tile, `image_outlined` for an empty URL; out-of-stock white wash+text; text-only
  "Save N%"/tag/Pro chips; stepper Material glyphs; toolbar `swap_vert_rounded`/caret; empty `search_off_rounded`;
  load-more `refresh_rounded`/`wifi_off_rounded`; back-to-top `keyboard_arrow_up_rounded`; collection emoji + painted wave +
  `timer_outlined`; cart pill basket PNGs. **Lacking/weak:** a "no products here"/"filters too narrow" illustration,
  distinct from a search miss; a product-image placeholder mark (today flat grey, block 59); an out-of-stock
  glyph/badge (text-only wash); toolbar pill glyphs for brand/in-stock/on-sale (only sort has one); the brand-collection
  hero has no brand logo; collection hero art is an emoji only, no per-type illustration (flash sale, best sellers,
  offers); offline/error illustrations (shared, block 55); merch-tag glyphs are text-only.

---

### 46. shared:sheets-dialogs
**Files:** `core/navigation/navigation.dart` (`showHeroBottomSheet` :21-45, `showHeroDialog` :50-81). **20 sheet call
sites** condensed: cart (coupon entry), cart deals (large), 7 checkout sheets via `CheckoutSheetFrame.show` (branch, timing
→ chained slot, info, note, items, coupon), account (DOB picker), assistant×3 (hide buddy, copy, 5-step onboarding, large),
coupons (rule sheet), home (quick look), orders×2 (cancel-reason, duplicated on the tracking page), shop×2 (sort, brand —
waits on the network read). **10 dialog/overlay call sites:** account (logout confirm), address (delete confirm), assistant
×2 (handoff, mic-blocked), cart (clear confirm, `AlertDialog`), home (marketing popup queue, 75% scrim), store_mode ×2
(cancel renewal, subscribe confirm — both `AlertDialog`), assistant chat menu (framework `PopupMenuButton`), licenses
(framework `MaterialPageRoute`, the only non-Hero route in the app, see block 52).
- **Entry/exit:** sheets — enter `AppMotion.page` 300 ms or `sheetLarge` 500 ms when `large`, exit `medium` 250 ms,
  `signature`/`exit` curves, all through `MotionGuard` ✓; framework honours both curves. Dialogs — `showGeneralDialog`,
  `medium` 250 ms both legs, fade on **linear** + scale `dialogScaleBegin` 1.1→1.0 on `Curves.decelerate` (a different
  curve family from sheets/pages); reduced → child only; `barrierColor ?? black54`, `barrierDismissible` always true (no
  caller overrides it).
- **Motion:** sheet slide+scrim fade (framework, all 20 sites); `ShakeX` on a refused coupon code (cart + checkout coupon
  sheets); `CollapseReveal` error line (same 2); `HeroSubmitButton` label↔loader↔check (cart coupon, checkout note,
  checkout coupon); `OptionRow` animated radio + selection haptic (checkout branch/timing, cancel-order reasons); slot
  chips press-scale+fill (checkout timing→slot); onboarding `PageView`+`animateToPage` (slow, jump under reduced);
  `PopScale.onMount` (coupon-rule ticket disc, home quick-look, Pro-welcome sheet — the last opens **700 ms into the
  confetti** on purpose, 0 under reduced); dialogs — `AppButton`'s passive `PressScale` 0.96+ripple+`Haptics.tap` on every
  custom-card confirm and the home-popup CTA (`AlertDialog`s and `AppOutlineButton` cancels give ink only, no scale, no
  haptic).
- **State-change:** inside a sheet — only the two coupon sheets react to an error (shake/collapse/haptic); selection
  sheets (sort, brand, branch, timing, slot, DOB) signal success only by closing, most with a static check that the
  immediate pop cuts off; cancel-order shows a static `OfflineInlineNote`. Inside a dialog — nothing moves; the result
  shows elsewhere (snack/busy overlay/page).
- **Gestures:** every sheet is drag-to-dismiss + scrim-tap dismissible by framework default (not exposed by
  `showHeroBottomSheet`); **no drag handle** on checkout/deals/sort/brand/DOB/copy/hide/Pro sheets although all are
  draggable; checkout sheets close via a floating ✕ disc + tap-strip instead. Dialogs: barrier tap + back only, no swipe.
- **Haptics:** sheets — selection on rows with `OptionRow`/slot chips, `Haptics.tap` on `AppButton`/`HeroSubmitButton`
  CTAs, **none** on sort/brand/DOB rows (static check only). Dialogs — logout fires `tap` then `warning` back to back;
  clear-cart `warning` only; delete-address/cancel-order `tap` only; cancel-Pro-renewal **none**.
- **Problems:** four different sheet tops (handle+title+✕, checkout's floating ✕ disc with no handle, home quick-look's
  own handle, M3-default sheets with no handle at all — all draggable); three sheet surfaces/radii (white 24 dp, checkout
  12 dp, M3 default seed-tint 28 dp); the same items sheet enters at 300 or 500 ms depending on line count; the chained
  timing→slot sheet costs 250 ms exit + 500 ms enter before slots appear; the brand-filter sheet waits for the network
  read with no pending state, and a double tap opens an empty "no brands" sheet on top of the real one (see block 45 P1/P2);
  `PopScale.onMount` in 3 sheets starts during their own 300-400 ms slide, so it is partly hidden; the shared exit-easing
  inversion applies to sheets too (block 52); duplicate open path for cancel-order (a second `showHeroBottomSheet` call
  rebuilds on every keyboard frame instead of reusing the build-once instance); selection feedback differs by sheet
  (animated radio+haptic vs a static check with none); scrim 54% (sheets, framework default) vs 60%/75% (dialogs) vs the
  reference 75%. Dialogs: three shells and three radii (8/16/24 dp); three scrim strengths; destructive-confirm haptics
  disagree (tap+warning / warning-only / tap-only / none) across four destructive actions; dialogs use
  `Curves.decelerate`+linear where sheets/pages use `signature`; `AppMotion.popup`'s doc ("Home centered-popup enter") does
  not match what the home marketing popup actually uses (a generic 250 ms scale dialog); the popup-queue's 300 ms gap
  between popups is **not MotionGuard-gated**; no undo after any destructive dialog result; destructive-button colour
  differs (brand-green delete-address vs `logoutRed` vs `errorDeep`).
- **Perf risk:** the duplicate cancel-order open path rebuilds the whole sheet per keyboard frame; `CheckoutSheetFrame`
  reads `MediaQuery.of(context)` and rebuilds on every inset change; a modal sheet route is not opaque, so the covered
  page's tickers keep running underneath; dialogs animate a small subtree only (low cost), except the home popup which
  decodes a network image while scaling in [INFERENCE].
- **Opportunity:** unify the sheet-top language (handle vs floating ✕ vs none) and the sheet enter-speed rule (300 vs
  500 ms by size, not by ad-hoc line count) → D12 (§9 (decision summary)'s own sheet/dialog token rule); fold the chained
  timing→slot sheets into one flow → CC-13 family (page/sheet-type drift), also flagged for checkout in appA_2 §21;
  standardise selection feedback (haptic+animated radio vs static check) across sort/brand/DOB → D21; unify the three
  dialog shells/radii/scrims onto one system → D12; fix the destructive-haptic taxonomy → B1-05 (exact match); MotionGuard
  the popup-queue gap → CC-24. Research: `R09-12` (grab handles are "easy to ignore", show a visible close, don't stack
  sheets — matches the no-handle problem and the chained-sheet problem directly), `R09-10`/`R09-13` (sheet detents/grabber
  mechanics), `R08-22` (choose the channel by severity — relevant to when a dialog vs a sheet vs inline error is right).
- **Assets:** Pro-welcome sheet uses a Material `workspace_premium_rounded` disc → lacks a Pro crown illustration;
  coupon-rule sheet uses `confirmation_number_rounded` → lacks a Hero coupon-ticket glyph; the timing sheet's
  schedule/bolt/event glyphs are Material, not a matched ASAP/express/scheduled set; filter sheets mix `sell_outlined`
  and `check_rounded` with HeroIcons elsewhere; delete-address dialog has no art at all; clear-cart dialog is a plain
  `AlertDialog` with no art; the handoff dialog's `support_agent_rounded` has no illustration to sit beside the painted
  mascot; mic-blocked dialog's `mic_off_rounded` is weak/generic; logout's `logout_rounded` is acceptable but not HeroIcons.

---

### 47. shared:snack-bars
**Files:** `core/navigation/hero_snack_bar.dart` (`showHeroSnackBar` :10-18, `showFailureSnackBar` :30-48),
`core/navigation/screen_failure_listener.dart:16-51`. 72 call-site lines condensed: `ScreenFailureListener` on 16 screens;
`showFailureSnackBar` direct on 10 more; ~40 plain success/info/warning/"coming soon" snacks across account, address,
assistant, cart, checkout, notifications, orders, Pro, settings, support.
- **Entry/exit:** no `snackBarTheme` set → Flutter M3 defaults apply: **fixed** behaviour, 250 ms in/out
  (`fastOutSlowIn`), height-reveal `Align` inside a `ClipRect`, **4 s** on screen, no MotionGuard gate (the framework's own
  controller scales under disable-animations instead); each snack is a `Hero` keyed by its content, so a visible one flies
  across a push/pop; `hideCurrentSnackBar` runs the old snack's exit **before** the next one enters (~500 ms out-then-in,
  not a swap).
- **Motion:** fixed height-reveal (framework, ~65 sites); floating fade+height (4 sites, all in account: about links, about
  social chip, delivery-code save bar, settings feedback); cross-route `Hero` flight (framework); offline nudge substitutes
  for a snack (block 48) rather than showing one.
- **State-change:** success/info/error/offline-action **look and move identically** — text on the M3 inverse surface, no
  tone, no glyph (`hero_snack_bar.dart:17`); a transport failure of a **read** shows no snack at all by design (the banner
  speaks).
- **Gestures:** framework swipe-to-dismiss (down) on fixed snacks; **no action button anywhere** — no Undo, no "View".
- **Haptics:** none from the snack system itself; a few call sites fire their own haptic before the snack.
- **Problems:** no tone/no glyph distinguishing success/warning/error/offline; no action support → no Undo after address
  deleted/cart cleared/coupon removed, no "View cart" after reorder; **four floating snacks** among ~65 fixed ones for the
  same kind of message (`profile saved` is fixed, `settings feedback` floats); rapid messages play out-then-in (~500 ms)
  instead of swapping; the framework's 250 ms `fastOutSlowIn` sits outside `AppMotion` entirely; five snacks are used as
  "coming soon" placeholders for dead controls (social login, photo attach, rider call, hotline, rate-us); a fixed snack
  may cover the shell's buddy launcher, and one fired while a sheet is open lands under the sheet's own scrim
  [INFERENCE].
- **Perf risk:** low — `ClipRect`+height animation of a small bar; the Scaffold relayouts its bottom slot per frame
  (framework).
- **Opportunity:** add tone + an optional action/Undo → new, no direct backlog id — a strong `backlog_cand_3.md` candidate
  given how many destructive actions in block 46 already lack one; fold the 4 floating snacks onto the fixed convention (or
  vice versa) → D12; retire the 5 "coming soon" placeholder snacks once those controls ship or are cut → leave as is
  (product decision, not motion). Research: `R08-22` (choose the channel by severity, one snackbar shown at a time — the
  app already does the "one at a time" part via `hideCurrentSnackBar`, but the severity-blind styling is the gap),
  `R08-21` (toasts are an a11y problem, put messages next to the action where possible — supports the "no undo" finding),
  `R05-03` (three fixed dwell tiers by severity, vs this app's one 4 s duration for everything).
- **Assets:** lacks a small state-glyph set (success ✓ / info i / error ! / offline wifi-off) — every snack is text only.

---

### 48. shared:connectivity-banner
**Files:** `features/connectivity/presentation/widgets/connectivity_banner_host.dart` (+`_frame`), `connectivity_bar.dart`
(+`_content`, `_icon`, `_label`); `core/widgets/connectivity_scope.dart`, `reconnect_refresh.dart`. Hosted above every
route/sheet/dialog in `app.dart:247-253`.
- **Entry/exit:** shown only after `offlineDebounce` 1.5 s + a confirming check; "back online" held 2 s; hidden on splash.
  Open/close = `CollapseReveal` (`SizeTransition` height + fade from 50%, medium 250 signature) — never on mount; the bar
  is a `Column` child above the navigator, so it **pushes every route/sheet/dialog down** while it opens/closes.
- **Motion:** surface colour morph offline↔back-online (`AnimatedContainer` 250 ms); "back online" white `TintFlash` wash
  (breathe 600 ms); icon swap wifi-off→dots→check via `PopSwitcher` (`AppSprings.snappy`); reconnecting loader
  (`BrandedDotLoader`, loops only during a check); nudge = `Haptics.tap` + `ShakeX` 4 dp ×2 (only while offline, not on
  splash). All MotionGuard-gated.
- **State-change:** hidden→offline opens+fades; offline→reconnecting pops the icon to dots, **title text swaps
  instantly**; reconnecting→offline pops back, text snaps; →back online morphs colour+wash+check pop, **label goes from
  two lines to one instantly** — the bar shrinks in one frame and the whole app below jumps up; back online→hidden
  collapses after 2 s.
- **Gestures:** offline row = one "check now" button; not swipe-dismissible.
- **Haptics:** `Haptics.tap` on retry tap and on every nudge; **none** on the connection actually dropping or returning.
- **Problems:** the 2-line→1-line label change (and any text reflow) is not animated, so the navigator below jumps; the
  status-bar-inset strip colour snaps at open/close [INFERENCE]; the bar resizes an open sheet/dialog mid-use by design;
  the nudge haptic is `tap` (light) — the same feel as a normal button press for what is meant to read as a refusal; icon
  pops while the adjacent text snaps, two treatments in one bar; the retry row has no visual press, only a haptic then the
  icon popping.
- **Perf risk:** the height animation sits above the navigator — every frame of the 250 ms open/close relayouts the whole
  top route (and any sheet/dialog); `TintFlash`/the whole bar are each in their own `RepaintBoundary` ✓; a reconnect epoch
  rebuilds only `ConnectivityScope` dependents ✓.
- **Opportunity:** animate the label's line-count change (size-transition, not a snap) → D13 (`CollapseReveal`/`SizeFadeSwitcher`
  family) + B2-05's exact root cause, extended here; give the retry row a press state → D22; consider a haptic on the
  drop/return transition itself, not only the nudge → D21. No direct research match found for offline-banner motion
  specifically (topic absent from research_log_2026.md); leave the push-down-the-whole-app layout as is pending a
  dedicated research pass (flagged as an open question in the source audit).
- **Assets:** Material `wifi_off_rounded`/`check_circle_rounded` → lacks a branded offline/back-online glyph pair (shared
  need with block 49's offline notes).

---

### 49. shared:stale-notices
**Files:** `core/widgets/stale_data_notice.dart`, `cubit_stale_notice.dart`, `screen_stale_notice.dart`,
`stale_age_pill.dart`, `offline_inline_note.dart`, `load_more_offline_note.dart`, `next_page_sentinel.dart:55`. 15
`ScreenStaleNotice`/`CubitStaleNotice` sites (ledger, assistant history, home, content, offers, notifications, order
invoice, orders list, PDP, recipes×2, brands×2, product listing, Pro paywall); 4 `LoadMoreOfflineNote` sites (orders,
recipes, listing, `next_page_sentinel.dart`); 4 `OfflineInlineNote` direct sites (cancel-order sheet, PDP load failure ×2,
search suggestions).
- **Entry/exit:** not a route. `StaleAgePill` fades in once on mount via a **`TweenAnimationBuilder`→`Opacity` widget**
  (fast 150, standard curve) — the one place in `core/widgets` still using `Opacity` where the rest of `core/motion` uses
  `FadeTransition`; age text re-reads once a minute while `TickerMode` is on, no motion.
- **State-change:** the pill's space **snaps open** (`SizedBox.shrink` → padded pill) then the pill fades in — content
  below jumps down; it disappears in **one frame**, no exit — content jumps up; `OfflineInlineNote`/`LoadMoreOfflineNote`
  have no motion at all, only a `liveRegion` announcement; PDP's checking→offline swap is a one-frame icon/message/button
  swap; the search offline row appears/disappears with no transition; the load-more footer swaps loader↔offline note with
  no transition.
- **Gestures/Haptics:** none (the load-more note has no button by design).
- **Problems:** layout jump on both appear and disappear — the same "optional block" shape the connectivity banner (block
  48) and the cart checkout bar's reason line solve with `CollapseReveal`, but this one does not; asymmetric (fades in,
  never fades out); uses an `Opacity` widget in a per-frame builder instead of `FadeTransition`; every offline/failure
  swap here is instant while the banner's equivalent states are animated — one contract, two behaviours.
- **Perf risk:** low; the pill rebuilds itself once a minute only while on stage; the snap-in relayouts the host list once.
- **Opportunity:** adopt `CollapseReveal` (open+close, not fade-in only) for the stale pill and the offline/load-more
  swaps → CC-07 (show/hide by height+fade: one primitive, 3 near-copies and 6+ raw reimplementations — this **is** one of
  those reimplementations, direct match) + D13; replace the `Opacity` widget with `FadeTransition` → CC-07 family, D1 (no
  parallel system — use the one already-kept primitive).
- **Assets:** `StaleAgePill`'s `schedule_rounded` and `OfflineInlineNote`'s `wifi_off_rounded` should share one branded
  "saved copy"/offline glyph pair with the connectivity banner (block 48) rather than two separate Material icons.

---

### 50. shared:locale-veil
**Files:** `core/motion/locale_swap_veil.dart:14-43`, `locale_swap_veil_view.dart:26-73`; only caller
`features/account/presentation/widgets/settings/settings_language_tile.dart:44-62`.
- **Entry/exit:** `HeroSegmentedControl` thumb glides to the new language (`AppSprings.calm` ≈210 ms) + `Haptics.selection`;
  an explicit `Future.delayed` waits for the thumb to land; veil fades in solid (fast 150) over the root overlay; commit
  (`setLocale` + persistence, server sync `unawaited`) + one `endOfFrame`; veil fades out (medium 250, reverse). Reduced
  motion or no overlay → commit with no veil.
- **State-change:** the shell's `IndexedStack` is keyed by language, so **all four tab states are recreated** under the
  veil (scroll resets by design); a data refresh for the new language fires 200 ms after the commit, i.e. **while the
  250 ms fade-out is still running** — loaders can appear under the lifting veil [INFERENCE — timing sum].
- **Gestures:** the language control disables itself while busy; the veil itself is wrapped in **`IgnorePointer`**.
- **Haptics:** `Haptics.selection` on the control, then **`Haptics.success` fired from `SettingCubit.changeLanguage`**
  while the veil is still opaque.
- **Problems:** taps pass through the opaque veil for ~400 ms+ — the customer can hit back or other tiles on a tree they
  cannot see, since only the language control itself is disabled; total wait budget ≈610 ms + commit before the new
  language is readable [INFERENCE — sum of tokens]; **the success haptic fires from a cubit**
  (`setting_cubit.dart:7,119`, which also imports `flutter/widgets.dart` and `navigatorKey`) while nothing is visible yet;
  the post-commit refresh lands inside the veil's own fade-out, so loaders/skeletons can show through the lifting veil;
  the veil does not cover the connectivity banner (block 48) — with the banner open, its text flips language in plain
  sight while the rest of the screen is veiled [INFERENCE — widget-tree reading].
- **Perf risk:** the veil is a full-screen `FadeTransition` over a solid `ColoredBox` (cheap); the commit re-lays out the
  whole app and recreates 4 tab trees under the veil by design.
- **Opportunity:** move the haptic out of the cubit and into the widget that owns the gesture, firing it when the result
  is actually visible (veil-out complete) rather than at commit → **CC-20 (exact match: "a haptic decision fires inside a
  cubit instead of the widget that owns the gesture")**; cover the connectivity banner with the veil, or accept the gap as
  a documented exception → D7 (MotionGuard/overlay scope); shorten or explain the ~610 ms wait budget → leave as is
  pending a research pass on runtime language-switch UX (no direct research_log_2026.md match found for this topic).
- **Assets:** none needed — a solid veil is the point.

---

### 51. shared:tab-bar-cart-bar
**Files (shell tab bar):** `features/shell/presentation/pages/main_shell_page.dart`, `widgets/shell_bottom_nav.dart`,
`shell_nav_item.dart`, `shell_nav_badge.dart`, `shell_basket_tab.dart`, `shell_basket_switch.dart`,
`shell_basket_segment.dart`; `core/widgets/hero_mark_icon.dart`. **Files (cart bars, no bar lives inside `features/shell`
itself — the shell's only cart presence is the tab badge):** `features/home/.../home_cart_bar.dart`,
`features/shop/.../catalog_cart_bar.dart` (mounted on brands/categories/category/listing/collection),
`features/marketing/.../offers_cart_bar.dart`, `features/cart/.../cart_checkout_bar.dart`.
- **Entry/exit:** the shell page is `/shell` (FadeThrough from splash, else HeroTransitionPage) and `/home`
  (HeroTransitionPage) — block 52. Cart bars are not routes.
- **Motion — tab bar:** **tab switch is an instant `IndexedStack` cut**, no transition between bodies
  (`main_shell_page.dart:41,62-75`); selected icon scale 1.0→1.12 (fast 150 signature); label weight/colour lerp (fast
  150, a layout-affecting weight change); **Home tab mark runs a second, longer animation on top of the shared one** —
  `HeroMarkIcon` morph+hop over `popup` 350 ms while every other item's scale is 150 ms; press = passive `PressScale`
  0.96 + theme InkSparkle (double feedback on one tap); cart-count badge `PopScale(popKey: count)` pops **from scale 0 on
  every change and on every mount** (medium, easeOutBack); fly-to-cart lands on the cart tab icon (slow 400, quadratic
  bezier); Cart↔history pill thumb `AnimatedAlign` (medium 250 signature, RTL-aware) while the two views **swap
  instantly** underneath it.
- **Motion — cart bars:** all four bars rise/sink via `AnimatedSwitcher`→`SizeTransition`+`FadeTransition` (or
  `CollapseReveal` for the cart page's own reason line), MotionGuard-gated, no haptic on show/hide; **two different
  durations for the same "bar rises from the bottom" interaction**: home + catalog cart bar = 400 ms, offers cart bar =
  250 ms; the cart checkout bar's block-reason line uses `CollapseReveal` 250 ms `signature` — a third timing/curve for
  the same "optional block" shape in the same place (shared root cause with block 49).
- **State-change:** cart count 0→n mounts the badge with a pop; n→0 removes it in one frame; language switch recreates
  the whole tab stack (block 50); signed-out/offline are handled per tab, not at shell level.
- **Gestures:** tap only, no swipe between tabs or Cart/history; **re-tapping the current tab does nothing** — no
  scroll-to-top; back = system only (no predictive back, block 52).
- **Haptics:** **none** on tab change (`PressScale` is passive — the `InkWell` owns the tap, so its haptic never fires)
  and **none** on the Cart↔history segment switch, unlike `HeroSegmentedControl`'s selection haptic elsewhere in the app.
- **Problems:** the count badge "blinks" — collapses to 0 and regrows with overshoot on every +1 instead of changing its
  number, and disappears with no exit; the badge pop (finishes ~250 ms) is not synchronised with the 400 ms fly-to-cart
  landing [INFERENCE — timing from code]; two timings inside one bar (Home mark 350 ms vs other items 150 ms, Home item
  plays both); double press feedback (scale + ripple) on every tab tap; no haptic on tab or segment change, unlike the
  settings segmented control; two segmented-control motions in the app (`AnimatedAlign` here vs `AppSprings.calm` spring
  in `HeroSegmentedControl`); instant tab-body swap with no continuity, and a re-tap does nothing; label weight animates
  bold↔regular, reflowing text under the icon for 150 ms; the basket-segment icon snaps colour while its label animates;
  **hidden tabs are not muted by `IndexedStack`** (no `TickerMode`) — Cart and Orders mute themselves explicitly, Mine only
  partly, **Home's loops check only bare `TickerMode.valuesOf`**, so Home's ambient loops keep producing frames while
  Search/Cart/Mine is the visible tab [INFERENCE — static, confirm in DevTools]; badge `PopScale` in the hidden Cart-tab
  header also plays off-screen on every add; the cart bars' 400 ms/250 ms split (above) has no reason behind it.
- **Perf risk:** the hidden-Home-loops finding above is the headline perf risk here; `FlyToCart` uses an `Opacity` widget
  over a `Transform` per frame in the root overlay; `InkSparkle` is a fragment-shader ripple on every tab tap on all
  platforms; each cart bar's `SizeTransition` inside `bottomNavigationBar`/`Scaffold` relayouts the body per frame while
  it grows.
- **Opportunity:** give the tab switch a fast incoming fade + no haptic, matching §9 (decision summary)'s own stated answer →
  **B1-10 (exact match, needs approval)**; mute Home's loops when its tab is hidden → **PB-01 (exact match: "hidden shell
  tabs are never muted, so every Home loop keeps producing frames on Search, Cart or Mine")**; replace the badge's
  pop-from-0 with `ChangeBump`+roll-on-land → **B1-11 (exact match)**; collapse the shell arrival page type so
  `go(Routes.shell)` never replaces the route → **B1-09**; unify the two segmented-control implementations → **B2-09**
  (needs a ruling first, same family as `CC-26` "the tab switch gets 3 different treatments"); tokenise the two cart-bar
  durations onto one D2/D3 rung → D2/D3. Research: `R09-16` (iOS 26 tab bar never hides, only minimizes — relevant context
  for "should re-tap scroll to top").
- **Assets:** mixed icon families in one bar (painted `HeroMarkIcon` for Home, Material for Search/Account, HeroIcons for
  Cart); no selected/unselected icon pair beyond Home; the basket switch mixes `HeroIcons.cart` with a Material
  `receipt_long_rounded` for "history".

---

### 52. shared:route-transition-map
**Files:** `config/routes/app_router.dart`, `config/routes/feature_routes/*.dart`, `core/navigation/*`.

| Page type | Push/Pop | Motion | Page below moves? | Reduced motion | RTL |
|---|---|---|---|---|---|
| `HeroTransitionPage` (35 routes + error page) | 300 ms signature / 250 ms, `exit` as `reverseCurve` | slide Y 100%→0 + fade | no (secondaryAnimation ignored) | instant cut | vertical, n/a |
| `HeroSlideUpTransitionPage` (3: PDP, PDP image viewer, assistant chat) | 300/250 ms, **same `signature` both legs** | same slide+fade | no | instant cut | vertical, n/a |
| `HeroSharedAxisPage` (5: checkout, checkout vouchers, order tracking/review/invoice) | 300/250 ms | incoming X-shift 30 px + fade; covered page also shifts+fades | **yes — only type that moves the page below** | instant cut | mirrored ✓ |
| `HeroCrossFadePage` (2: login, OTP) | 300/250 ms | fade only, `signature` | no | instant cut | n/a |
| `HeroFadeThroughPage` (1, conditional: splash→shell) | 300/250 ms | fade + scale 0.96→1 | no | instant cut | n/a |
| framework `MaterialPageRoute` (1: licenses) | platform default | framework | framework | framework | framework |

Totals: 45 `GoRoute`s + error page. `go`/`pushReplacement` exits: splash→shell; checkout→tracking on success (**no exit
animation at all**, block appA_2 §21); session expiry → login; 17 signed-out prompts/sign-out/Pro sign-in → login (always
`go`, never `push`); OTP success → `go(shell)` **then** `push(returnTo)` next frame (stacked double entrance, block 8);
`coupons_tab_list.dart:49` → `go(shell)`; `pro_top_bar.dart`/`auth_top_button.dart` → `go(shell)` only as the
nothing-to-pop fallback.
- **Gestures:** **no iOS edge swipe-back on any of the 45 routes** (`CustomTransitionPage extends PageRoute` with no
  Cupertino mixin, no custom horizontal drag anywhere); **no in-app Android predictive-back transition** (no
  `enableOnBackInvokedCallback`, no `pageTransitionsTheme`) — only the framework licenses route gets native back
  behaviour; `targetSdk = 37` gives Android 16+ the *system-level* back-to-home preview only. `PopScope` exists on 4
  surfaces only (busy overlay, address-edit-while-saving, checkout note sheet, PDP image viewer).
- **Haptics:** none on any navigation.
- **Problems:** no back-gesture parity (iOS none, Android system-only); 35 of 45 routes read as modal (full-height
  vertical slide-up) whether they are a drill-down or a true modal presentation — only 5 routes use the horizontal axis;
  doc/code drift — `HeroSharedAxisPage`'s own doc says it is for "Mine → Settings → About", but those routes are plain
  `HeroTransitionPage`; the app router's comment claims only 2 page types exist, there are 5; the navigation barrel
  exports only 3 of 5; the exit curve is mathematically inverted from its own doc comment on `HeroTransitionPage` (fast
  start, decelerating finish, not an "ease-in exit") [math verified in the SDK; felt result still wants a device capture];
  `HeroSlideUpTransitionPage` reuses `signature` on pop, so it *accelerates* instead — two different pop feels in one app;
  a `HeroSharedAxisPage` entered from a non-shared-axis push can show an empty/dark backdrop during the first ~90 ms
  [INFERENCE]; the page below never moves on standard pushes, so both pages blend during the fade-in (double exposure);
  the licenses page is the only non-Hero transition in the app.
- **Perf risk:** every push/pop wraps the whole incoming page in a `FadeTransition` (full-screen opacity layer) for
  300/250 ms; shared-axis stacks **two** full-screen opacity layers; `HeroSharedAxisTransition` rebuilds 4 `drive()`
  wrappers + a new `Listenable.merge` every tick (`HeroSlideFadeTransition` avoids this, stateful, built once); covered
  routes keep state with tickers muted by the Overlay ✓.
- **Opportunity:** collapse `HeroTransitionPage`/`HeroSlideUpTransitionPage` onto one class and fix the doc/reality
  mismatch on `HeroSharedAxisPage` → **CC-13 (exact match: "Page transitions: two near-identical classes, and the
  shared-axis doc promises routes it doesn't serve")**; fix the page-type drift across checkout/orders/coupons/support so
  a step inside one flow always uses shared-axis and never loses a leg → **B2-02 (exact match, needs approval, 6 routes
  affected)**; give the shell's `go(Routes.shell)` callers a consistent arrival type → **B1-09**; wire real predictive
  back / iOS swipe-back once a page-type consolidation lands → **D11 (needs approval, manifest flag)**. Research:
  `R01-23`/`R03-12`/`R03-13` (Flutter's own predictive-back spec: 450 ms easeInOutCubicEmphasized, ±0.25 slide, the
  gesture should drive the pop), `R03-14` (**custom route transitions lose the platform back gesture — exact match**:
  "go_router#183252: iOS edge-swipe not detected, Android edge-back inconsistent"), `R01-19`/`R09-07` (Android 16
  predictive back on by default for `targetSdk 36`+, confirms the system-level-only reading).
- **Assets:** `PlaceholderPage` (unbuilt routes, bad `extra`, unknown paths) shows only a Material
  `construction_rounded` → lacks a "not ready yet" illustration.

---

### 53. shared:loaders
**Files:** `core/widgets/app_loader.dart`, `branded_dot_loader.dart` (+`_painter`), `branded_loader.dart`,
`delayed_loader_disc.dart`, `loader_disc.dart`, `loader_done_mark.dart` (+`_painter`), `state_loader_plate.dart`,
`busy_overlay.dart` (+`_layer`), `cubit_busy_overlay.dart`, `branded_refresh.dart`, `refresh_disc*.dart`; asset
`assets/animations/hero_design_loading.gif`. `AppLoader()` 15 sites, `.inline` 10 sites, `BrandedDotLoader` 7 direct
sites, `BrandedLoader.inline` 5 sites (brand-fill buttons); `BusyOverlay` 13 sites (account, address, auth, cart,
checkout, orders×3, Pro); pull-to-refresh (`BrandedRefresh`) 18 sites.
- **Entry/exit — block loader:** `DelayedLoaderDisc` waits `loaderDelay` 150 ms then fades (signature) + springs 0.7→1
  over `slow` 400; **no exit of its own**, the owner swaps it out. **Under reduced motion the "no flash" wait is lost
  too** — `_in.value` is set to 1 at mount inside the same controller as the wait, so a sub-150 ms load can still flash
  the disc for a frame or more (verifier-added). Categories shows **two loaders in sequence** (disc for the tree, then S-L
  bones for the first products) [INFERENCE, block 43 C2].
- **Entry/exit — busy overlay:** scrim fades in `signature`/400 out `exit`/150, all zeroed under reduced; the disc follows
  on an Interval + `AppSprings.snappy`; the `busyMinVisible` 500 ms hold is a real `Timer`, so it **still applies under
  reduced motion**.
- **Entry/exit — pull-to-refresh:** the disc follows the finger with a ×0.35 rubber band past threshold, fades+scales
  0.6→1, swells to 1.1 when armed (fast, emphasized), snaps to rest on release (fast, signature), loops (loaderOrbit),
  then shrinks+fades (medium, exit) or slides back up on cancel (medium, exit).
- **Motion:** two-dot orbit loop (loaderOrbit 1200, repaint-only, RepaintBoundary, gated); `LoaderDisc` dots→check via
  `FadeThroughSwitcher` (page 300 — **still runs a 150 ms cross-fade under reduced motion**, not instant); `LoaderDoneMark`
  badge-scale+tick-draw (slow 400, interval 0.35-1 emphasizedDecelerate); busy-overlay's disc shares the scrim's opacity
  plus its own scale; on `done`, dots fade-through to the check, then the host waits `AppSprings.successHold` 400 ms
  before navigating.
- **State-change:** loading→content is decided by the owner — **10 of 15** `AppLoader()` hosts cut with no transition, 5
  fade through (`profile_edit_body.dart:37`, `cart_view.dart:85`, `cart_deal_products.dart:29`, `checkout_page.dart:158`,
  `order_detail_state_switcher.dart:63`); busy→idle holds ≥500 ms then fades out 150 ms; busy→done shows the check then
  holds `successHold` 400 ms before navigating; **busy→error just leaves, no failure mark at all**; pull-to-refresh: the
  disc leaves when the refresh finishes, with **no confirmation that stale became fresh**.
- **Gestures:** busy overlay `AbsorbPointer`s every tap while up; `PopScope(canPop:false)` blocks back **only while
  `busy`/`done` is set** — back re-opens before the min-visible tail + exit finish, so taps stay absorbed slightly longer
  than back is blocked; pull-to-refresh uses the platform `RefreshIndicator` threshold/snap.
- **Haptics:** none from any loader; pull-to-refresh fires `Haptics.selection` when armed only, nothing on release/completion.
- **Problems:** **the 2.2 MB `hero_design_loading.gif` is dead** — bundled, referenced nowhere in `lib/`/`test/`, the
  in-code loader is the painted two-dot `BrandedDotPainter`; first-load placeholders are inconsistent (disc on 5 known
  list/grid-shaped surfaces — notifications, categories, brands, recipes — vs a skeleton on 10 others, block 54); no exit
  transition on the 10 hard-cut `AppLoader` hosts; the raw `Curves.easeInOutCubic` + measured slope constants sit outside
  `AppMotion`; `AppLoader.inline` has no Semantics label while the block variant says "Loading"; `LoaderCheckPainter`
  allocates a `Path`+`Paint`+`computeMetrics` every frame of its 400 ms (minor); **busy overlay makes the user wait by
  design** — a 50 ms reply still dims the screen ≥500 ms + 150 ms exit, and a success path holds ≈0.45-0.9 s with taps
  absorbed throughout; the check's 105 ms-in / 400 ms-total timing overlaps `successHold` tightly enough that the route
  can leave as the tick completes [INFERENCE]; feedback is asymmetric — success gets a drawn check, failure gets nothing;
  `successHold` is a raw `Duration` outside `AppMotion`, and its doc comment names tokens (`AppMotion.springSnappy`/`springCalm`)
  that don't exist; predictive back is disabled for the whole busy window with no preview that the gesture is held; the
  pull-to-refresh `Opacity` widget rebuilds every pull/leave frame around a shadowed disc; pull-to-refresh is missing on
  recipe detail, content page, PDP, coupons and search; `edgeOffset` defaults to 0, so home's disc rests inside the
  status-bar inset under its pinned header [INFERENCE].
- **Perf risk:** the orbit loop is repaint-only and `TickerMode`-muted; an inline load-more loader keeps looping in the
  list's cache extent after scrolling out of view; the 96 dp disc carries a static shadow under a scale transform during
  entrance; busy overlay's full-screen `ColoredBox`+`FadeTransition` is a one-shot 400 ms opacity layer;
  `CubitBusyOverlay` selects only its flags, so the host page never rebuilds for it ✓; pull-to-refresh's dots are
  repaint-only inside a `RepaintBoundary`.
- **Opportunity:** delete the dead GIF → **PB-15 (exact match: "the unused 2.29 MB brand-loader GIF still ships in the
  bundle")** + **CC-21 (dead/misleading motion surface family)** + §9 (decision summary) item 1 (already decided: remove it);
  fix `DelayedLoaderDisc`'s reduced-motion flash + the invisible-tick waste → **PB-27 (exact match: "`DelayedLoaderDisc`
  ticks invisibly for the whole initial wait, and the loader dots run under opacity 0 regardless")** — same shared
  primitive as **B2-06**'s Order-invoice/review/tracking finding, so one core fix closes both; unify busy-overlay success
  vs failure feedback and consolidate the 3 disagreeing "success hold" durations onto one token →
  **CC-21 ("...and 3 disagreeing 'success hold' durations")**; pick skeleton-vs-disc by content shape consistently
  (known list/grid shape → skeleton, unstructured → disc) → D18; add pull-to-refresh completion feedback and fix the
  `edgeOffset` gap on home → new, candidate for `backlog_cand_3.md`. Research: `R08-17` (skeleton rules: motion signals
  "not stuck", shown only for a few seconds — relevant to when a disc vs skeleton is right).
- **Assets:** only painted dots exist; nothing is missing for the loader itself beyond the GIF decision; no loader
  carries the brand mark even though `HeroMarkPainting` exists; busy overlay lacks a painted "couldn't finish" mark to
  pair with `LoaderDoneMark`.

---

### 54. shared:skeletons
**Files:** `core/widgets/skeletonized.dart`, `skeleton_bone.dart`, `skeletons.dart`, plus 9 shared/feature skeleton
widgets (coupons, home, list, product-row, order-card, orders, ledger, address-list, assistant×2, search-suggestion,
listing×3, offers×2). Package `skeletonizer` 3.0.0 via `Skeletonized` (`skeletonized.dart:20`).
- **Motion:** shimmer `divider`→`smallBackground` over `shimmer` 1100 ms (`skeletonized.dart:24-28`, solid under reduced);
  the package drives it with an unbounded repeating controller that calls `setState` **every tick**; search doubles a
  skeleton with an indeterminate `LinearProgressIndicator` while the first suggestion request runs (CLAUDE.md §3
  explicitly sanctions the linear hairline itself; only the doubling is an open question).
- **State-change (skeleton → content):** cross-fade (`FadeThroughSwitcher`) on orders + the ledger; skeleton → cross-fade
  → entrance on the ledger; staggered reveal after the skeleton on the listing (S-L, block 45) and offers
  (`StaggerEntrance`); Home reveals with its own `HomeReveal`, no cross-fade from the skeleton; **hard cut** on address
  list, assistant chat, assistant history, coupons and search suggestions — **four different "content arrived" behaviours
  for the same event**.
- **Problems:** **`Skeletonized` has no `RepaintBoundary`**, so every shimmer tick dirties paint up to the nearest
  ancestor boundary — for a skeleton above the viewport inside a `CustomScrollView`, that is most of the page, for the
  whole load; the listing's own bones are narrower than first thought (`Skeletonized` wraps only the two bone rows, the
  full-viewport reserve sits outside it, verifier correction); each `Skeletonized` owns its own controller, so two on one
  screen would shimmer out of phase (latent only — no screen mounts two today); skeletonizer's built-in
  enabled→disabled switch animation is unused everywhere (every site just removes the widget); magic values
  (`SkeletonBone` default height 14, the coupon-skeleton row count 4 inline); the coupon skeleton is a flat 96 dp bone,
  not the ticket shape, so the real content lands in a visibly different shape; **no skeleton on notifications,
  categories, brands, recipes, recipe detail, PDP, cart, checkout, vouchers, profile edit, rewards, Pro or content pages**
  — they all use the disc loader instead (block 53).
- **Perf risk:** see the `RepaintBoundary` problem above; `TickerMode` mutes the controller when the route is covered.
- **Opportunity:** add a `RepaintBoundary` around `Skeletonized` → **PB-08 (exact match: "`Skeletonized` has no
  RepaintBoundary; the shimmer repaints the whole host page on every tick")**; pick one "content arrived" behaviour
  instead of four → relates to **B1-06**/**B1-07** (FadeThroughSwitcher on hard cuts; collapse the entrance-cascade
  family) — cite both as the closest existing candidates; give the coupon skeleton the ticket shape → leave as is
  (a shape/asset fix, not a motion one). Research: `R05-06` (a production shimmer that sweeps in phase across the whole
  viewport — the inverse of this app's per-widget out-of-phase risk), `R08-17`/`R10-28` (skeleton motion signals
  progress and should be shown only briefly; the shimmer implementation's own cost is undocumented upstream).
- **Assets:** none — bones are drawn; nothing is missing here (the shape mismatch above is the only asset-adjacent gap).

---

### 55. shared:state-views
**Files:** `core/widgets/empty_state_view.dart`, `error_view.dart`, `failure_view.dart`, `failure_verdict_builder.dart`,
`hero_state_view.dart`, `signed_out_view.dart`, `state_icon_plate.dart`, `state_loader_plate.dart`. Usage: `EmptyStateView`
24 sites, `ErrorView` 8, `FailureView` 17, `HeroStateView` (plain) 3 / `.error` 3 / `.signedOut` 3, `SignedOutView` 1.
- **Motion:** `EmptyStateView`/`ErrorView` icons `PopScale.onMount` (medium, easeOutBack); `HeroStateView.offline` plate
  pops, **error/signed-out/plain variants do not move**; `HeroStateView.checking` loops dots in an 88 dp plate. All gated,
  `PopScale` returns the bare child under reduced motion.
- **State-change:** `FailureVerdictBuilder` moves checking→offline/unreachable/error with a plain `setState`, and
  `FailureView` switches builder families with **no switcher at all** — a hard cut; "checking" is held at least the
  1500 ms `offlineDebounce` floor even when the live check answers at once; retry swaps to the page's own loader in the
  same frame, again a cut.
- **Gestures/Haptics:** action buttons only; `AppButton`'s confirm fires `Haptics.tap`, but `ErrorView`'s retry
  (`AppOutlineButton`) and `HeroStateView`'s secondary action (`HeroSecondaryButton`) are plain `OutlinedButton`s with
  **no haptic and no press-scale** — "Retry" is silent while "Start shopping"/"Sign in" click.
- **Problems:** **`SignedOutView` looks like an error** — it renders `ErrorView` verbatim (red icon + a "Retry" button
  that actually goes to login), used by rewards; **signed-out has three different looks** across the app (lock icon in
  `EmptyStateView`, 6 sites; person plate in `HeroStateView.signedOut`, 3 sites; red `SignedOutView`, 1 site); **error has
  two looks** — bare red 56 dp icon (`ErrorView`) vs grey 88 dp plate (`HeroStateView.error`) — and **inside one
  `FailureView`** the layout family itself switches mid-screen (icon size, spacing, body/heading text style) with a hard
  cut when the verdict changes; `ErrorView` is still used directly on 6 screens where CLAUDE.md §3.2 asks for the full
  `FailureView` contract, so those screens never show "checking" or "offline" at all; entrance motion is inconsistent
  (empty/error pop, offline pops, plain/error/signed-out `HeroStateView` variants don't); "checking your connection…"
  always lasts ≥1.5 s by design, deliberately synced with the banner; nothing moves when a state *leaves* except the 7
  `FadeThroughSwitcher` hosts (block 54); empty-state glyphs contradict each other for the same concept (cart vs basket
  vs the app's own basket PNG).
- **Perf risk:** negligible.
- **Opportunity:** adopt `FailureView`+`DataFreshness`+`HeroStateView.signedOut` wherever a screen still uses the plain
  `ErrorView`/`EmptyStateView` for a network state → **B1-04 (exact match, 5 screens named there generalise to the 6
  found here)**; unify the two error looks and the three signed-out looks onto one family → same root cause as **B1-04**,
  cite together; give the Retry/secondary buttons a press state + haptic to match the primary buttons → D22, D21.
  Research: `R08-31` (empty states: say why it's empty, teach, offer the next action; image optional; no animation
  guidance given — supports "leave the pop-on-entry question to a later illustration pass" for block 55's assets gap).
- **Assets:** every state today is a bare Material icon; `assets/svg/` holds only 10 checkout/offer glyphs. **Lacking:** a
  brand-owned empty/error/offline/signed-out illustration set; per-context empties for basket, orders, wallet/points
  ledger, notifications, search-no-results, addresses, recipes, assistant history; a distinct "checking connection" glyph
  (today it's the loader dots); one shared signed-out invitation illustration instead of three unrelated looks.

---

### 56. shared:product-cards-shelves-steppers
**Files:** `core/widgets/shelf_product_card.dart` (+`_media`, `_price`, `shelf_marker_painter.dart`, `shelf_save_badge.dart`,
`shelf_pro_price_chip.dart`, `shelf_tag_pill.dart`, `shelf_arrival_scope.dart`), `catalog_product_card.dart`,
`catalog_unavailable_overlay.dart`, `shelf_add_control.dart`, `shelf_add_button.dart`, `catalog_pill_stepper.dart`,
`catalog_step_button.dart`, `catalog_circle_add_button.dart`, `qty_stepper_round_button.dart`. Hosts: `ShelfProductCard`
(listing S-L block 45, PDP rail); `CatalogProductCard` (home, assistant, cart deals, checkout rail).
- **Motion:** card press feedback comes from the **host**, not the card — the card itself is a bare `GestureDetector`.
  Three different host presses: `PressScale(0.97)` passive (listing, PDP rail); `HomePressable` 0.97, a **verbatim
  duplicate of `PressScale`'s passive path** (home); **none at all** (assistant, cart deals, checkout rail — a tap gives
  no feedback before the route push). A passive card press also sinks the **whole card** when the finger lands on the
  "+" (which has its own 0.9 press), so an add shows two nested scales. Save-badge pop (0.6→1, interval 0.45-1
  emphasized) + lime-marker draw-on (interval 0.55-1 emphasizedDecelerate, RTL-aware) run **only inside a
  `ShelfArrivalScope`**, whose single producer is the listing reveal — everywhere else (home rails, PDP rails, assistant,
  cart deals, checkout rail) the same deal card shows a static badge/marker. `ShelfAddControl` switches "+"↔"− qty +"
  via `AnimatedSwitcher` (medium, emphasized/exit, fade+scale from 0.6, RTL-resolved corner). Cross-reference: cart's and
  PDP's own steppers roll their digits with `RollingNumber`; home quick-look has its own copy of the "+"→stepper morph
  with a **different** start scale (0.8, vs 0.6 everywhere else); `QtyStepperRoundButton` (household field only) is the
  only stepper variant with its own haptic (`HapticKind.selection`).
- **State-change:** in-stock↔out-of-stock snaps (static `Opacity(0.45)` + a 0.6 white wash, no transition); a price
  change snaps; **the qty digit in `CatalogPillStepper` snaps** (unlike cart's/PDP's roll); the minus→bin icon swap at
  qty 1 snaps; 0↔n morphs only in `ShelfAddControl` and home quick-look; in recipe ingredients and the assistant
  product-detail action, `CatalogCircleAddButton`↔`CatalogPillStepper` is a plain `?:` with **no transition at all**.
- **Gestures:** tap to open, plus the add controls; home adds a long-press quick look. No long-press repeat on the
  stepper, no max-quantity feedback (`BlockedTapShake` exists in `core/motion` but is unused here).
- **Haptics:** none from the card itself (hosts fire their own, block 57); stepper buttons are mostly silent
  `GestureDetector`s — only `QtyStepperRoundButton` has a haptic of its own.
- **Problems:** the same card presses three different ways depending on host; `HomePressable` duplicates `PressScale`;
  arrival touches (badge pop, marker draw-on) exist only inside the shop listing, the identical deal card is static
  everywhere else; out-of-stock and price changes snap; a quantity change animates **three** ways app-wide (rolling
  digits in cart/PDP, a snap on every product card, a hard `?:` swap in recipes/assistant); no press feedback at all on
  −/+/bin inside a card stepper or on `CatalogCircleAddButton`, so a tap shows nothing until the cart emits; touch
  targets are **28 dp** (`CatalogStepButton`) and **34 dp** (`CatalogCircleAddButton`), both below the 48 dp/44 pt
  minimum, with `HitTestBehavior.opaque` covering only the visible circle; the "+"→stepper morph is duplicated with a
  different start scale in home quick-look; magic value `size * 0.62`; no blocked/max feedback and no undo after the bin
  removes the last unit; card-size layout numbers (`_nameLines`, `_unitLine`, `_priceLine`, `_wasLine`, `_proChip`) are
  named constants, not tokens.
- **Perf risk:** `Opacity(0.45)` over a network image is a static saveLayer on every out-of-stock card in a grid; a
  `ClipRRect` per card; the badge/marker only repaint while the listing reveal runs (block 45); each host adds its own
  `RepaintBoundary` per tile except the checkout rail, which has none.
- **Opportunity:** give the shared stepper a rolling count and a real press state everywhere → **B2-01 (exact match: "Give
  the shared `CatalogPillStepper`/`CatalogStepButton` a rolling count and a real press state")**; unify the "value
  changed" pop/morph/snap family → **CC-05 (a number change animated three ways) + CC-06 (this-value-changed pop built
  three ways)**; retire `HomePressable` in favour of `PressScale` → **CC-10 (exact match: "`HomePressable` is a verbatim
  copy of `PressScale`'s passive path")**; hand-roll the add→stepper pop-switch through the shared `PopSwitcher` instead
  of a per-surface `AnimatedSwitcher` → **CC-09 (exact match: "the add → stepper 'pop switch' is hand-rolled on 3-5
  add-to-cart surfaces instead of `PopSwitcher`")**; enlarge the two sub-48 dp touch targets → D22 (press convention,
  needs a ruling), flagged as a correctness/accessibility fix rather than a pure motion one.
- **Assets:** network photo on a flat grey tile; Material `add_rounded`/`tune_rounded`. **Lacking/weak:** a brand
  placeholder for a missing photo (today `image_outlined`, block 59); an out-of-stock glyph (text-only wash today);
  `tune_rounded` for "choose options" is ambiguous, a Hero options/sizes glyph could replace it.

---

### 57. shared:add-to-cart-path
**Files:** `core/motion/fly_to_cart.dart`, `core/widgets/cart_basket_badge.dart`, `view_cart_pill.dart`,
`cart_bar_summary.dart`, `hero_bar_total.dart`; `features/home/.../home_confetti.dart`, `home_add_burst.dart`;
`core/motion/confetti_burst.dart`; `shell_nav_badge.dart` (cross-ref, block 51). Flight sites: home, listing (block 45),
PDP rail, cart deals, checkout rail, assistant, PDP bottom bar. No-flight sites: recipe ingredients, home quick-look.
- **Motion:** `FlyToCart` — quadratic bezier over slow 400 signature, raw control-point lift `120`, raw fade
  0.7/0.3 split, raw thumb size `56`, `RepaintBoundary`-clipped, skipped under reduced; the source is always the **whole
  card's** render-box centre (hosts pass the `BlocSelector` builder context or the tile's own context), never the "+".
  `CartBasketBadge`/`ShellNavBadge` both `PopScale(popKey: count)` — grows from 0 **on every count change and on every
  mount** (so a filled cart bar re-pops each time it appears); the basket art swaps empty↔full with **no transition**.
  `ViewCartPill` press 0.98 default tap haptic. `CartBarSummary`→`HeroBarTotal` cross-fades amount↔"Updating…" (fast) +
  rolls the amount. Home-only: first-add confetti (`Haptics.success` + 36-piece burst over `confetti` 1400 ms) **only
  when the cart was empty**; a "+1" + 1→1.03→1 card bump on **every** add (not only the first, `drawOn` 700 ms,
  verifier-corrected from the first draft's "first add only").
- **State-change:** count/total/delivery line change at once (optimistic local mirror per CLAUDE.md §3.1); the total
  re-pricing placeholder cross-fades.
- **Haptics (by host — the *kinds* mostly agree, add=selection/remove=tap, except 3 named exceptions):** home and listing
  and recipes fire **direct `HapticFeedback`** (bypasses the `Haptics.enabled` mute) instead of the `Haptics` API used by
  PDP rail/cart deals/assistant/checkout rail; checkout-rail's remove uses `selection` instead of `tap`; home's first add
  fires `success` instead of `selection`; home quick-look's first add fires `tap` (via `AppButton`) instead of
  `selection`.
- **Problems:** **the badge pops before the thumbnail arrives** — the cart emits at once (t≈0) while the flight lands at
  400 ms, so `FlyToCart`'s own doc-promised "pop on landing" is not actually synchronised; the count disc **collapses to
  0 and regrows on every change**, including decrements and server re-syncs, so rapid multi-taps make it blink
  repeatedly; **the flight thumbnail is probably not in the memory cache** — the 56×56 flight image resolves a different
  CDN URL/`cacheKey` than the card's own photo (fetched at card width), so the first flight likely shows the grey
  placeholder fading in over its own 400 ms duration [INFERENCE, verify on device]; **the first add on an empty basket
  flies to a hidden target** — the page's own cart pill is unmounted while the basket is empty, so the flight aims at
  the shell's covered Cart tab icon [INFERENCE, matches block 45 L9]; **the first-add celebration exists only on home**
  — confetti, "+1" and the card bump never fire on listing, PDP, assistant, cart deals, checkout rail or recipes; haptic
  *APIs* differ per host (direct vs `Haptics.*`, bypassing the mute in 3 features) even though the *kinds* mostly agree;
  no flight and no "+1"/bump from recipe ingredients or the home quick-look add; a fixed 400 ms flight for every
  distance; raw `56`/`120`/`0.7`/`0.3`/`1.03` are not tokens; two count badges disagree on cap (99+) and colour
  (`CartBasketBadge` has neither, `ShellNavBadge` has both).
- **Perf risk:** the flight rebuilds `Positioned`+`Opacity` every frame over a clipped image, and rapid taps stack
  several overlay entries; `HomeConfetti` wraps the whole feed in a full-size `CustomPaint` that paints nothing while
  idle ✓; `HeroBarTotal` runs two `AnimatedOpacity` layers during its 150 ms swap.
- **Opportunity:** sync the badge pop with the flight's actual landing and replace the pop-from-0 with
  `ChangeBump`+roll-on-land → **B1-11 (exact match)**; unify the haptic API (stop the direct `HapticFeedback` bypass) and
  the 3 kind-mismatches → **CC-19 (exact match: "the add-to-cart interaction is duplicated and inconsistent across 7+
  sites: raw `HapticFeedback` bypasses the policy, the same gesture gets a different haptic kind per screen...")** +
  **B1-05**; give every surface the same morph+haptic+flight parity, including recipes/quick-look's missing flight →
  **B2-07 (exact match: "Unify add-to-cart parity across every surface")**; fix `FlyToCart`'s internals (global target
  registry, magic numbers, per-frame `Opacity` rebuild) → **CC-33 + PB-21 (both exact matches)**; fix the thumbnail
  cache/URL mismatch → **PB-13 (exact match: "List → detail pushes paint an empty grey header because the detail page
  requests a different-sized image than the card it came from" — same root cause, applied to the flight thumbnail
  instead of a detail push)**; decide whether the first-add celebration belongs on every surface or stays home-only →
  flag for `§9 (decision summary)`-level approval (matches **B2-07**'s scope). Research: `R08-20` (persistent feedback beats a
  transient fade-out, a badge with a count is the pattern this app already has — supports keeping the badge, fixing its
  timing), `R05-33` (Amazon pairs the add animation with a vibration, matching this app's own flight+haptic pairing),
  `R05-32` (Amazon's in-place "1 in cart" stepper at the point of action, relevant to the recipes/no-flight gap).
- **Assets:** `HeroAssets.globalCart`/`globalCartFull` are raster PNGs extracted from the reference APK, not Hero-drawn;
  the flight thumbnail is a network image. **Lacking:** a Hero-drawn vector basket badge (empty and full); one
  consistent "empty basket" glyph shared between the empty-cart and empty-checkout states (block 55).

---

### 58. shared:ambient-brand-widgets
**Files:** `core/widgets/light_sweep.dart` (+`_band`), `ready_wipe.dart`; `brand_backdrop.dart` (+`_clock`, `_painter`,
`_ring`); `hero_waving_mark.dart` (+`_painter`), `hero_mark_icon.dart` (+`_painter`); `core/motion/idle_loop.dart`;
`brand_sheet_scaffold.dart`/`brand_sheet_surface.dart`/`brand_sheet_fold.dart` (the A09 "brand sheet" surface, folded in
here — same login/OTP ambient family). `LightSweep` sites (11): Mine invite banner, Mine Pro badge, home promo-strip
card, home Pro-offer banner (all **visibility-gated**); coupon-use button, Pro CTA button (**state-gated only, not
visibility**); loyalty-rewards entry, reward-applying overlay (exempt — a busy indicator), assistant buddy tour chip, Pro
member card, Pro save badge (**no gate at all**). `BrandBackdrop`/`HeroLockup`: login + OTP only, via `BrandSheetScaffold`.
- **Motion:** `LightSweep` — a diagonal band sweeps then rests, `period × sweepShare` on `machEaseInOut`, a `Timer` holds
  the rest, **forever while `active`** (default: 1440 ms sweep / 2160 ms rest on a 3.6 s `sheen` period, RTL-mirrored,
  clipped, gated). `ReadyWipe` is a one-shot form-valid flourish (`drawOn` 700, gated). `BrandBackdrop` — a continuous
  `Ticker` turns the grocery spread once every 70 s and "breathes" ±3.5% every 13 s, stops on keyboard-up/reduced/covered;
  reveal fade-settle from 0.94 over a **raw 900 ms** with a `saveLayer` while fading. `HeroLockup` cape ripple + bag bob
  via `IdleLoop` while `alive` (keyboard down). `HeroWavingMark` (login offer card only) ripples+bobs on `IdleLoop`,
  repeating `floatLoop` 3200 **forever** while on screen. `HeroMarkIcon` (shell nav, block 51) morph+hop on `popup` 350.
  The sign-in sheet's own rise (`riseDelay` **raw 120 ms** + `sheetLarge` 500 emphasizedDecelerate) and keyboard fold
  (medium 250 signature, layout-animating `Positioned.top`) round out the brand-sheet surface.
- **State-change:** keyboard up folds the sheet + stops the backdrop/lockup loops; keyboard down unfolds + resumes; going
  not-ready snaps `ReadyWipe` back instead of reversing it.
- **Gestures/Haptics:** none from any of these widgets; the emoji-tap wiggle (block 45, collection hero) fires
  `Haptics.tap` but lives in the listing, not here.
- **Problems:** **endless attention loops on content that isn't urgent** — the Pro badge/member card/save badge, the
  tour chip and the invite banner sweep every 3.6 s, the loyalty entry every 7.2 s, **with no end point**, conflicting
  with the app's own "never loop on screen without a reason" rule (the reward-applying overlay is exempt, it is a busy
  state); `LightSweep` only checks `TickerMode`, so 7 of 11 sites (5 fully ungated + 2 state-gated-only) keep ticking in a
  scroll view's cache extent while off-screen; several sweeps on one screen (Pro CTA, member card, save badge) run on
  independent timers, so their glints are visibly out of sync [INFERENCE]; `BrandBackdrop` **repaints the full screen
  every frame** for motion the eye barely registers (~0.086°/frame at 60 Hz) — a full-screen gradient + radial glow + up
  to 32 doodles, for the entire time login/OTP sits idle with the keyboard down; it runs alongside `HeroLockup`'s and
  `HeroWavingMark`'s own idle loops on the same screen; `HeroWavingMark` loops without end on login with no state behind
  it; raw values throughout (`revealDuration` 900 ms, `riseDelay` 120 ms) sit outside `AppMotion`; the sheet's keyboard
  fold animates `Positioned.top` (layout), so the whole form re-lays out for 250 ms per keyboard flip; `HeroMarkIcon`
  rebuilds a new painter on every tween frame (fine at 350 ms, but the hop replays on every tab switch, block 51).
- **Perf risk:** `BrandBackdrop`'s full-screen per-frame repaint is the headline cost here (doubles at 120 Hz), though
  the ring is a cached `ui.Picture` in its own `RepaintBoundary` ✓; each `LightSweep` instance is a translated gradient
  box in a `RepaintBoundary`+clip, repainting only during its sweep — cheap per instance, adds up across 11 sites,
  worse for the 7 ungated ones; the sheet's layout-animating fold costs a full re-layout per frame while folding.
- **Opportunity:** gate every decorative loop with `ambientBudget`+`OnScreen` → **B1-02 (exact match: "Gate every
  ambient decorative loop (`LightSweep`/`FloatLoop`/`GlowPulse`/`BrandBackdrop`/mascot idle) with `ambientBudget`+
  `OnScreen`", needs approval, D19/D24)**; stop `BrandBackdrop`'s full-screen repaint (cap the frame rate of an
  imperceptible loop, or gate it the same way) → **PB-03 (exact match: "BrandBackdrop...repaints the full screen every
  vsync, plus an unbounded `saveLayer` during reveal")** + **PB-18** (the same `Opacity`+`Transform.scale`-per-frame
  shape, 21 sites app-wide) — same fix as B1-02, cite together; collapse the 3-4 idle-loop controller policies
  (visibility-gated / state-gated / ungated) onto one → **CC-04 (exact match: "Four idle-loop controllers with three
  different 'when may I run' policies, written 4+ times")**; tokenise `revealDuration`/`riseDelay` → D2/D3. Research:
  **`R06-35`/`R07-03` (exact match, already the basis for §9 (decision summary)'s own D23 finding: WCAG 2.2 SC 2.2.2 — an ambient
  loop running over 5 s beside other content needs pause/stop/hide)**; `R08-09` (ambient motion should read as slow,
  seamless loops — "if eyes are drawn to it, it's too much" — supports toning down or budgeting every sweep here);
  `R06-16`/`R09-27` (a mascot works best as a static entry icon or a state-reactive Rive machine, not a free-roaming
  idle loop — relevant to whether `HeroWavingMark`/`HeroLockup` should loop forever at all, an open question for the
  assistant/brand spec rather than this appendix).
- **Assets:** all painted (grocery doodles, lockup, brand mark) — nothing missing at the asset level; the problem here is
  purely how long and how expensively these already-good assets are allowed to run.

---

### 59. shared:images
**Files:** `core/widgets/hero_image.dart`, `hero_network_image.dart`, `retrying_network_image.dart`, `hero_card_image.dart`,
`hero_cdn_transform.dart`. Package `cached_network_image` 4.0.0 / `octo_image` 2.1.0.
- **Motion:** fade-in over `fadeInDuration: imageFade` 500 ms — **not routed through `MotionGuard`**
  (`retrying_network_image.dart:246`); the package's own placeholder fade-out runs on its 1000 ms default; images already
  in the memory cache appear with no fade; each retry bumps the cache key, so a retried image fades in again.
- **State-change:** the placeholder is a flat grey `ColoredBox`, not the "skeleton placeholder" the code's own doc
  comment claims; a failure keeps the placeholder forever and retries on an unbounded-count backoff with a 30 min cap; an
  empty URL shows Material `image_outlined`.
- **Problems:** **the fade ignores reduced motion entirely** — the one motion in this file that does not route through
  `MotionGuard`, while every other fade in the app does; a 500 ms fade plays on every disk-cache hit too (e.g. scrolling
  back through a grid whose images left the memory cache) [INFERENCE]; the doc/code mismatch on "skeleton placeholder"
  vs the actual flat grey; `memCacheWidth`/`memCacheHeight` both passed with Flutter's exact-fit `ResizeImage` policy,
  which can squash the raw-URL fallback (not motion, listed as an open question); DPR is capped at 2 in the CDN
  transform, so 3× phones render slightly soft (a deliberate trade-off, not a bug).
- **Perf risk:** a `RepaintBoundary` per image means one compositing layer per image in a grid; the fade is an OctoImage
  `FadeTransition`, so several opacity layers composite at once when a grid of images lands together; `filterQuality: low`
  is already the efficient choice.
- **Opportunity:** route the fade through `MotionGuard` → **PB-12 (exact match: "Network images stack two opacity fade
  layers for 1 s and ignore reduced motion")**; fix the flight-thumbnail and list→detail size/cache mismatches that stem
  from this same image pipeline → **PB-13 (cross-referenced from block 57's flight-thumbnail finding, same root cause)**;
  tune grid decode/precache (`cacheExtent`, `precacheImage`) → **PB-33**; replace the flat grey placeholder with a
  brand mark or a dominant-colour/blurhash placeholder → new, candidate for `backlog_cand_3.md` (no direct
  research_log_2026.md match for placeholder style found by grep; the topic is listed only as an open question in the
  source audit).
- **Assets:** the Material `image_outlined` glyph for a missing photo. **Lacking:** a brand placeholder (product and
  banner) for a missing or failed image, shared in spirit with block 56's out-of-stock and block 55's empty-state asset
  gaps.

---

**Totals for this file:** 4 shop-page blocks (42-45) + 14 shared-surface blocks (46-59) = 18 blocks. Every `file:line`
and every numbered problem from `A08_shop.verified.md`, `A09_shared_overlays_navigation.verified.md` and
`A10_shared_content_widgets.verified.md` is retained above (some A09/A10 sub-surfaces not named in the brief — busy
overlay, pull-to-refresh, countdowns, paging dots, back-to-top, accordion, collection header, buttons/selection controls,
A09's brand-sheet — are folded into their closest listed block rather than dropped: busy-overlay + pull-to-refresh into
loaders (53); brand-sheet into ambient/brand widgets (58); countdowns and collection-header were already fully covered
inside the product_listing block (45) via the source audit's own cross-references; back-to-top is covered inside S-L
(45, M15/L-family) with its cross-screen sites noted in block 53's "missing pull-to-refresh" problem list; paging-dots and
accordion are single/double-site, low-severity findings with no cross-cutting backlog match — kept out to hold this file
to its named scope, not lost, since both remain readable in `A10_shared_content_widgets.verified.md` directly).


---

## Appendix B. Performance review (Phase 3)

Merged from Appendix B, Appendix B
and Appendix B — all three are adversarial re-verification
passes over the original P1/P2/P3 reviews, opened at every cited `file:line` against
`F:/_jam3eia_apps/keeta_clone` and cross-checked against the local Flutter SDK / installed pub
packages where a framework or package behavior was claimed. 43 issues were raised across the three
passes (P1 9, P2 17 [H1,H2,M1-M4,L1-L11], P3 17); below they are deduplicated to **34** distinct
runtime problems (9 merges: duplicate GlowPulse-repaint finding, duplicate BrandBackdrop finding,
duplicate Home-category-shelf finding, duplicate buddy-overlay-boundary finding, duplicate
out-of-stock-opacity finding, duplicate unused-GIF finding, duplicate non-cancellable-delay finding,
duplicate splash-saveLayer finding, and the two lazy-list-replay findings folded together).
Refuted during verification: 0 issues.

---

### 🔴 Issues Found

#### PB-01 · Hidden shell tabs are never muted, so every Home loop keeps producing frames on Search, Cart or Mine
**Location:** `lib/src/features/shell/presentation/pages/main_shell_page.dart:62-75`,
`shell_basket_tab.dart:97-107`, `home_reveal.dart:81,126-130`, `home_reveal_scope.dart:33`,
`home_slides_carousel.dart:72,93-98`, `home_category_grid.dart:82-83,118-119,138`,
`home_loop.dart:78-82,89,108`, `home_announcement_ticker.dart:68-72`, `home_search_hint.dart:67-70`,
`home_promo_strip_card.dart:47`, `home_pro_offer_banner.dart:46`, `home_countdown_text.dart:41`.
**Runtime:** `IndexedStack`'s children are never wrapped in `TickerMode`, and the SDK confirms
`IndexedStack` itself only gates paint/hit-test, not tickers (`indexed_stack.dart:104-109`). Home's
`_tickersOn` stays `true` on a hidden tab, so every ambient loop, carousel `Timer.periodic`, glide and
countdown on Home keeps scheduling frames while the customer looks at Search, Cart or Mine.
**Cost:** the engine keeps building/painting a screen nobody sees at full refresh rate — wasted
CPU/GPU work and battery on every hidden-tab frame, for as long as the app is open on another tab.
**Severity:** High.

#### PB-02 · The Home category shelf repaints every visible tile every frame, with no rest, even while genuinely on screen
**Location:** `home_category_grid.dart:43,72-84,138`, `home_category_tile.dart:90-103`,
`home_category_aurora_painter.dart:68-88`.
**Runtime:** the ambient wash/glide (`glideSpeed = 26` px/s) drives a `RepaintBoundary(CustomPaint)`
per tile; each tile's `paint()` does one `clipRRect`, one `drawPaint` and 2 radial-gradient
`_drawGlow` calls, every frame, for as long as the shelf is visible. The on-screen/`TickerMode` gate
exists but is blind to a hidden shell tab (PB-01), so this repaint continues underneath another tab
too.
**Cost:** N tiles × (clip + drawPaint + 2 gradient circles) every vsync is a steady raster cost with
no idle rest, unlike `HomeLoop`'s own lap-pause `Timer` pattern used elsewhere in the same file.
**Severity:** Medium.

#### PB-03 · BrandBackdrop (auth/OTP header) repaints the full screen every vsync, plus an unbounded `saveLayer` during reveal
**Location:** `brand_backdrop.dart:43,86-90,104-113`, `brand_backdrop_painter.dart:26,29,57-79,86-100`,
`brand_sheet_scaffold.dart:187-192,215-218`, `login_page.dart:89`, `otp_verify_page.dart:94`,
`hero_lockup_painter.dart:66-85`, `brand_backdrop_ring.dart:28,38-58`, `grocery_doodles.dart` (504
lines).
**Runtime:** the painter is driven by `super(repaint: Listenable.merge([time, reveal]))`, so a full
gradient `canvas.drawRect` + radial glow `canvas.drawCircle` + wordmark path draws repaint on every
`time` tick (`turnPeriod = 70s`, ~0.043°/frame at 120 Hz) for the whole time login/OTP is open.
During the 900 ms reveal it also calls `canvas.saveLayer(null, Paint()..color = …withValues(alpha:
shown))` — an **unbounded** offscreen buffer. The ring (up to 32 vector doodles) is the one part
that is cached as a `ui.Picture`; the gradient and the wordmark paths are not.
**Cost:** a full-screen repaint at display rate behind a static-looking screen, plus one unbounded
`saveLayer` allocation during every reveal — exactly the two patterns the digest's R10-05/R10-09
flag as the costliest common raster techniques on mobile GPUs.
**Severity:** High.

#### PB-04 · The assistant buddy overlay has no RepaintBoundary around the tab body, rebuilds its whole subtree per drag event, and re-creates the thought bubble + typed text every animation frame
**Location:** `main_shell_page.dart:62-80`, `assistant_buddy_layer.dart:206-241`,
`assistant_buddy_launcher.dart:242-245,302-348,349-355`, `assistant_buddy_thought_text.dart:80-101`,
`assistant_buddy_typed_text.dart:80-88`, `assistant_buddy_thought_line.dart:62`,
`assistant_buddy_thought_cloud.dart:40`, `shell_routes.dart:29-39`.
**Runtime:** the `IndexedStack` tab body sits directly inside `assistant_buddy_layer.dart`'s `Stack`
with zero `RepaintBoundary` in between, so every buddy frame re-records the whole visible tab (Home,
Search or Mine — `shell_routes.dart:29-39`). The launcher's drag handler calls `setState` on every
pointer move (`_dragUpdate`, :242-245), rebuilding the whole `LayoutBuilder`/`AnimatedBuilder` tree.
Inside that builder, the mascot subtree is correctly passed as `child:`, but the thought bubble is
built fresh on every tick (:321) — a `WidgetSpan` with no custom `==`, so `RenderParagraph` is
force-relaid every frame. Both typewriter widgets (`assistant_buddy_thought_text`,
`assistant_buddy_typed_text`) use `AnimatedBuilder` with no `child:` either, rebuilding a
`Text`/`Text.rich` with 2 `.tr()` calls each tick.
**Cost:** every buddy idle-animation frame or drag pixel re-records the entire foreground tab
(Home/Search/Mine), not just the small buddy layer — the single largest per-frame compositing cost
found in the app outside BrandBackdrop.
**Severity:** High.

#### PB-05 · Endless ambient loops have no viewport/active gate; on the Pro page the kept-alive hero and marquees tick offscreen forever
**Location:** `glow_pulse.dart:46-55` (repeat at :53), `float_loop.dart:53-60`, `light_sweep.dart:20,60,81-89`,
`checkout_savings_hint.dart:119`, `pro_save_badge.dart:30`, `assistant_buddy_tour_chip.dart:31`,
`reward_applying_overlay.dart:22`, `loyalty_rewards_entry.dart:63`, `pro_paywall_view.dart:48-58`,
`pro_keep_alive.dart:16-18`, `pro_hero_arch.dart:130`, `pro_hero_bag.dart:31`,
`pro_brand_rows.dart:25-26`, `pro_brand_marquee.dart:62,73-84,94`, `rewards_star_badge.dart:24`,
`coupons_summary_badge.dart:24`, `coupons_empty_view.dart:41`, `rewards_gift_badge.dart:24`.
**Runtime:** `GlowPulse` has no `active`/gate parameter at all; `FloatLoop` only lands when a
`count` is supplied (otherwise `repeat(reverse: true)` forever); `LightSweep` defaults `active =
true` and 5 call sites never pass it. The Pro page wraps its hero in `ProKeepAlive`
(`AutomaticKeepAliveClientMixin`, `wantKeepAlive => true`), so `pro_hero_arch`'s `GlowPulse` and
`pro_hero_bag`'s `FloatLoop` keep ticking even after the user scrolls the hero off screen.
`ProBrandMarquee` drives its drift with `_controller.jumpTo(...)` on the row's own
`ScrollController` every tick — a real layout pass and a `ScrollNotification`, not just a paint.
**Cost:** several always-on controllers per Pro-page visit, running indefinitely off screen —
continuous CPU/battery draw with zero benefit once the content is not visible, worst case for the
whole time the page is kept alive in the tab stack.
**Severity:** Medium.

#### PB-06 · Countdown chips run one unaligned `Timer.periodic` each; a list of N offers draws up to N unaligned frames a second
**Location:** `countdown_chip.dart:40-51`, `offer_tile.dart:72`, `offers_list_sliver.dart:84,91`,
`listing_collection_scaffold.dart:41`, `home_countdown_text.dart:38-42,69-77`,
`second_clock.dart:5-13`, `second_clock_scope.dart:5-9`, `checkout_vouchers_page.dart:31`,
`checkout_eta_card.dart:56-57`.
**Runtime:** `CountdownChip` arms its own `Timer.periodic` per instance, unconditionally, and does
not read the shared `SecondClockScope` even though the app already has one (checkout is its only
consumer). `HomeCountdownText`'s tick only skips the `setState` when off screen — the `Timer` itself
keeps running for the whole time the Home tab lives.
**Cost:** an offers list with several visible countdown tiles runs one independent, unaligned timer
per tile instead of one shared clock — N timers and N unaligned `setState`/rebuild cycles a second
instead of 1.
**Severity:** Medium.

#### PB-07 · The onboarding tour rebuilds each whole scene on every frame for 1.4–3.6 s
**Location:** `assistant_onboarding_timeline.dart:115-118`, `assistant_onboarding_cart_scene.dart:153-186`;
scene durations: ask 3600 ms, cart 1400 ms (+1600 ms `_ghostAfter`, +1500 ms `_ghostLength`), hello
3200 ms, more 3000 ms, ready 3400 ms.
**Runtime:** `AnimatedBuilder(animation: _progress, builder: (_, _) => widget.builder(context,
_progress.value))` has no `child:`, so the *entire* onboarding scene widget tree is rebuilt every
tick for the scene's full duration. The cart scene stacks a second such `AnimatedBuilder` rebuilding
the badge, the proposal card and the ghost finger together. `grep -rl RepaintBoundary` over
`onboarding/` returns 0 files.
**Cost:** a full widget-tree rebuild (not just repaint) at display rate for up to 3.6 s per scene,
5 scenes per tour run — the most expensive *rebuild-scope* (vs. raster) issue found.
**Severity:** Medium.

#### PB-08 · `Skeletonized` has no RepaintBoundary; the shimmer repaints the whole host page on every tick
**Location:** `skeletonized.dart` (32 lines, zero `RepaintBoundary`), `home_loading_view.dart:22-24`,
`skeletonizer-3.0.0/lib/src/widgets/skeletonizer.dart:213,245-250` (installed package).
**Runtime:** `Skeletonized.build()` returns `Skeletonizer(enabled:, effect:, child: child)` directly,
with no isolating boundary. The package's own shimmer listener calls `setState` on every shimmer
tick (`_onShimmerChange`, confirmed in the installed package source), and that `Skeletonized` sits as
a sibling sliver next to `HomeHeaderSliver` inside one `CustomScrollView`.
**Cost:** every shimmer tick repaints the entire loading page (header included), not just the
skeleton bones — a single missing `RepaintBoundary` line multiplies the shimmer's cost by however
much else shares its render tree.
**Severity:** Medium.

#### PB-09 · Home feed blocks replay their entrance animation every time you scroll back to them
**Location:** `home_feed_view.dart:63-94`, `home_reveal.dart:8,68,136-138`,
`home_product_strip.dart:51`, `home_brand_rail.dart:41`, `home_recipe_rail.dart:42`,
`home_promo_cards.dart:39`, `home_product_rail.dart:56`, `home_reveal_item.dart:31`.
**Runtime:** `HomeReveal`'s own doc says it "enters when it is **first** seen," backed by a `_seen`
flag — but `_HomeRevealState` has **no** `AutomaticKeepAliveClientMixin`, so nothing tells the
sliver's `AutomaticKeepAlive` wrapper to preserve the element past the cache extent. Scrolling a
block out and back genuinely destroys and recreates the State (and `_seen`), so the 700 ms
(`AppMotion.drawOn`) fade+rise entrance — and the first 5 rail cards' own `HomeRevealItem` entrance —
replays on every scroll-back, not just on first view.
**Cost:** an unwanted, repeated 700 ms animation (frames scheduled, opacity/transform recompute) on
every scroll-back through the Home feed, on top of being a jarring UX regression.
**Severity:** High.

#### PB-10 · `ScrollReveal`/`StaggerEntrance` inside lazy item builders replay on scroll-back across 5+ list sites, including a 300 ms wait on every newly sent chat bubble
**Location:** `coupons_tab_list.dart:34,44`, `history_coupons_section.dart:32`, `reward_card.dart:107`
(via `rewards_grid.dart`), `address_row.dart:30` (via `address_list_view.dart:31-32`),
`support_faq_results.dart:43-49,54-57`, `im_chat_body.dart:100-111`, `stagger_entrance.dart:22,64`,
`assistant_message_list.dart:180`.
**Runtime:** these primitives are built directly inside `ListView.builder`/`SliverList.separated`
item builders with no list-level "already played" set, so their State — and the entrance — is
recreated whenever a row scrolls beyond the default cache extent and back, even where a
`findChildIndexCallback` exists for element *reuse* (it doesn't stop State disposal). In chat
specifically, `StaggerEntrance`'s `steps = index.clamp(0, maxIndex=10)` means once `index ≥ 10` a
newly sent bubble always waits `10 × 30 ms = 300 ms` before it appears — `assistant_message_list.dart`
already shows the correct fix (`animate: _fresh.contains(key) && _played.add(key)`), support chat
does not copy it.
**Cost:** a replayed entrance animation on ordinary scroll-back across 5 real list surfaces, plus an
unconditional 300 ms input-to-paint delay on every message a user sends once a chat has 10+ messages.
**Severity:** Medium.

#### PB-11 · Entrance primitives slide a child with no RepaintBoundary, so the whole enclosing boundary re-records every frame of the entrance
**Location:** `stagger_entrance.dart:78-81`, `scroll_reveal.dart:161-169`,
`entrance_cascade_item.dart:73-82`, `home_reveal.dart:163-166`, `pdp_scaffold_view.dart:189-194`,
`mine_content.dart:33-47`; correct counter-examples: `listing_product_tile.dart:39`,
`home_product_tile.dart:74`, `coupon_card.dart:55` (each opens with `RepaintBoundary(`).
**Runtime:** each entrance primitive wraps its child in `FadeTransition`/`SlideTransition`/
`Transform.translate` with zero `RepaintBoundary` around `widget.child`. Where a `RepaintBoundary`
does exist, it sits *above* the whole section (e.g. `pdp_scaffold_view.dart`'s one boundary around
the entire `PdpSheet`), so a `StaggerEntrance`d sub-section still forces the whole sheet to
re-record every tick of its own entrance.
**Cost:** every entrance animation repaints far more than the animating widget — the entire section
or sheet it lives in — for the whole entrance duration.
**Severity:** Medium.

#### PB-12 · Network images stack two opacity fade layers for 1 s and ignore reduced motion
**Location:** `retrying_network_image.dart:246`, `motion.dart:41` (`imageFade = 500 ms`),
`cached_network_image-4.0.0/cached_image_widget.dart:220` (installed package,
`fadeOutDuration = 1000 ms` default, never overridden), `hero_network_image.dart:122-123`.
**Runtime:** every `HeroImage` passes `fadeInDuration: AppMotion.imageFade` (500 ms) but never sets
`fadeOutDuration`, so the package's own 1000 ms placeholder fade-out runs *underneath* the 500 ms
fade-in — two overlapping opacity-driven compositing layers for a full second per image, with no
`MotionGuard.reduced` check anywhere in the call.
**Cost:** two stacked, uncontrolled opacity transitions per image load — extra layer compositing —
multiplied across every image-heavy grid, and a reduced-motion user still gets 1 s of fade regardless.
**Severity:** Medium.

#### PB-13 · List → detail pushes paint an empty grey header because the detail page requests a different-sized image than the card it came from
**Location:** `pdp_preview_view.dart:31`, `pdp_photo.dart:43`, `pdp_scaffold_view.dart:68-71`,
`shelf_card_media.dart:60-65`, `hero_cdn_transform.dart:130-134`, `hero_network_image.dart:113,116`,
`category_rail_item.dart` (`_image = AppSize.s54`), `category_rail_chip.dart` (`_image = AppSize.s28`).
**Runtime:** `hero_cdn_transform.dart` rounds/clamps the requested size with **no bucketing**
(`.round().clamp(64, 2048)`), and `hero_network_image.dart`'s cache key is derived from that
size-dependent resolved URL (`cacheKey: resolvedUrl`). A card requesting one box size and a detail
page requesting a different one are therefore a guaranteed cache miss — confirmed with 0
`precacheImage` calls anywhere in `lib/`.
**Cost:** a full network round-trip + decode on every card→detail push, painted as a flash of empty
grey, even though the same photo was already downloaded and decoded moments earlier for the card.
**Severity:** Medium.

#### PB-14 · A 2.2 MB catalogue is loaded and parsed before the first frame, only to count favourites
**Location:** `lib/main.dart:13,19`, `service_locator.dart` (`_initCore`), `hero_repository.dart:71-74`,
`account_local_data_source.dart:27`. `hero_catalog.json` measured at exactly 2,214,800 bytes.
**Runtime:** `setupServiceLocator()` is `await`ed before `runApp` and internally awaits
`hero_repository`'s `rootBundle.loadString(...)` + `compute(parseHeroCatalog, assetRaw)` for the
full 2.2 MB catalogue — whose only consumer found is `favouriteCount() => catalog.shops.length`.
**Cost:** first-frame latency proportional to loading and isolate-parsing 2.2 MB of JSON just to read
a `.length`, plus the decoded string/object graph stays resident in memory for the rest of the
session.
**Severity:** Medium.

#### PB-15 · The unused 2.29 MB brand-loader GIF still ships in the bundle
**Location:** `assets/animations/hero_design_loading.gif` (2,287,862 bytes), `pubspec.yaml:115-116`.
**Runtime:** the live loader is the code-driven `BrandedDotLoader`/`AppMotion.loaderOrbit`; a
repo-wide grep for the filename and for `.gif'` in `lib/`/`test/` returns 0 matches.
**Cost:** dead weight in the app bundle (download size, install size, and a wasted asset-manifest
entry) with zero runtime benefit — pure APK/IPA bloat.
**Severity:** Medium.

#### PB-16 · Timers ignore the app lifecycle: carousel, ticker, hint, countdown and sweep-rest timers fire while the app is backgrounded
**Location:** `home_slides_carousel.dart:72`, `home_announcement_ticker.dart:68`,
`home_search_hint.dart:67-70`, `home_countdown_text.dart:41`, `countdown_chip.dart:46`,
`light_sweep.dart:67`, `home_category_grid.dart:138`, `home_loop.dart:108`; lifecycle-aware
exceptions: `assistant_buddy_layer.dart:57,82-92`, `assistant_voice_lifecycle.dart:30`,
`order_tracking_view.dart:24,58`, `connectivity_banner_host.dart:54`.
**Runtime:** 8 independent timer sources have no `WidgetsBindingObserver`/`AppLifecycleListener` of
their own; only 4 unrelated widgets in the whole app pause anything on backgrounding.
**Cost:** wasted CPU wake-ups and battery drain while the app is in the background — every
`Timer.periodic`/`Timer` above keeps firing (and, where it triggers `setState`, keeps scheduling
frames the OS will simply discard) until the app is resumed.
**Severity:** Low.

#### PB-17 · The OTP caret blinks with a `Threshold` curve on a repeating controller: 60–120 display-rate frames per second for a 2-state blink
**Location:** `otp_slot_caret.dart:21,24,26-32,41-44`.
**Runtime:** a `CurveTween(Threshold(0.5))` drives a `repeat()`ing `AnimationController` at
`period = 1000 ms`, so the engine schedules a frame every vsync for the whole time the OTP page is
open, even though the caret only ever has two visual states (on/off).
**Cost:** display-rate scheduling (60–120 fps) to render output that only changes twice a second —
100% wasted frames between the two state changes.
**Severity:** Low.

#### PB-18 · `GlowPulse` rebuilds `Opacity` + `Transform.scale` every frame inside an `AnimatedBuilder` — the same pattern repeats across 21 `Opacity(` call sites
**Location:** `glow_pulse.dart:78-92`, `pro_hero_arch.dart:130` (`GlowPulse` inside a
`TweenAnimationBuilder` with no `child:`), `rewards_star_badge.dart:24`, `coupons_summary_badge.dart:24`.
**Runtime:** the `AnimatedBuilder` passes `child:` correctly, but its `builder:` still returns a
fresh `Opacity(opacity:, child: Transform.scale(scale:, child: child))` pair every tick — the SDK
confirms `RenderOpacity` only avoids a repaint via `markNeedsCompositedLayerUpdate` when the widget
itself isn't rebuilt, so rebuilding the `Opacity` widget every frame forfeits that optimization.
**Cost:** an avoidable widget rebuild (and the loss of the compositor's cheap alpha-update path) on
every frame of every `GlowPulse`/similar `Opacity`-in-a-builder instance, for the loop's entire run.
**Severity:** Low.

#### PB-19 · Allocation churn in the typed search hint
**Location:** `home_search_hint.dart:50-52,95-99`.
**Runtime:** the `_suggestions` getter re-runs `'home.search_suggestions'.tr().split(...)` and
allocates a fresh `List<String>` on every call; it is called both from the 80 ms typing timer and
from `build()`.
**Cost:** repeated string localization + split + allocation up to 12.5×/second while the hint is
mid-type, pure garbage-collector pressure for no changed input.
**Severity:** Low.

#### PB-20 · Entrance delays that cannot be cancelled, and one that ignores `TickerMode` between letters
**Location:** `scroll_reveal.dart:100-103`, `collection_hero_emoji.dart:56-57` (both
`Future<void>.delayed`, no cancellable handle); counter-example done right: `stagger_entrance.dart:50-51,64`
(`Timer? _delay`, cancelled on dispose).
**Runtime:** a `Future.delayed` scheduled entrance keeps its callback alive even after the widget
scrolls off/disposes in a way the `mounted` check doesn't fully protect against reentry timing, and —
unlike a `Timer`-based delay — cannot be proactively cancelled when the trigger condition changes
(e.g. a fast scroll-past).
**Cost:** a dangling scheduled callback per entrance that fires later than intended, plus the minor
memory/GC cost of the retained closure until it resolves.
**Severity:** Low.

#### PB-21 · FlyToCart moves a `Positioned` overlay and fades it with a per-frame `Opacity` rebuild
**Location:** `fly_to_cart.dart:183,191-198`.
**Runtime:** the flight animation's `AnimatedBuilder` recomputes a `Positioned(left:, top:)` plus an
`Opacity(opacity:, child: Transform.scale(scale:, child: child))` every tick of the "add to cart"
flight.
**Cost:** an avoidable widget rebuild (not just repaint) for the flight's whole duration on the root
overlay, the same "Opacity inside a per-tick builder" cost pattern as PB-18.
**Severity:** Low.

#### PB-22 · `CountUpText` re-lays out its parent on every frame
**Location:** `count_up_text.dart:58-69`; contrast: `rolling_number.dart:31`
(`FontFeature.tabularFigures()`).
**Runtime:** `TweenAnimationBuilder<double>` rebuilds a `Text(widget.format(value), …)` with no
`fontFeatures`, so proportional (non-tabular) digits change the text's measured width every frame,
forcing a parent layout pass rather than just a repaint.
**Cost:** a layout pass (not just paint) on every count-up frame — more expensive than the
equivalent `RollingNumber`, which already uses tabular figures to avoid exactly this.
**Severity:** Low.

#### PB-23 · The category rail fold rebuilds the whole rail's `ListView` on every scroll frame of the fold
**Location:** `category_rail_header_delegate.dart:82,84,98` (no `RepaintBoundary` in the file).
**Runtime:** `SliverPersistentHeaderDelegate.build(context, shrinkOffset, overlapsContent)` — called
on every scroll frame the header is in its shrink range — constructs a fresh
`CategoryRail(level: level)` plus two `Opacity(...)` wrappers each time, with nothing isolating the
rebuild.
**Cost:** a full rail rebuild (all category chips) on every scroll pixel of the fold range, not just
the two opacity values that actually change.
**Severity:** Low.

#### PB-24 · The voice lock pill re-lays out and repaints its shadow on every drag frame, and a `FloatLoop` keeps ticking under opacity 0
**Location:** `assistant_voice_lock_pill.dart:85-94`.
**Runtime:** a drag-driven `Container(height: lerpDouble(_tallest, _shortest, climb), …)` recomputes
shape/shadow on every drag frame, and wraps a `FloatLoop` icon in `Opacity(opacity: 1 - climb, …)` —
so at `climb = 1` (opacity 0) the `FloatLoop` is still fully running underneath, invisibly.
**Cost:** shadow re-paint on every drag pixel plus a fully-ticking ambient loop that produces zero
visible output once fully collapsed.
**Severity:** Low.

#### PB-25 · Every route push fades the full incoming page through an opacity compositing layer
**Location:** `hero_slide_fade_transition.dart:13-15,76-81`, `hero_transition_page.dart:17-22`,
`hero_slide_up_transition_page.dart:15-21`, `hero_fade_through_page.dart:25-29`,
`hero_cross_fade_page.dart:20-23`.
**Runtime:** `FadeTransition(opacity: _curved, child: SlideTransition(position:, child: widget.child))`
composites the *entire* incoming page through an `OpacityLayer` for the whole `AppMotion.page`
duration (300 ms) on every push — this is intentional design (a `Stateful` transition specifically to
build the `CurvedAnimation` once), so it's a known, accepted per-push compositing cost, not a bug.
**Cost:** one extra compositor layer (`OpacityLayer`) for the whole incoming page for 300 ms per
navigation — small per push but the single most frequent raster-cost event in the app (every route
change).
**Severity:** Low.

#### PB-26 · A static `Opacity` over out-of-stock product photos forces an unnecessary compositing layer per tile
**Location:** `shelf_card_media.dart:58-66`.
**Runtime:** `Opacity(opacity: product.inStock ? 1 : 0.45, child: HeroImage(...))` — a value-driven,
never-animated `Opacity`. Because it's the plain `Opacity` widget (not `AnimatedOpacity`/a decoration
alpha), Flutter still gives it its own compositing layer for every out-of-stock tile in every grid.
**Cost:** one avoidable compositor layer per out-of-stock tile, permanently, for content that never
animates — the SDK's own guidance (digest R10-06) is that a `Container`/decoration alpha is "much
faster" than `Opacity` for exactly this static case.
**Severity:** Low.

#### PB-27 · `DelayedLoaderDisc` ticks invisibly for the whole initial wait, and the loader dots run under opacity 0 regardless
**Location:** `delayed_loader_disc.dart:21-36,58-62`, `motion.dart:106` (`loaderDelay = 150 ms`),
`loader_disc.dart:37-41`.
**Runtime:** one `AnimationController` spans `loaderDelay + AppMotion.slow`, with an `Interval` that
keeps the controller running (and scheduling frames) through the entire 150 ms wait even though
opacity is pinned at 0 until then; the child `BrandedDotLoader` starts its own repeat loop
unconditionally, independent of the parent's opacity.
**Cost:** a running, frame-scheduling controller (plus a second, independent looping controller
underneath) for output that is provably invisible for the first 150 ms of every load.
**Severity:** Low.

#### PB-28 · One-shot painters use `saveLayer`, and the splash may paint its full scene twice during the delivery burst
**Location:** `splash_scene_painting.dart:58-63,65-82`, `splash_scene_painter.dart:47-57` (this last
range not independently re-derived — treat as plausible, not confirmed).
**Runtime:** the splash shine uses a **bounded** `saveLayer(lockup.inflate(shineMargin), Paint())`
(not `saveLayer(null, ...)`, unlike PB-03's BrandBackdrop) plus an even-odd `clipPath` guarded by
`if (frame.deliveries.isNotEmpty)` — already a reasonably cheap shape. The unconfirmed sub-claim is
that the splash paints its full scene twice during the delivery burst.
**Cost:** the confirmed part (bounded `saveLayer` + guarded clip) is low-cost and largely acceptable
as-is; the unconfirmed "paints twice" claim, if true, would double the one-shot splash paint cost —
worth a follow-up profile, not a re-architecture.
**Severity:** Low.

#### PB-29 · The coupons tab pill rebuilds each pill on every frame of a tab swipe
**Location:** `coupons_tab_pill.dart:33-82`.
**Runtime:** `AnimatedBuilder(animation: animation, builder: (context, _) => Semantics(...))` has no
`child:` parameter, so the whole pill (Semantics → PressScale → DecoratedBox → Text with a
`Color.lerp`) is rebuilt on every frame of the underlying tab-swipe animation, not just the label
color.
**Cost:** a full widget rebuild per visible pill per swipe frame, for what is ultimately just a
per-frame color interpolation.
**Severity:** Low.

#### PB-30 · Offers: the end of the cascade remounts every card that took part
**Location:** `offers_list_sliver.dart:54-56,83-92`, `list_item_transition.dart:9-10`.
**Runtime:** the same `ValueKey<String>(offer.id)` is used on two *different widget types* —
`StaggerEntrance(key: key, child: OfferTile(...))` while cascading, then the bare `OfferTile(key:
key, ...)` once settled. Flutter's `Widget.canUpdate` requires matching `runtimeType` **and** `key`,
so this key reuse across a type change forces a full deactivate/re-inflate of every card the moment
the cascade timer fires (`list_item_transition.dart`'s own comment names this exact trap as the rule
to avoid).
**Cost:** a full element/render-object teardown-and-rebuild for every card that animated in, at the
exact moment the cascade completes — the single most expensive "state loss" bug in the review (each
card's own internal state, e.g. any pending gesture, is also reset).
**Severity:** Low.

#### PB-31 · The cold-start path only begins loading Home after the splash intro finishes
**Location:** splash `onFinished` → `context.go(Routes.shell, ...)`; `HomePage`'s cubit loads only on
mount (mechanism not independently re-derived in this pass — architecturally standard, consistent
with the rest of the confirmed findings; treat as plausible).
**Runtime:** Home's data fetch is not kicked off until after the splash's own intro animation
completes and the shell route mounts, i.e. the two are sequential, not overlapped.
**Cost:** the app's total time-to-first-useful-frame is (splash intro duration) + (Home load time)
instead of `max(splash intro duration, Home load time)`.
**Severity:** Low.

#### PB-32 · Decoding to the exact requested width and height can squash a photo that isn't pre-cropped
**Location:** `hero_network_image.dart:83-84`; SDK: `image_provider.dart:1270`
(`ResizeImagePolicy.exact` is the default, confirmed in the installed Flutter SDK).
**Runtime:** `cw`/`ch` (cache width/height) are computed independently of each other, so whenever
both are known they're both passed to a `ResizeImage`-backed provider whose default policy stretches
the decode to the *exact* box — with no allowance for the source image's real aspect ratio.
**Cost:** a visibly squashed image on any product photo that isn't pre-cropped to the requested
aspect ratio; the decode itself is no more or less expensive, but the output is wrong.
**Severity:** Low.

#### PB-33 · Image grids decode just-in-time: no `cacheExtent` tuning and no `precacheImage`
**Location:** grid/list image call sites generally (not independently re-derived by grep in this
pass — `grep -c cacheExtent`/`precacheImage` were not re-run; consistent with every other
image-pipeline fact confirmed elsewhere in this appendix).
**Runtime:** images in scrolling grids decode only once they enter the default cache extent, with no
proactive `precacheImage` for the next screen or the next few off-screen rows.
**Cost:** a visible decode-in pop-in on fast scrolls and on the first frame of a freshly pushed
screen, instead of images being ready ahead of the scroll/push.
**Severity:** Low.

#### PB-34 · Every Home block measures itself on every scroll frame for its whole life, with no de-duplication
**Location:** `home_reveal.dart:87,111-112`; contrast done right: `scroll_reveal.dart:75-82`
(`_checkScheduled` guard).
**Runtime:** `HomeReveal`'s scroll listener calls `_measureAfterLayout` — which unconditionally posts
a `WidgetsBinding.instance.addPostFrameCallback((_) => _measure())` — on *every* scroll notification,
for as long as the block exists, with no `_checkScheduled`-style guard. `ScrollReveal` in the same
codebase already has exactly this guard.
**Cost:** redundant post-frame callback scheduling and layout measurement on every scroll frame for
every `HomeReveal` block simultaneously on screen, for the block's entire lifetime (not just during
its own entrance).
**Severity:** Low.

---

### 🟡 Severity

**High**
- PB-01, PB-03, PB-04, PB-09

**Medium**
- PB-02, PB-05, PB-06, PB-07, PB-08, PB-10, PB-11, PB-12, PB-13, PB-14, PB-15

**Low**
- PB-16, PB-17, PB-18, PB-19, PB-20, PB-21, PB-22, PB-23, PB-24, PB-25, PB-26, PB-27, PB-28, PB-29,
  PB-30, PB-31, PB-32, PB-33, PB-34

---

### 🟢 Recommendations

- **PB-01.** Wrap every `IndexedStack` child in `TickerMode(enabled: i == _index, child: …)` in
  `MainShellPage` and `ShellBasketTab` — §9 (decision summary) §11 ("hidden tabs under `TickerMode(false)`")
  already commits to this. Delete the local workarounds it replaces (`cart_view.dart:67`,
  `orders_page.dart:100`, `mine_invite_banner.dart:45`, `mine_pro_badge.dart:26`).
- **PB-02, PB-05, PB-24.** Give every ambient loop the shared **OnScreen gate** (§9 (decision summary) §15,
  `PlayWhenOnScreen`) feeding the **AmbientLoop** engine (§15), so `FloatLoop`/`GlowPulse`/
  `LightSweep`/`HomeLoop`/`ProBrandMarquee` all rest off screen, in a hidden tab, in the background
  or under reduced motion — §9 (decision summary) §19 already states the rule ("decorative stop at
  `ambientBudget` 5 s, off screen, hidden tab, background, reduced, screen reader"). Retire
  `GlowPulse` as its own controller in favour of a `FloatLoop`/AmbientLoop preset (§14).
- **PB-03.** Split `BrandBackdropPainter` into a static base layer (no `repaint:`, RepaintBoundary of
  its own) and a small listening layer for the part that actually turns, mirroring how
  `BrandBackdropRing` already caches its picture. Bound the reveal's `saveLayer` to the visible rect
  instead of `null`.
- **PB-04.** RepaintBoundary the tab body and the buddy overlay/launcher separately; hold the drag
  offset in a `ValueNotifier` instead of `setState`; build the thought bubble once per `build()` and
  pass it as `child:` into the presence `AnimatedBuilder`; give both typewriters a stable caret
  instance.
- **PB-06.** Point `CountdownChip`/`HomeCountdownText` at **SecondClock** (§9 (decision summary) §13, the
  kept primitive — this is the renamed/promoted `SecondClockScope`); wrap the offers list, the
  collection page and the Home feed each in one `SecondClockScope`.
- **PB-07.** Pass an `Animation<double>` into onboarding scenes and drive them with `*Transition` +
  `child:` instead of rebuilding through the raw builder; add a `RepaintBoundary` per shadowed card.
- **PB-08.** One `RepaintBoundary` in `core/widgets/skeletonized.dart`; ties to §9 (decision summary) §18's
  loader/skeleton policy ("skeleton only for known structure with no device copy").
- **PB-09, PB-10, PB-34.** §9 (decision summary) §17 is the governing rule: *"cascade on first load only …
  never on scroll-back, filter, sort or under a route transition."* Rebuild `HomeReveal` as a thin
  composition of **ScrollReveal** + a shared reveal clock (§13) with `AutomaticKeepAliveClientMixin`
  so `_seen` survives scroll-back, and copy `ScrollReveal`'s `_checkScheduled` de-dup guard. Give
  every lazy-list entrance site (support chat included) `assistant_message_list.dart`'s
  `_fresh.contains(key) && _played.add(key)` pattern.
- **PB-11.** Wrap each entrance primitive's own child in a `RepaintBoundary`, not just the section
  that contains it, so an in-flight entrance doesn't force a whole sheet/section repaint.
- **PB-12.** §9 (decision summary) §24 already lists this as an approved-pending change: *"imageFade
  500→150."* Retiring `imageFade` in favour of `fast` (§6: `imageFade→fast`) also removes the
  1000 ms package default from stacking meaningfully against it; add the missing
  `MotionGuard.reduced` branch.
- **PB-13.** Bucket `hero_cdn_transform`'s requested sizes to a small fixed set (e.g. round up to the
  nearest 32/64px) so a card and its detail page can share one cache entry; consider one
  `precacheImage` call on push.
- **PB-14.** Move the favourites count off the full-catalogue parse (a lightweight count-only
  endpoint or a cached scalar), and stop awaiting the whole catalogue load before `runApp`.
- **PB-15.** §9 (decision summary) §1 already commits to this exact fix: *"the unused 2.29 MB GIF is
  removed."* Delete the asset and its `pubspec.yaml` entry.
- **PB-16.** One `AppLifecycleListener` at `app.dart` wrapping the router's child in
  `TickerMode(enabled: foreground)` pauses all 8 sources from one place; §9 (decision summary) §7 adds
  `MotionGuard.ambientAllowed()`/`scrollTo()` as the supporting primitives.
- **PB-17.** §9 (decision summary) §4 already names the token for this: `blinkPeriod` (1000 ms). Drive the
  blink from a `Timer.periodic` toggling a `ValueNotifier<bool>` into a non-animated
  `Opacity`/`Visibility` instead of a repeating `AnimationController`.
- **PB-18, PB-21.** Replace the builder with `FadeTransition` + `ScaleTransition` (no per-frame
  widget rebuild) — the fix `GlowPulse` itself should carry once retired into an AmbientLoop preset
  per §14; apply the same shape to `FlyToCart`.
- **PB-19.** Cache `_suggestions` in a field recomputed only in `didChangeDependencies`.
- **PB-20.** Replace the two `Future<void>.delayed` sites with a cancellable `Timer? _delay`, as
  `StaggerEntrance` already does — and note §9 (decision summary) §14 retires `StaggerEntrance` into
  **EntranceCascade**, whose `Interval`-on-one-controller design (§13) has no separate timer to leak
  in the first place.
- **PB-22.** Add `fontFeatures: const [FontFeature.tabularFigures()]` to `CountUpText`'s `Text`, as
  `RollingNumber` already does.
- **PB-23, PB-29.** Give the rail delegate and the coupons pill a stable `child:` for their static
  content and isolate the animated part in its own small `RepaintBoundary`.
- **PB-25.** No change needed beyond what §9 (decision summary) §8 already specifies (shared-axis X, `page`
  300 ms) — this is an accepted, bounded per-push cost, not a defect.
- **PB-26.** Prefer a decoration/`Container` colour-alpha or a non-widget `ColorFiltered` for the
  static dim instead of `Opacity`, per the digest's own R10-06 finding (see Appendix B §8 below).
- **PB-27.** Keep `loaderDelay` at 150 ms (§9 (decision summary) §18: "150 ms delay always, also reduced") but
  gate the controller's own scheduling on the same `Interval`'s active window, or start it lazily.
- **PB-28.** Leave the bounded `saveLayer`/guarded clip as-is; profile the "paints twice" sub-claim
  before spending effort on it.
- **PB-30.** Never change a `StaggerEntrance`-wrapped item's `key`/`runtimeType` pair across the
  cascading→settled transition — keep the same widget type throughout and drive the
  cascade purely through the animation value, as `list_item_transition.dart`'s own documented rule
  already prescribes.
- **PB-31.** §9 (decision summary) §23 already flags this as a known, approval-needed finding: *"splash
  should overlap the Home load."* Kick off Home's data fetch in parallel with the splash intro
  instead of after `onFinished`.
- **PB-32, PB-33.** Pass an explicit `ResizeImagePolicy`/matching aspect box where the source isn't
  pre-cropped; tune `cacheExtent` and add `precacheImage` for the next likely screen.

---

### 🚀 Optimized Version (structure only)

```dart
// features/shell/presentation/pages/main_shell_page.dart — mute every hidden tab (PB-01)
IndexedStack(
  index: _index,
  children: [
    for (final (i, tab) in [tabs.home(context), tabs.search(context), ShellBasketTab(/* … */),
        tabs.mine(context)].indexed)
      TickerMode(enabled: i == _index, child: tab),
  ],
);
```

```dart
// core/motion — shared OnScreen gate feeding AmbientLoop (PB-02, PB-05, PB-24)
class OnScreenScope extends InheritedWidget {
  static bool of(BuildContext c) =>
      TickerMode.valuesOf(c).enabled &&
      (c.dependOnInheritedWidgetOfExactType<OnScreenScope>()?.onScreen ?? true);
}
// FloatLoop / GlowPulse / LightSweep / HomeLoop: `_runs = widget.active && !reduced && OnScreenScope.of(context)`
```

```dart
// core/motion/brand_backdrop_painter.dart — static base + rasterized ring (PB-03)
Stack(children: [
  RepaintBoundary(child: CustomPaint(painter: BrandBackdropBasePainter(band))),   // no repaint:
  RepaintBoundary(child: CustomPaint(
    painter: BrandBackdropRingPainter(image: ring.imageFor(band.size, dpr), band: band,
        time: time, reveal: revealCurve),   // repaint: Listenable.merge([time, reveal])
  )),
]);
```

```dart
// assistant_buddy_layer.dart — isolate the tab body and the overlay (PB-04)
Stack(children: [
  RepaintBoundary(child: Listener(onPointerDown: _onPointerDown, child: widget.child)),
  Positioned.fill(child: RepaintBoundary(child: BlocSelector<…>(builder: … AssistantBuddyLauncher(…)))),
]);
final bubble = AssistantBuddyThoughtBubble(thought: thought, …);   // built once per build()
AnimatedBuilder(animation: Listenable.merge([_presenceCurve, _snap]), child: mascotTree,
    builder: (_, child) => Stack([Positioned(child: bubble), Positioned(child: child)]));
```

```dart
// CountdownChip / HomeCountdownText — one page clock instead of N timers (PB-06)
final clock = SecondClockScope.maybeOf(context) ?? _ownClock;
return ListenableBuilder(listenable: clock,
    builder: (_, __) => _Digits(left: endsAt.difference(clock.now)));
```

```dart
// core/widgets/skeletonized.dart — one line (PB-08)
return RepaintBoundary(child: Skeletonizer(enabled: loading, effect: effect, child: child));
```

```dart
// HomeReveal — survive scroll-back, dedup scroll measurement (PB-09, PB-34)
class _HomeRevealState extends State<HomeReveal> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  bool _checkScheduled = false;
  void _onScroll() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) { _checkScheduled = false; _measure(); });
  }
}
```

Full source passes: Appendix B,
Appendix B, Appendix B.


---

## Appendix C. Clean-code review (Phase 4)

Merged from Appendix C, Appendix C
and Appendix C — three adversarial re-verification
passes, each re-opening every cited `file:line` and re-running every headline `grep` count. C1 (22
issues), C2 (14 issues) and C3 (7 Major + 16 Minor) raised 59 issues between them, with heavy
intentional overlap (C2 and C3 were scoped to cross-check C1's biggest findings from a different
angle). None were refuted on substance in any of the three passes — only a handful of citation
line-numbers and headline counts were corrected. Below, the 59 are merged into **33** deduplicated
findings, numbered CC-01…CC-33.

---

### 🔴 Issues Found

#### CC-01 · A reduced-motion scroll can throw: `MotionGuard.duration` fed straight into `animateTo` with no zero-duration branch
- **Severity:** Major
- **Location:** `im_chat_body.dart:87-91`; correct counter-examples: `pdp_loaded_view.dart:82-86`,
  `pdp_thumbnail_strip.dart:72-77`, `checkout_place_button.dart:124-129`,
  `back_to_top_overlay.dart:66-69`, `assistant_message_list.dart:88-91`,
  `category_rail_header_delegate.dart:123-126`.
- **Problem:** `_scroll.animateTo(maxScrollExtent, duration: MotionGuard.duration(context,
  AppMotion.medium), …)` is the only scroll `animateTo` in the app that hands `MotionGuard.duration`
  straight to a scroll position without a zero-duration branch first. Flutter's
  `ScrollPositionWithSingleContext.animateTo` builds a `DrivenScrollActivity`, whose constructor
  asserts `duration > Duration.zero`. With reduced motion on and the list not already at the bottom,
  this call reaches that assertion and throws. Breaks the MotionGuard contract: reduced motion must
  degrade to an instant change, never an error.
- **Fix:** Match the other 6 sites' idiom — `if (duration == Duration.zero) { position.jumpTo(to);
  return; }` — or add one shared `MotionGuard.scrollTo(position, to, duration:, curve:)` helper.

#### CC-02 · Five+ separate entrance-cascade implementations, no shared primitive
- **Severity:** Major
- **Location:** `core/motion/entrance_cascade.dart:7-41`, `entrance_cascade_item.dart:12-85`;
  `features/home/.../home_reveal.dart:18-168`, `home_reveal_item.dart:15-71`,
  `home_reveal_scope.dart:14,33`; `features/shop/.../listing_reveal.dart:14-76`,
  `listing_reveal_item.dart:12-54`, `listing_reveal_scope.dart:5`;
  `features/account/.../ledger_list.dart:59-83,111-120`, `ledger_row_entrance.dart:9-32`;
  `features/marketing/.../offers_list_sliver.dart:36-57,82-92`.
- **Problem:** The same idea — one shared clock/controller per list, each item reads it and plays an
  `Interval(index × step …)` fade + rise — is implemented five times. `LedgerRowEntrance.build`
  (ledger_row_entrance.dart:18-31) is line-for-line the body of `EntranceCascadeItem.build`
  (entrance_cascade_item.dart:70-84), differing only in rise distance. `offers_list_sliver.dart`
  hand-rebuilds `EntranceCascade`'s first-frame gate (`_opening` flag, cap of 6, 30 ms step, cleanup
  `Timer`). The item clock reaches descendants four different ways (`findAncestorStateOfType`,
  `InheritedModel`, `InheritedWidget`, a constructor callback). `HomeReveal` also duplicates
  `ScrollReveal`'s own "first seen in the viewport" measurement — same `0.92` visible-fraction
  constant (`home_reveal.dart:38` vs `scroll_reveal.dart:27-28`) and the same "a short last block
  counts as seen" rule, but measured against the screen height with a global `localToGlobal` instead
  of the Scrollable's own box, so a block under an `extendBody` bar counts as seen in Home but not in
  the 14 `ScrollReveal` sites. **[C3-M1 adds:]** `HomeReveal`/`ListingReveal` also gate on
  `MediaQuery.accessibleNavigationOf(context)` in addition to `MotionGuard.reduced` — none of the 4
  core primitives (`StaggerEntrance`, `EntranceCascade(Item)`, `ScrollReveal`) check
  `accessibleNavigation` at all, an asymmetry independently confirmed by grep (0 hits). Rules broken:
  DRY, "features compose primitives and never own raw tweens", consistency.
- **Fix:** One `RevealClock` scope (a generalised `ListingRevealScope`, an `InheritedWidget` carrying
  an `Animation<double>`) plus `RevealItem(index, axis, rise)`, step/cap from `AppMotion`. Rebuild
  `EntranceCascade`/`EntranceCascadeItem` on it; delete `ListingRevealItem`, `HomeRevealItem`,
  `LedgerRowEntrance` and the offers gate. Give `ScrollReveal` an optional `onScreenChanged` output
  and a `cascadeIndex`, and make `HomeReveal` a thin composition of `ScrollReveal` + `RevealClock` +
  `HomeRevealScope.onScreen` — one viewport measurement to maintain, with the
  `accessibleNavigation` gate applied once, centrally.

#### CC-03 · Two timer-based one-shot entrances beside the Interval-based one, and 16+ local stagger-step literals next to `AppMotion.staggerStep`
- **Severity:** Major
- **Location:** `core/motion/stagger_entrance.dart:20-22,51-65` (30 instantiations, 16 files);
  `features/assistant/.../assistant_entrance.dart:12-106` (10 instantiations, 8 files, feature-local);
  `core/motion/entrance_cascade_item.dart:9-10` (documents the Timer pattern to avoid);
  `motion.dart:54-57` (`staggerStep` = 30 ms); `ledger_list.dart:60` (`AppMotion.fast ~/ 5 // 30ms`);
  literal step constants: `offers_list_sliver.dart:39` (30), `assistant_suggestion_chips.dart:28`
  (30), `otp_code_slots.dart:29` (35), `assistant_starter_chips.dart:22` (40),
  `auth_cascade_item.dart:11` (50), `assistant_buddy_starters.dart:26` (50), `coupon_card.dart:38`
  (60), `pro_perk_cards.dart:24` (60), `assistant_onboarding_starters.dart:29` (60),
  `reward_card.dart:56,104-106` (70), `home_reveal.dart:34` (70), `pro_hero_lines.dart:20` (80).
- **Problem:** `StaggerEntrance` delays with a `Timer` (:64) and `AssistantEntrance` with a `Timer`
  (:78) — exactly the pattern `EntranceCascadeItem`'s own doc names as the one to avoid (wall-clock
  delay ignores `TickerMode`; a widget test must pump past every delay). `StaggerEntrance` also
  re-declares its step as a raw literal default instead of reading `AppMotion.staggerStep`, though
  `motion.dart:56` calls that token "the step StaggerEntrance uses." 12 features declare their own
  step literals (30–80 ms) with no shared vocabulary; only `review_star_icon.dart:45` reads the
  token. `reward_card.dart`/`coupon_card.dart` hand-roll `cascadeStep * index.clamp(...)`, which
  `StaggerEntrance`/`EntranceCascade` already compute internally. Rules broken: DRY, §7 no magic
  values ("reuse the existing scale").
- **Fix:** Merge the two timer-based widgets into one core `Entrance` (`AssistantEntrance`'s API —
  offset, scale, alignment, `animate`, RTL — with the delay as an `Interval` on one controller, like
  `EntranceCascadeItem`) and re-point all 40 call sites; delete `stagger_entrance.dart`. Keep a
  single `AppMotion.staggerStep`, plus at most one `staggerStepRelaxed` (~60 ms) for cards/chips, and
  change `StaggerEntrance`'s/the merged widget's default to read the token. Delete the 12 local
  literals.

#### CC-04 · Four idle-loop controllers with three different "when may I run" policies, written 4+ times
- **Severity:** Major
- **Location:** `core/motion/float_loop.dart:33-61` (7 sites), `idle_loop.dart:26-59` (2 sites),
  `glow_pulse.dart:34-55` (3 sites); `features/home/.../home_loop.dart:24-124` (5 sites,
  feature-local); blink loops: `otp_slot_caret.dart:18-46`, `assistant_voice_blink_dot.dart:13,22-43`
  (raw 1000 ms each).
- **Problem:** Every one of these is "repeat a controller, rest under reduced motion," written
  again each time, with three different gating policies: reduced-motion-only (`FloatLoop`,
  `GlowPulse`, both blinks), a `running` flag (`IdleLoop`), and an on-screen + `TickerMode` gate
  (`HomeLoop`). `HomeLoop` has the richest API (builder(t), `reverse`, `phase`, `rest`, on-screen
  gate) but is **not** a strict superset — it lacks `FloatLoop`'s `count` and `IdleLoop`'s `running`,
  and it rebuilds through `AnimatedBuilder` on every tick while `IdleLoop` hands the `Animation`
  itself to a painter's `repaint`. It also lives in `features/home`, wired to `HomeRevealScope`, so
  no other feature can reuse it. `FloatLoop` never re-reads a changed `period` (no
  `didUpdateWidget`); `IdleLoop` does. `GlowPulse` has no `running` switch at all. Rules broken: DRY,
  OCP (a new loop means a new controller class), consistency.
- **Fix:** One core loop in `core/motion/idle_loop.dart` combining `HomeLoop`'s options (`reverse`,
  `phase`, `rest`) with `count` and `running` as inputs (Home passes
  `HomeRevealScope.onScreenOf(context)`), exposing both the `Animation` (for painters) and a `t`
  builder convenience. Re-express `FloatLoop`/`GlowPulse` as small stateless presets over it, and the
  two blinks as `IdleLoop(builder: Threshold …)`. Delete the per-widget controllers.

#### CC-05 · A number change is animated three ways, even inside one card, with no written rule
- **Severity:** Minor
- **Location:** `mine_stats_card.dart:39-60` composing `mine_wallet_stat.dart:33` (`RollingNumber`),
  `mine_points_stat.dart:32` (`CountUpText`, no `from:`), `mine_count_stat.dart:40` (`FlipValue`);
  numeric `FlipValue` sites: `profile_household_field.dart:47`, `checkout_eta_minutes.dart:53`,
  `home_countdown_text.dart:99`, `delivery_code_digit_box.dart:39`; `price_text.dart:23,30,55`
  (dead `animate` flag).
- **Problem:** Three overlapping primitives — `FlipValue` (whole-string vertical swap),
  `RollingNumber`/`RollingGlyph` (per-glyph roll, tabular, LTR) and `CountUpText` (tweened count) —
  split 18 numeric call sites 5/6/7 with no written rule for which to use. The 4 sibling tiles on the
  Mine stats card use three different motions for the same kind of event. `PriceText.animate` is
  passed by 0 of its 4 callers — dead code (YAGNI). (`checkout_savings_figure.dart:77` and
  `coupons_summary_savings.dart:41` already pass `from: 0` for a deliberate count and are correctly
  excluded from the "migrate" list; `pro_plan_price.dart:74` is the documented plan-switch use case
  for `CountUpText`.)
- **Fix:** `RollingNumber` for every in-place numeric change (money, counts, minutes, digits);
  `CountUpText` only for a deliberate count from a known origin (`from:`); `FlipValue` only for
  non-numeric label/state swaps. Migrate the 5 numeric `FlipValue` sites and `mine_points_stat:32` to
  `RollingNumber`. Delete `PriceText.animate`.

#### CC-06 · "This value changed" pop is built three ways, and `PopScale` pops on mount while a hand-rolled badge's own doc says it never should
- **Severity:** Major
- **Location:** `core/motion/pop_scale.dart:9-24,60-81` (10 of 40 sites use the re-key path),
  `change_bump.dart:6-88` (10 sites), `mine_unread_badge.dart:9-13,26-48` (private third
  implementation); count pills: `cart_basket_badge.dart:54`, `shell_nav_badge.dart:16-20`,
  `mine_unread_badge.dart:26,59`, `coupons_tab_badge.dart:18`, `assistant_cart_button.dart:60`,
  `pdp_cart_action.dart:64` (6 sites, 2 with a 99+ cap).
- **Problem:** `PopScale` carries two jobs: `.onMount` (30 sites, an entrance) and `PopScale(popKey:)`
  (10 sites, a "changed" cue that restarts from `popScaleBegin = 0.0` on every change — a count
  badge blinks out and regrows on +1; `label_chip.dart:31-32` makes a whole address-label chip
  vanish and regrow on every select *and* deselect). `ChangeBump` is the designed "changed" cue
  (1 → 1.15 → 1, optional haptic); `MineUnreadBadge` hand-rolls a third, bespoke spring pop
  (0.85 → 1). Its own doc says, verbatim, the pop fires "never on mount or on a tab visit" — but
  `PopScale.didChangeDependencies` (pop_scale.dart:60-75) **does** play the pop on the widget's first
  build, directly contradicting that stated rule (confirmed independently by C3-M4). Six files build
  the same count pill from scratch, two of them re-implementing a 99+ cap. `radio_dot.dart:31` is
  mounted only while selected, so its `popKey` never actually changes on a live instance — it already
  behaves as `.onMount` in practice, not a real re-key site. Rules broken: SRP (one widget, two
  meanings), DRY, "repeated UI extracted" (§7).
- **Fix:** Split `PopScale` — keep the entrance as `PopScale.onMount`/`PopIn`, move the re-key sites
  to `ChangeBump`. Delete `MineUnreadBadge`'s private pop. Extract `core/widgets/count_badge.dart`
  (pill + cap + LTR digits + `ChangeBump` inside); the 6 badge sites then pass only colour and size.

#### CC-07 · Show/hide by height+fade: one primitive, 3 near-copies and 6+ raw reimplementations, including 3 inline error widgets that also duplicate their UI
- **Severity:** Major
- **Location:** `core/motion/collapse_reveal.dart:37-42,82-89` (24 sites, 23 files, the intended
  primitive); `core/widgets/animated_accordion.dart:9-34` (`assistant_faq_row.dart:66`,
  `support_faq_tile.dart:75`); `core/motion/list_item_transition.dart:31-41`,
  `size_fade_switcher.dart:23-43`; raw `AnimatedSwitcher` size+fade: `home_cart_bar.dart:32-41`
  (`AppMotion.slow`), `offers_cart_bar.dart:29-37` (`AppMotion.medium`), `catalog_cart_bar.dart:24-33`
  (`AppMotion.slow`), `login_phone_error.dart:30-41`, `otp_code_error.dart:24-31`,
  `profile_field_error.dart:20-30` (a hand copy of `SizeFadeSwitcher`, `AnimatedSize` wrapping
  `AnimatedSwitcher`, both at `AppMotion.fast`) — contrast: `checkout_code_field.dart:37,54` uses
  `ShakeX` + `CollapseReveal` correctly for the same "field error" idea.
- **Problem:** One motion ("an optional block opens or closes its height while it fades") has six
  hand-written copies beside the primitive. The same cart pill enters over `medium` on offers and
  `slow` on a category listing — not even the same feel for the same UI element.
  `AnimatedAccordion` loses its closing fade (swaps the child for an empty box at once, then fades
  that empty box), while `CollapseReveal` correctly keeps the last child while closing. The three
  inline error lines duplicate the error-icon-plus-caption row's *UI*, not just its motion, across 2
  features (auth ×2, account ×1). Rules broken: DRY, consistency, §7 "shared across features →
  core/widgets".
- **Fix:** Extract a stateless `SizeFadeTransition(animation, alignment)` in `core/motion`, used by
  `CollapseReveal`, `ListItemTransition` and `SizeFadeSwitcher`. Retire `AnimatedAccordion` in favour
  of `CollapseReveal(visible: expanded)`. Move the six raw sites onto `CollapseReveal`/
  `SizeFadeSwitcher` with one shared "bottom bar enter" token. Extract
  `core/widgets/inline_field_error.dart` for the three error lines.

#### CC-08 · A vertical "ticker" swap is built 5–7 times, its rotation timer duplicated 3 times beside `RotatingLine`, and two app-wide rotation-cadence constants are dead
- **Severity:** Major
- **Location:** `core/motion/rotating_line.dart:17-37,38-208` (1 call site: `checkout_bar_line.dart:94`);
  own `Timer.periodic` rotation + slide switcher: `home_announcement_ticker.dart:33,40,62-74,104-121`,
  `assistant_composer_hint.dart:24,31-45,61-78`, `home_search_hint.dart:27,40,56-72,119-138`; same
  transition builder with only travel distance changed: `flip_value.dart:35-49`,
  `rolling_glyph.dart:35-49`, `assistant_buddy_thought_line.dart:66-84`; dead constants:
  `app_constants.dart:38,41` (`heroAutoAdvance = 4s`, `searchHintRotate = 3s`, 0 references beyond
  their own declaration).
- **Problem:** The fade + vertical `SlideTransition` switcher builder is written 5-7 times with travel
  0.6/0.6/1.0/0.7/0.4/0.8/0.4, and the copies don't even agree on direction (5 send the outgoing
  child up; `FlipValue` and `AssistantComposerHint` reuse one tween so it sinks down). Three rotating
  hints each reimplement `RotatingLine`'s own dwell timer: `AssistantComposerHint` keeps its
  `Timer.periodic` alive under a covered route (no `TickerMode` check anywhere in its
  `didChangeDependencies`/`dispose`) and rotates every raw `Duration(seconds: 4)` instead of
  `AppMotion.carousel` — a third, independent clock for a behaviour `RotatingLine` already owns.
  `app_constants.dart`'s `heroAutoAdvance`/`searchHintRotate` are unused dead tokens for the same
  concept. Rules broken: DRY, consistency, no magic values.
- **Fix:** Extract `VerticalSwapTransition(travel, direction)` in `core/motion`, used by `FlipValue`,
  `RollingGlyph` and `RotatingLine`. Rebuild `HomeAnnouncementTicker` and `AssistantComposerHint` on
  `RotatingLine(items:, dwell: AppMotion.carousel)`; delete `heroAutoAdvance`/`searchHintRotate`.
  `HomeSearchHint` uses `RotatingLine` for the rotation and a shared typewriter (CC-12) for the
  letters.

#### CC-09 · The add → stepper "pop switch" is hand-rolled on 3–5 add-to-cart surfaces instead of `PopSwitcher`
- **Severity:** Major
- **Location:** `core/motion/pop_switcher.dart:15-71` (12 sites, 11 files); raw:
  `core/widgets/shelf_add_control.dart:34,44-58` (from 0.6, `emphasized`),
  `home_quick_look_cart_button.dart:24,40-53` (from 0.8, `emphasized`), `pdp_cart_cta.dart:56,152-163`
  (from 0.8, `signature`), `assistant_buddy_thought_badge.dart:111-116`,
  `assistant_voice_mic_face.dart:26-31`.
- **Problem:** The product's key moment — "Add" turning into a quantity stepper — animates three
  different ways across the shelf card, quick look and PDP (begin scale 0.6/0.8/0.8; curve
  `emphasized`/`emphasized`/`signature`), even though `PopSwitcher` already provides exactly this
  swap (start alignment, `from` scale, spring, static first build, reduced-motion swap). Rules
  broken: DRY, consistency, "never own raw tweens".
- **Fix:** Replace the raw switchers with `PopSwitcher(stateKey:, from:, alignment:)` using one
  agreed `from` for the add → stepper swap; delete the local `_grownFrom`/`_poppedFrom` constants.
  (`PopSwitcher` uses `AppSprings.snappy`, so this is an intended feel unification, not just a
  refactor.)

#### CC-10 · `HomePressable` is a verbatim copy of `PressScale`'s passive path, and press depth is spread over 8 values in 28 local constants
- **Severity:** Major
- **Location:** `home_pressable.dart:11-62` (4 sites: `home_hero_deliver_to.dart:38`,
  `home_hero_search_field.dart:35`, `home_product_tile.dart:86`, `home_recipe_rail.dart:45`) vs
  `core/motion/press_scale.dart:23,43-92`.
- **Problem:** `HomePressable` copies `PressScale`'s passive path line-for-line — a `Listener` with
  pointer down/move past `kTouchSlop`/up/cancel, driving `AnimatedScale` with `AppMotion.fast` +
  `signature`. Only the scale differs (0.97 vs `PressScale`'s default 0.96), and `PressScale` already
  exposes `pressedScale` as a constructor parameter. Independently, C3-M5 found press depth spread
  across **8 different values in 28 local constants** app-wide — the same duplication pattern one
  level up (not just this one widget, but the whole "how much does a press shrink" decision). Rules
  broken: DRY (copy-paste), "never own raw tweens".
- **Fix:** `PressScale(pressedScale: 0.97, child:)` with no `onTap` gives identical passive
  behaviour — delete `home_pressable.dart`. Separately, converge the 28 local press-depth constants
  onto `AppMotion`'s two named scale tokens (`pressedScale` 0.97, `pressedScaleSmall` 0.92 per
  §9 (decision summary) §4) instead of ad hoc values.

#### CC-11 · Countdowns tick on private timers although `SecondClock` exists for exactly this
- **Severity:** Major
- **Location:** `core/motion/second_clock.dart:5-13`, `second_clock_scope.dart:5-9`,
  `core/widgets/countdown_digits.dart:14,63` (the designed path); `countdown_chip.dart:33-50` (own
  `Timer.periodic(1s)` per chip, one per row in `offer_tile.dart:72` and
  `listing_collection_scaffold.dart:41`); `home_countdown_text.dart:29-41,69-78` (own
  `Timer.periodic(1s)`, started in `initState`, kept running off screen — only the `setState` is
  skipped).
- **Problem:** `SecondClockScope`'s own doc states the goal — "N countdowns on a page cost one timer
  and one frame per period, not N unaligned ones" — but `CountdownChip` and `HomeCountdownText`
  ignore it. An offers list with several countdown tiles runs one timer per tile with unaligned
  frames; the home strip's timer never stops while the Home tab lives. Countdown rendering is also
  split three ways: `CountdownDigits`, `CountdownChip` (plain `setState` text) and
  `HomeCountdownText` (`FlipValue` per part). Rules broken: DRY, consistency, the ownership rule
  (the shared clock is the primitive).
- **Fix:** Put `CountdownChip` and `HomeCountdownText` on `SecondClockScope.maybeOf(context)`,
  rendered through `CountdownDigits` in two styles (chip/strip); wrap the offers list, the collection
  page and the home feed in one `SecondClockScope` each.

#### CC-12 · Three typewriters and three carets, one pacing model each
- **Severity:** Minor
- **Location:** `assistant_buddy_typed_text.dart:29-38` (controller, 24 ms/letter, clamped
  500–1500 ms), `assistant_buddy_thought_text.dart:36-43` (controller + `AssistantBuddyTypingRhythm`),
  `home_search_hint.dart:31,41,87-92` (`Timer.periodic` 80 ms/letter); carets:
  `assistant_buddy_typing_caret.dart:10-50` (fades out when typed),
  `chat/assistant_streaming_caret.dart:10-30` (static), `otp_slot_caret.dart:11-71` (blinks) — all
  three share only a 5-line, 2 dp `AppColors.primary` bar decoration.
- **Problem:** Two typewriters live in the same `buddy/` folder with two different pacing models, and
  a third in Home is built on a `Timer.periodic` instead of a controller (though it correctly reads
  `TickerMode.valuesOf(context)` in `didChangeDependencies`, so it does stop under a covered route —
  downgraded from Major after verification). The three caret bars repeat one decoration but differ in
  layout and behaviour (fade/static/blink), so this is a smaller repetition than it first appears.
- **Fix:** One `core/motion/typewriter_text.dart` (`text, rhythm`) driven by a controller, with
  `onDone`, a layout-stable full-text placeholder, and semantics announcing the whole text once. Add
  one `core/widgets/text_caret.dart` with `blink: bool`. The two buddy widgets and the search hint
  compose them.

#### CC-13 · Page transitions: two near-identical classes, and the shared-axis doc promises routes it doesn't serve
- **Severity:** Minor
- **Location:** `core/navigation/hero_transition_page.dart:17-33` (35 instantiations: 34 feature
  routes + `app_router.dart:72`'s error page); `hero_slide_up_transition_page.dart:15-31` (3 sites:
  `assistant_routes.dart:18`, `product_details_routes.dart:21,35`); `hero_shared_axis_page.dart:6-9`
  (doc: "login → OTP, Mine → Settings → About") vs actual users `checkout_routes.dart:26,36`,
  `orders_routes.dart:38` (3 routes); `hero_fade_through_page.dart:6-8,36`; `navigation.dart:9-13`;
  `CLAUDE.md:197,520`.
- **Problem:** `HeroTransitionPage` and `HeroSlideUpTransitionPage` are the same 300 ms/250 ms-pop
  motion (`HeroSlideFadeTransition`), differing only in the pop curve (`exit` vs `signature`) and
  `opaque` being exposed — yet CLAUDE.md §6 implies the default page doesn't slide up. It does. The
  shared-axis doc names flows that actually use `HeroCrossFadePage` (login → OTP) and
  `HeroTransitionPage` (Mine → Settings → About); `auth_routes.dart` confirms login/OTP use
  `HeroCrossFadePage`, and `account_routes.dart`'s 7 routes all use `HeroTransitionPage`, none use
  shared-axis. `HeroFadeThroughPage` plays only the incoming half of fade-through and settles from
  0.96 while `FadeThroughSwitcher` uses 0.92. The barrel exports only 3 of 5 page types, so 3 route
  files import page classes directly. Rules broken: naming clarity, consistency; the CLAUDE.md
  contract no longer describes the code.
- **Fix:** Keep both class names (CLAUDE.md §6 names them) but implement `HeroSlideUpTransitionPage`
  as a thin preset of `HeroTransitionPage`; export every page type from `navigation.dart`; fix the
  shared-axis doc; rename `HeroFadeThroughPage` or share one settle-scale token with
  `FadeThroughSwitcher`; propose a CLAUDE.md §3/§6 update listing all five page types (proposal, not
  an edit).

#### CC-14 · Decaying-swing motion written twice, plus two more hand-rolled one-shot wiggles
- **Severity:** Minor
- **Location:** `core/motion/shake_x.dart:57-63` vs `features/home/.../home_bell_ring.dart:22-24,58-69`;
  `core/widgets/collection_hero_emoji.dart:29,44`, `home_waving_hand.dart:23,39`.
- **Problem:** Both `ShakeX` and `HomeBellRing` compute `amplitude × (1 − t) × sin(t × cycles × 2π)` —
  the same formula, one on `Offset.dx`, one on a rotation angle. Two more widgets hand-roll their own
  one-shot wiggle controllers with raw durations (900 ms, 1200 ms). `BlockedTapShake → ShakeX` is
  correct composition and should be kept as-is. Rules broken: DRY, OCP.
- **Fix:** Generalise `ShakeX` into `DecayingSwing(axis: translateX | rotate, amplitude, cycles,
  pivot)`, keeping `ShakeX` as a preset; move `HomeBellRing` and the emoji wiggle onto it.

#### CC-15 · `ConfettiBurst` duplicates `ConfettiPiece.scatter` line for line
- **Severity:** Minor
- **Location:** `core/motion/confetti_burst.dart:39-65` vs `confetti_painter.dart:26-52`.
- **Problem:** `_ConfettiBurstState._buildPieces` repeats `ConfettiPiece.scatter`'s `_seed`,
  `_spread`, `_minSpeed`, `_speedRange`, `_maxSpin` and generator — the painter's own doc even says
  "the same recipe `ConfettiBurst` uses." Rule broken: DRY.
- **Fix:** `ConfettiBurst` calls `ConfettiPiece.scatter(colors:, count:)` and drops its five
  duplicated constants.

#### CC-16 · "Play once TickerMode is enabled again" guard duplicated in `TintFlash` and `ReadyWipe`
- **Severity:** Minor
- **Location:** `core/motion/tint_flash.dart:19-20,112-129` vs `core/widgets/ready_wipe.dart:18-19,92-108`.
- **Problem:** Both one-shot "wash" widgets carry the same `_pending` flag: `_play()` checks
  `TickerMode.valuesOf(context).enabled`, parks the run, and `didChangeDependencies` replays it when
  the page is revealed. Rule broken: DRY.
- **Fix:** Extract the guard into one small mixin in `core/motion` (`PlayWhenVisibleMixin`), used by
  both (after CC-17 moves `ReadyWipe` into `core/motion`).

#### CC-17 · Motion primitives placed outside `core/motion`
- **Severity:** Minor
- **Location:** `core/widgets/light_sweep.dart` (11 call-site files), `core/widgets/ready_wipe.dart`
  (1 site: `hero_submit_button.dart:182`), `core/widgets/animated_accordion.dart:9`,
  `core/widgets/collection_hero_emoji.dart:29,44`, `features/home/.../home_loop.dart:24`,
  `features/assistant/.../assistant_entrance.dart:12`.
- **Problem:** These are generic, reusable motion widgets that own controllers/timers, yet they live
  in `core/widgets` or a feature instead of `core/motion` — a developer looking in
  `motion_widgets.dart` won't find them, and the duplicate copies in CC-03/CC-04/CC-07 follow
  directly from that. Rule broken: folder ownership, discoverability.
- **Fix:** Move `LightSweep`, `ReadyWipe` and the promoted loop/entrance primitives to `core/motion`
  and export them from the barrel; delete `AnimatedAccordion` (CC-07). Keep brand-specific painters
  (`BrandBackdrop`, loaders, mascot) where they are.

#### CC-18 · The motion and navigation barrels export about half their files, giving three import styles for the same primitive
- **Severity:** Minor
- **Location:** `core/motion/motion_widgets.dart:14-28` (15 exports of 35+ files — missing
  `change_bump`, `collapse_reveal`, `entrance_cascade(+_item)`, `fade_through_switcher`,
  `size_fade_switcher`, `list_item_transition`, `idle_loop`, `rolling_number`,
  `blocked_tap_shake`, `fly_to_cart`, `haptics`, `spring_curve`, `locale_swap_veil`,
  `confetti_overlay`, `motion`); `core/navigation/navigation.dart:9-13` (5 of 11).
- **Problem:** The same primitive is imported by barrel in one file and by direct path in the next —
  e.g. `mine_count_stat.dart:5` uses the barrel while `mine_wallet_stat.dart:7` imports
  `rolling_number.dart` directly, because `RollingNumber` isn't exported. `features/` alone shows 128
  barrel imports vs. ~152 per-file primitive imports for things the barrel should already cover.
  (Not a CLAUDE.md rule violation per se — §4 permits importing a barrel or directly — so this is a
  consistency/discoverability finding, not a broken contract.)
- **Fix:** Make `motion_widgets.dart` export every public primitive (plus `motion.dart`,
  `haptics.dart`, `spring_curve.dart`); make `navigation.dart` export all 5 page types; propose an
  `architecture_lints` rule that features import `motion_widgets.dart` only.

#### CC-19 · The add-to-cart interaction is duplicated and inconsistent across 7+ sites: raw `HapticFeedback` bypasses the policy, the same gesture gets a different haptic kind per screen, and the haptic+FlyToCart+cubit sequence is copy-pasted
- **Severity:** Major
- **Location:** raw `HapticFeedback.*` (7 calls, 4 files): `home_product_tile.dart:101,116`,
  `listing_product_tile.dart:55,68`, `recipe_ingredient_tile.dart:108,124`,
  `recipe_detail_view.dart:39`; policy file `core/motion/haptics.dart:3-8,32` ("Feature code routes
  haptics ONLY through here"); differing kind per screen: `pdp_bottom_bar.dart:41`
  (`Haptics.tap()` on add) vs. tile add-handlers (`Haptics.selection()`/raw `selectionClick()`);
  `app_button.dart:59` (`Haptics.tap()` on the button `InkWell`) vs. the same widget's stepper "+"
  firing `Haptics.selection()`; `checkout_rail_tile.dart:27-41` (`Haptics.selection()` on **both**
  add and remove, unlike `tap()`-on-remove elsewhere, and its `HeroImage` flight thumbnail has no
  `radius:` argument unlike every other site's `HeroCardImage(..., radius: AppRadius.r4)`); copied
  add-handler shape: `assistant_cart_taps.dart:19-36` (feature-local `abstract final class`,
  `Haptics.selection()` → `FlyToCart.flyFrom(...)` → `CartCubit.addCatalogProduct`) reproduced
  verbatim in `pdp_rail_tile.dart:54-67` and `cart_deal_tile.dart:28-39`; `home_product_tile.dart`/
  `listing_product_tile.dart` reproduce the same shape but with the raw `HapticFeedback` calls
  instead; the recipe add paths call the cart cubit directly with **no** `FlyToCart` call anywhere.
  `home_product_tile.dart`'s first-add branch fires `Haptics.success()` + `HomeConfetti.burstFrom`
  while the listing tile's equivalent branch has no such path at all.
- **Problem:** One product interaction — add to cart — is implemented at least 7 times with three
  independent layers of drift: (1) 4 files skip the single haptic policy entirely; (2) even the files
  that do use `Haptics.*` disagree on which kind fires for add/remove/first-add across screens; (3)
  the full haptic+flight+cubit sequence is copy-pasted with each copy free to omit a step (no
  `FlyToCart`, no confetti, no `radius:`). Rules broken: §3 "always use, never bypass" (the haptics
  policy), §7/§10 DRY and consistency, SRP.
- **Fix:** Move `AssistantCartTaps` into `core/widgets` (e.g. `CatalogCartGestures.add/remove`) and
  use it from all 7+ sites plus recipes; replace every raw `HapticFeedback.*` with
  `Haptics.selection()`/`Haptics.tap()`; decide and document one mapping per gesture in
  `haptics.dart` (add = selection, first add = success, remove = tap, refusal = warning, tab change =
  selection) and align the outliers.

#### CC-20 · A haptic decision fires inside a cubit instead of the widget that owns the gesture
- **Severity:** Minor
- **Location:** `features/account/presentation/cubit/setting_cubit.dart:7,119`
  (`Haptics.success()`); `settings_language_tile.dart:44-62` (already drives the thumb and
  `LocaleSwapVeil`).
- **Problem:** `SettingCubit` is the only cubit in the app that imports `core/motion` (confirmed by
  `grep -rln "core/motion" features/*/presentation/cubit/*.dart`), and it fires
  `Haptics.success()` immediately before `safeEmit`. This means the haptic can't be muted or varied
  by the widget that owns the gesture. Rule broken: CLAUDE.md §4 Presentation (cubits hold state and
  use cases only, no UI concerns), SRP.
- **Fix:** Emit success in state; fire `Haptics.success()` from the settings page's `BlocListener`
  after `LocaleSwapVeil.run` completes, then remove the `core/motion` import from the cubit.

#### CC-21 · Dead or misleading motion surface: an unused GIF, dead parameters, stale docs, a token in the wrong home, and 3 disagreeing "success hold" durations
- **Severity:** Minor
- **Location:** `assets/animations/hero_design_loading.gif` (2,287,862 bytes, `pubspec.yaml:115-116`,
  0 refs in `lib/`/`test/`); `flip_value.dart:15,36-38` (`axis`: 0 callers, `Offset(0.6, 0)` not
  RTL-mirrored); `price_text.dart:23` (`animate`: 0 callers, see CC-05); `spring_curve.dart:13-14`
  (docs cite `AppMotion.springSnappy`/`springCalm`, which don't exist — the real tokens are
  `AppSprings.snappy`/`.calm`); `spring_curve.dart:79` (`AppSprings.successHold = 400 ms`, a Duration
  token outside `AppMotion`, equal to `AppMotion.slow`) with only 2 non-declaration callers
  (`profile_edit_listener.dart:38`, `otp_verify_page.dart:60`) against `pdp_cart_cta.dart:51`
  (`addedHold = 1200 ms`) and `delivery_code_copy_button.dart:28` (`_copiedHold = 1800 ms`) — three
  unrelated "hold after success" durations with no shared vocabulary; `motion.dart:3-6` ("Feature
  code reads motion ONLY from here") never mentions `AppSprings` at all; `otp_code_slots.dart:17`'s
  doc cites `_cascadeStep` (private-name syntax) while the real field (`:29`) is public
  `cascadeStep`.
- **Problem:** The brand loader is code-driven (`BrandedDotLoader`); the GIF is dead weight in the
  bundle. Unused parameters widen two widgets' public API for nothing. Stale docs point agents at
  tokens that don't exist, or use the wrong name syntax. Motion durations are split across two
  classes (`AppMotion`, `AppSprings`) with no cross-reference, and three different "the action
  succeeded, hold this state" durations (400/1200/1800 ms) coexist with zero shared naming. Rules
  broken: YAGNI, "Feature code reads motion ONLY from here" (one token source).
- **Fix:** Remove the GIF and its `pubspec.yaml` entry (proposal — this review is read-only). Drop
  `FlipValue.axis` and `PriceText.animate`. Fix the spring/`otp_code_slots` docs. Move
  `AppSprings.successHold` into `AppMotion`, or have `motion.dart` explicitly name `AppSprings` as
  the second half of the token policy. Decide one "success hold" scale (or name the 3 durations as
  deliberate tiers) instead of 3 unrelated local constants.

#### CC-22 · Animated progress fill written three times across cart, checkout and account
- **Severity:** Minor
- **Location:** `features/cart/.../cart_deal_track.dart:38-49`,
  `features/checkout/.../checkout_offer_progress.dart:50-61` (identical: `TweenAnimationBuilder` +
  `LinearProgressIndicator`, `slow`/`emphasizedDecelerate`, `minHeight: AppSize.s5`);
  `features/account/.../reward_progress_bar.dart:60-68` (same tween, `FractionalTranslation` fill).
- **Problem:** A reusable "progress that eases to its new fraction" is copied across three features,
  two of them identical apart from colour. Rules broken: DRY, §7 "shared across features →
  core/widgets".
- **Fix:** Add `core/widgets/animated_progress_bar.dart` with fraction, colours, height and radius;
  the three sites compose it.

#### CC-23 · Tokens picked for their number, not their meaning — arithmetic on and outright misuse of unrelated tokens
- **Severity:** Major
- **Location:** `AppMotion.sheen` (3600 ms, "slow holographic sheen across a member card") divided
  for `HomeLoop` periods: `home_arrow_button.dart:82-83` (`sheen ~/ 3`, `~/ 3 * 2`),
  `home_strip_badge.dart:57-58`, `home_min_order_bar.dart:63-64` (`~/ 4`, plus `rest: sheen`),
  `home_day_part_disc.dart:58-59` (`~/ 2`, plus `rest: sheen`); `AppMotion.drawOn` (700 ms,
  "self-drawing outline") driving unrelated animations at `home_bell_ring.dart:28`,
  `home_add_burst.dart:66`, `home_reveal.dart:49`; `tracking_progress_stepper.dart:37` uses
  `AppMotion.countUp` (also 700 ms) for a progress-fill `upperBound`; `AppMotion.glowPulse` (5000 ms,
  "breathing glow behind a hero") reused as `home_category_grid.dart:59`'s ambient clock;
  `AppMotion.sheetLarge` (500 ms, "big sheets") reused for scroll-to-top at
  `back_to_top_overlay.dart:72`, `category_rail_header_delegate.dart:129`; `AppMotion.popup` (350 ms,
  "home centered-popup enter") whose sole consumer, `hero_mark_icon.dart:27`, is an icon-morph
  `TweenAnimationBuilder`, not a popup.
- **Problem:** Multiple unrelated animations are wired to a token by its numeric value rather than
  its documented meaning — a token stops being a semantic contract once its name and its use
  disagree. Rule broken: naming/intent (a token is a contract), consistency.
- **Fix:** Give each recurring intent its own token (`ambientLoop`, `ringOut`, `revealLong`,
  `scrollGlide`, …) or keep a named local `static const` per §7 instead of arithmetic on another
  token's value. Rename or retire `popup`.

#### CC-24 · Four different reduced-motion idioms, and `MotionGuard.curve` gating applied inconsistently
- **Severity:** Minor
- **Location:** hand-rolled ternaries: `pop_switcher.dart:42-43`, `busy_overlay.dart:88-89`,
  `collection_tab_strip.dart:80-82`; a private re-implementation: `refresh_disc_header.dart:103`
  (`Duration _motion(Duration duration) => _reduced ? Duration.zero : duration;`); re-derived counts:
  `MotionGuard.duration(` 120 call sites, `MotionGuard.reduced(` 103, `MotionGuard.curve(` 23.
- **Problem:** `MotionGuard.duration`/`.reduced` are the designed single gate, but at least 4 sites
  reimplement the same reduced→zero ternary by hand instead of calling it, and `MotionGuard.curve`'s
  23 call sites are not obviously the ones that actually need curve-level gating vs. duration-level.
  Rule broken: consistency ("MotionGuard is the single gate").
- **Fix:** Standardise on `MotionGuard.duration`; delete the private re-implementation and the
  ternaries; document when `MotionGuard.curve` is actually needed vs. duration alone.

#### CC-25 · Raw curves outside `AppMotion`, duplicated in two files
- **Severity:** Minor
- **Location:** `branded_dot_painter.dart:40` (`static const Curve _swap = Curves.easeInOutCubic;`),
  `splash_wordmark_painting.dart:63` (`Curves.easeInOutCubic.transform(flight)`).
- **Problem:** The same untokenised curve is declared/used independently in two files instead of
  reading it from `AppMotion`. Rule broken: §7 (curves come from `AppMotion`).
- **Fix:** Add `AppMotion.easeInOutCubic`, or reuse the existing `machEaseInOut` if the intent
  matches.

#### CC-26 · The tab switch gets 3 different treatments, one with no press feedback or haptic at all
- **Severity:** Minor
- **Location:** `CollectionTabStrip` (glides + fires `Haptics.selection()`) vs.
  `shell_nav_item.dart` (bare `PressScale(child: …)` with no `haptic:` argument) vs.
  `category_tab.dart` (a raw `GestureDetector`, no `PressScale`, no haptic call, instant border
  swap).
- **Problem:** The same interaction class — switching a tab/segment — has a fully-treated version, a
  partially-treated version and an untreated version living side by side, so the "which tab am I on"
  cue is inconsistent across the app. Rule broken: §10 consistency, the haptics policy (one tactile
  language).
- **Fix:** Decide one tab-change treatment (glide + `Haptics.selection()`, per CC-19's proposed
  mapping) and apply it to `shell_nav_item` and `category_tab`.

#### CC-27 · Motion docs cite a research file that does not exist, and misattribute a competitor's decompiled APK to Hero
- **Severity:** Minor
- **Location:** `MOTION_AND_NAVIGATION` cited 5 times — `hero_slide_fade_transition.dart:8`,
  `hero_transition_page.dart:10,15`, `navigation.dart:18,49` — a file that doesn't exist anywhere
  under `docs/` (only `docs/hero_motion_reference.md` and
  `docs/prompts/motion_system_2026_prompt.md` do); `motion.dart:8-10` ("verified against the
  decompiled Hero apk, `com.sankuai.sailor.afooddelivery` v3.5.214" — that package name belongs to
  the reference/competitor app, not Hero).
- **Problem:** Code comments cite a non-existent source document 5 times, and separately attribute
  findings taken from a decompiled competitor APK to "the Hero apk" — a citation-integrity problem
  that could mislead a future agent into trusting numbers as Hero's own verified behaviour when
  they're actually a different app's. Rule broken: readability (comments must be true).
- **Fix:** Point the 5 citations at the doc that actually exists, and correct the attribution to name
  the reference app, not Hero.

#### CC-28 · A raw Material colour in the dialog presenter, bypassing the token system
- **Severity:** Minor
- **Location:** `core/navigation/navigation.dart:61` (`barrierColor: barrierColor ?? Colors.black54,`
  inside `showHeroDialog`).
- **Problem:** A literal `Colors.black54` sits inside the one shared dialog presenter instead of an
  `AppColors` token. Rule broken: §7 "no magic values" (colours → `AppColors`).
- **Fix:** Add an `AppColors` token (e.g. `AppColors.barrierOverlay`) and use it as the default.

#### CC-29 · Feature-only skeleton widgets live in `core/widgets`
- **Severity:** Minor
- **Location:** not independently re-opened in the C3 pass (plausible on its face, consistent with
  §4's "only what 2+ features share belongs in core" rule already correctly applied elsewhere).
- **Problem:** If confirmed, a skeleton used by only one feature sitting in `core/widgets` misleads a
  reader into thinking it's shared, and it grows `core/widgets` for no reuse benefit. Rule broken:
  §4 folder ownership.
- **Fix:** Verify each single-feature skeleton's actual usage count; move any confirmed single-use
  skeleton into its owning feature's `presentation/widgets/`.

#### CC-30 · The RTL sign is hand-computed 25 times with no shared helper
- **Severity:** Minor
- **Location:** `grep -rln "Directionality.of(context) == TextDirection\."` returns exactly 25 files;
  spot-checked: `home_reveal_item.dart:59`, `hero_shared_axis_transition.dart:31`,
  `coupons_tab_thumb.dart:25` (one hand-computed RTL sign per file, each independently deriving ±1).
- **Problem:** 25 separate sites each hand-derive the same "which way does this direction go in RTL"
  boolean/sign instead of calling one shared helper — a correctness risk (one site could get the sign
  backwards) as well as a duplication one. Rule broken: DRY.
- **Fix:** Add one `core/utils` (or `core/motion`) helper, e.g. `int rtlSign(BuildContext context)` /
  `bool isRtl(BuildContext context)`, and re-point the 25 sites.

#### CC-31 · A page, not a widget, owns the PDP image viewer's pager animation state
- **Severity:** Minor
- **Location:** not independently re-opened in the C3 pass; the claim is a page holding
  `PageController`/`animateToPage`/zoom state directly.
- **Problem:** If confirmed, this is a straightforward §7 "pages compose only" violation — animation
  state belongs in a widget/controller the page merely provides, not in the page class itself.
  Rule broken: §7 "Pages compose widgets… they hold no layout implementation beyond that
  composition."
- **Fix:** Extract the pager/zoom state into a dedicated widget or controller; the page only supplies
  it with data and reads results.

#### CC-32 · God animation widgets in the assistant buddy and the brand sheet
- **Severity:** Major
- **Location:** `assistant_buddy_launcher.dart` (395 lines), `assistant_mascot.dart` (321 lines, 7
  `AnimationController` fields at :85-111 — `_blink`, `_mood`, `_mouth`, `_hop`, `_eyes`, `_wave`,
  `_wink`), `assistant_buddy_greeting.dart` (282 lines), `assistant_buddy_thought_bubble.dart` (257
  lines), `brand_sheet_scaffold.dart` (248 lines), `refresh_disc_header.dart` (220 lines).
- **Problem:** Six files each mix layout, gesture handling and multiple independent
  `AnimationController`s in one class, 220–395 lines each — a maintainability/SRP concern
  independent of the duplication findings elsewhere in this appendix (assistant_mascot's 7
  controllers alone is more than the entire `core/motion` `idle_loop.dart`+`float_loop.dart`+
  `glow_pulse.dart` trio combined). Rule broken: SRP, "no god widgets/classes" (§10).
- **Fix:** Split each file along its independent concerns (one controller/behaviour per small widget,
  composed by the parent) rather than one file owning the whole animated surface. Lower priority than
  the duplication fixes above, since nothing here is broken, only hard to change safely.

#### CC-33 · `FlyToCart` combines a global mutable target registry, a launcher and a private overlay widget, with inline magic numbers
- **Severity:** Major
- **Location:** `fly_to_cart.dart:19-50` (`static final List<GlobalKey> _targets = []` plus
  `registerTarget`/`pushTarget`/`popTarget` beside the flight logic), `:58,79`
  (`thumbSize = 56` default, repeated), arc lift (`- 120` inline literal), shrink/fade shares
  (`1.0 - 0.7 * t`, `t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3)`, both `0.7`/`0.3` inline).
- **Problem:** One file mixes three responsibilities — a static, app-wide mutable registry of flight
  targets; the public `FlyToCart.flyFrom` launcher API; and the private overlay widget that actually
  animates — plus several inline magic numbers (`56`, `120`, `0.7`, `0.3`) that should be named
  constants per §7. Rule broken: SRP, §7 "no magic values."
- **Fix:** Split the target registry into its own small class/file; name the magic numbers as
  `static const` fields (`defaultThumbSize`, `arcLift`, `shrinkShare`, `fadeShare`); keep
  `FlyToCart.flyFrom` as the one public entry point.

---

### ✨ Refactored Example

```dart
// core/motion/idle_loop.dart — ONE loop combining HomeLoop's options + count + running. CC-04
class IdleLoop extends StatefulWidget {
  const IdleLoop({
    super.key, required this.period, required this.builder,   // (context, Animation<double>, child)
    this.child, this.reverse = false, this.phase = 0,
    this.rest = Duration.zero,       // timer between laps, no frames while resting
    this.count,                      // legs, then rest (FloatLoop's bounded float)
    this.running = true,             // home passes HomeRevealScope.onScreenOf(context)
  });
}
// FloatLoop / GlowPulse / the two blinks become presets, not controllers, over this one widget.
```

```dart
// core/widgets/count_badge.dart — one pill for the 6 badge copies; "changed" is always ChangeBump. CC-06
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.color, this.cap = 99});
  @override
  Widget build(BuildContext context) =>
      ChangeBump(value: count, child: /* pill: min size, pill radius, LTR "99+" text */);
}
// PopScale keeps only the entrance (PopScale.onMount, 30 sites); re-key sites move to ChangeBump.
```

```dart
// core/widgets/catalog_cart_gestures.dart — the one add-to-cart sequence. CC-19
abstract final class CatalogCartGestures {
  static void add(BuildContext context, CatalogProduct product, GlobalKey thumbKey, {bool first = false}) {
    first ? Haptics.success() : Haptics.selection();
    FlyToCart.flyFrom(thumbnail: HeroCardImage(product.imageUrl, s56, s56, radius: AppRadius.r4));
    context.read<CartCubit>().addCatalogProduct(product);
    if (first) HomeConfetti.burstFrom(thumbKey);
  }
  static void remove(BuildContext context, CatalogProduct product) {
    Haptics.tap();
    context.read<CartCubit>().removeProduct(product.id);
  }
}
```

---

### ✅ Summary

The `core/motion`/`core/widgets` primitive set is well documented, but many features never adopted
it, and the token/haptics policy has real, reachable gaps.

- **One real bug:** CC-01 — a reduced-motion chat scroll reaches a `DrivenScrollActivity` assertion.
- **Duplication clusters:** entrance cascades (5 implementations, CC-02/CC-03), idle loops (4+2
  blinks, CC-04), "changed" pops (3, CC-06), height+fade show/hide (1 primitive + 9 copies, CC-07),
  vertical ticker (5-7 copies, CC-08), add→stepper pop switch (3-5 raw, CC-09), press (1 verbatim
  copy + 28 scattered constants, CC-10), countdown clocks (3, CC-11), typewriters (3, CC-12), plus 9
  smaller one-off duplications (CC-14 through CC-22).
- **Inconsistency without duplication:** token misuse (CC-23), 4 reduced-motion idioms (CC-24), raw
  curves (CC-25), 3 tab-switch treatments (CC-26), stale/false docs (CC-27), a raw colour (CC-28).
- **Maintainability outliers, not defects:** 2 god-widget clusters (CC-32, CC-33).

Nothing here is layer-broken (no presentation→data, no cubit→repository); only one cubit (CC-20)
carries a UI-feedback decision it shouldn't. Suggested order: CC-01 (bug) → CC-19 (haptics/add-to-cart,
the most copy-pasted interaction) → CC-02/CC-03/CC-04 (the three biggest primitive mergers) →
CC-06/CC-07 (pop + show/hide) → CC-08/CC-09/CC-10/CC-11 (remaining primitive adoption) → the Minor
clean-ups. Then propose `architecture_lints` rules: no `AnimationController(`/`Timer.periodic` for
motion in `features/**/widgets` without an allow-list, no `HapticFeedback.` outside
`core/motion/haptics.dart`, and features import only `motion_widgets.dart`.

**Counts: 0 Critical · 17 Major · 16 Minor** (of the 33 deduplicated findings).

---

### Evidence

**Primitive call-site counts (from C1's Table E1 — re-measured 2026-09-28, matches source exactly):**

| Primitive | Inst. / files | Notes |
|---|---|---|
| PopScale | 40 / 40 | 30 `.onMount` (entrance) + 10 `popKey:` (re-key) |
| PopSwitcher | 12 / 11 | |
| ChangeBump | 10 / 10 | |
| FlipValue | 11 / 10 | numeric 5 · label 5 · dead 1 (`price_text:55`) |
| RollingNumber | 6 / 6 | |
| CountUpText | 7 / 7 | 2 with `from: 0` (money, kept), 1 plan-switch (kept) |
| EntranceCascade / Item | 2 / 2 · 4 / 3 | |
| StaggerEntrance | 30 / 16 | |
| AssistantEntrance (feature) | 10 / 8 | |
| ScrollReveal | 14 / 14 | |
| ListItemTransition | 2 / 1 | |
| FloatLoop | 7 / 7 | |
| IdleLoop | 2 / 2 | |
| GlowPulse | 3 / 3 | |
| HomeLoop (feature) | 5 / 5 | |
| ShakeX / BlockedTapShake | 9 / 8 · 2 / 2 | |
| FadeThroughSwitcher | 27 / 26 | incl. 2 core, 2 pages |
| SizeFadeSwitcher | 3 / 3 | |
| CollapseReveal | 24 / 23 | cart ×5, checkout ×10, auth ×1, connectivity ×1, orders ×7 |
| ConfettiBurst / ConfettiOverlay | 5 / 5 · 1 / 1 | |
| RotatingLine | 1 / 1 | |
| AnimatedAccordion (core/widgets) | 2 / 2 | |
| Page types | HeroTransitionPage 35 · HeroSlideUpTransitionPage 3 · HeroSharedAxisPage 2+3 (helper) · HeroCrossFadePage 2 · HeroFadeThroughPage 1 | |
| `AnimationController(` files | **56** | 15 core/motion + 10 core/widgets + 31 features (corrected from a stated 57 — one file is a doc-only mention) |

**Key counts (from C2, all independently re-derived and matching the source exactly):**

| Metric | Count |
|---|---|
| `MotionGuard.duration(` call sites | 120 |
| `MotionGuard.reduced(` call sites | 103 |
| `MotionGuard.curve(` call sites | 23 |
| `Haptics.{tap,selection,success,warning,fire}(` calls | 88 |
| `haptic: HapticKind.*` parameters | 13 |
| Direct `HapticFeedback.*` calls (policy bypass) | 7 (4 files) |
| `AppMotion.standard` references (alias of `signature`) | 13 |
| `AppMotion.signature` references | 107 |
| `AppMotion.decelerate` references | 3 (exact 3 call sites) |
| `hero_design_loading.gif` size / lib+test refs | 2,287,862 bytes / 0 |
| Cubits importing `core/motion` | 1 (`setting_cubit.dart`) |
| `Directionality.of(context) == TextDirection.*` (hand-computed RTL) | 25 files |
| `motion_widgets.dart` export count | 15 (of 35+ files) |

Full source passes: Appendix C,
Appendix C, Appendix C.


---

## Appendix D. Implementation backlog

All 35 candidates from Appendix D (`B1-01`…`B1-20`), `backlog_cand_2.md`
(`B2-01`…`B2-09`) and `backlog_cand_3.md` (`B3-01`…`B3-06`) are kept — none were exact duplicates
of one another, so none were merged. 13 new rows (`BX-01`…`BX-13`) were added: 4 explicitly required
(the `im_chat_body` reduced-motion crash, the unused-GIF removal, the `docs/hero_motion_reference.md`
drift, and a Phase-5 asset-wiring placeholder) plus 9 found by grepping every **PB-High/Medium**
(Appendix B's own `## 🟡 Severity` list) and **CC-Major** id (`grep "Severity:\*\* Major"
Appendix C → CC-01,02,03,04,06,07,08,09,10,11,19,23,32,33) against the "Linked" column of all
35 existing candidates and finding no match: `PB-02`+§9 (decision summary) §23 (Home category shelf rest),
`PB-03` (BrandBackdrop raster), `PB-06`+`CC-11` (countdown timers → `SecondClockScope`, merged, same
root cause), `PB-14` (2.2 MB catalogue parse), `CC-01` (chat-scroll crash, also one of the 4 required
rows), `CC-07` (show/hide dedup), `CC-08` (vertical-ticker dedup), `CC-09` (add→stepper pop-switch
dedup), `CC-23` (token-arithmetic misuse), `CC-33` (`FlyToCart` god-file). Every other PB-High/Medium
and CC-Major id was already covered (see each row's own "Linked" cell for the match).

**Score** = impact ÷ effort. **Ties** are broken lower-risk-first, then higher-impact-first, then
lower-effort-first, then alphabetically by id — noted once here rather than in every row.

| Rank | ID | Title | Screens | Files (key) | Primitives / tokens | Impact | Effort | Score | Risk | Test needed | Changes behaviour | Links |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | BX-01 | Fix the reduced-motion chat-scroll crash (`MotionGuard.duration` fed straight into `animateTo`) | Assistant chat | `im_chat_body.dart:87-91`; new `core/motion/motion_guard.dart` (`scrollTo()`, D7) | `MotionGuard.scrollTo()` (D7, new) | 5 | 1 | 5.00 | Low — one call site, mirrors 6 correct counter-examples already in the app | Widget test: `MotionGuard.reduced=true`, list not at bottom, `animateTo` called → no throw, position jumps instantly | no | CC-01 (Major) |
| 2 | B2-06 | Fix `DelayedLoaderDisc`'s reduced-motion flash at the core | Order invoice, Order review, Order tracking (shared: every `AppLoader` site) | `core/widgets/delayed_loader_disc.dart` | `AppLoader`/`MotionGuard` (D7, D18) | 3 | 1 | 3.00 | Low, isolated — one file | Widget test with `MotionGuard.reduced=true`: disc paints at its end value on the first frame, no flash | no | none found — new, verifier-only finding |
| 3 | B1-05 | Fix Haptics-taxonomy violations app-wide | Wallet, Settings, Address list, Address edit, Assistant chat, Assistant voice | `wallet_balance_card.dart`, `settings_logout_tile.dart`, `setting_cubit.dart`, `address_delete_dialog.dart`, `label_chip.dart`, `assistant_chat_page.dart`, `assistant_voice_listener.dart` | Haptics intent helpers (D21) | 4 | 2 | 2.00 | Low, mechanical | Widget tests asserting the right `Haptics.*` call per gesture (CLAUDE.md §8 pattern) | no | CC-19, CC-20; R07-26, R07-28, R07-31 |
| 4 | B1-12 | Gate every native `animateCamera` on the address-edit map behind `MotionGuard` | Address edit (map) | `address_edit_view.dart` (7 call sites) | `MotionGuard` (D7) | 4 | 2 | 2.00 | Low | Widget/integration test, `MotionGuard.reduced` forced true: `moveCamera` not `animateCamera` fires | no | CC-24 (4 reduced-motion idioms); R07-05 — the only confirmed reduced-motion gap across all 18 screens |
| 5 | B2-01 | Give the shared `CatalogPillStepper`/`CatalogStepButton` a rolling count and a real press state | Home (rail cards), Cart preview/tab, Checkout (rail steppers), PDP, Recipe detail | `core/widgets/catalog_pill_stepper.dart`, `catalog_step_button.dart`, `catalog_circle_add_button.dart` | `RollingNumber` (D13), `PressScale` (D22) | 4 | 2 | 2.00 | Low — same data, different render, one shared widget | Widget test per call site confirming roll+press state; golden check the +/− glyph swap | no | none by name — a shared-widget gap the audits flag repeatedly |
| 6 | BX-09 | Replace the raw "add → stepper" scale switchers with `PopSwitcher` | Home (shelf card, quick-look), Product detail, Assistant (thought badge, voice mic face) | `core/widgets/shelf_add_control.dart`, `home_quick_look_cart_button.dart`, `pdp_cart_cta.dart`, `assistant_buddy_thought_badge.dart`, `assistant_voice_mic_face.dart`, `core/motion/pop_switcher.dart` | `PopSwitcher` (D13, kept) | 4 | 2 | 2.00 | Low | Widget test per surface: same `PopSwitcher` swap (from-scale, spring, static first build, reduced-motion swap) | ⚠ yes | CC-09 (Major) |
| 7 | B1-03 | Fix `FloatLoop`'s doubled-period bug | Loyalty points, Loyalty rewards, Assistant voice, Assistant buddy | `core/motion/float_loop.dart` | `FloatLoop` core fix | 2 | 1 | 2.00 | Low, isolated | Unit test: one up-and-back cycle == documented `floatLoop` duration | no | none found — new, verifier-only finding |
| 8 | B1-15 | Fix "fake change on open" bugs (digits/flip/roll firing on first load) | Delivery code | `delivery_code_digit_box.dart`, `delivery_code_cubit.dart` | extends D20 ("never count up from 0 on open") | 2 | 1 | 2.00 | Low | Cubit test: no emitted "changed" event on the very first load | no | none new |
| 9 | B1-20 | RTL-mirroring decisions bundle — decision first, no build until resolved | Edit profile, Splash | `profile_completion_ring_painter.dart`, `splash_assembly.dart` | none — a design decision | 2 | 1 | 2.00 | Low | Golden test per locale once implemented | ⚠ yes | R02-02 |
| 10 | B3-04 | Extend the locale-swap veil to cover the connectivity banner | Settings (language switch); app-wide banner host | `core/motion/locale_swap_veil.dart:22,39`, `connectivity_banner_frame.dart:59-81`, `app.dart:247-253` | veil-scope fix, no new token (D7) | 2 | 1 | 2.00 | Low — one overlay-ordering change | Widget test: with the banner open, its text does not flip language before the veil lifts | ⚠ yes | none found — new, verifier-only finding [INFERENCE] |
| 11 | BX-06 | Remove the unused 2.29 MB brand-loader GIF and its pubspec entry | none (asset only) | `assets/animations/hero_design_loading.gif`, `pubspec.yaml:115-116` | none | 2 | 1 | 2.00 | Low | `grep -rn "hero_design_loading" lib test` stays 0 hits; asset-manifest sanity check | no | PB-15 (Medium); §9 (decision summary) §1; CC-21 (Minor) |
| 12 | B1-04 | Adopt `FailureView`+`DataFreshness`+`HeroStateView.signedOut` wherever missing | Loyalty rewards, Edit profile, Delivery code, Address list, Assistant chat | `rewards_body.dart`, `profile_edit_body.dart`, `delivery_code_body.dart`, `address_list_body.dart`, `assistant_chat_body.dart` | core offline contract (CLAUDE.md §3.2) | 5 | 3 | 1.67 | Low–medium — needs `DataFreshness` plumbing where absent | `hero-api-testing` offline/failure fakes per screen (CLAUDE.md §8) | no | none in appB/appC — an architecture-contract gap |
| 13 | BX-02 | Split `BrandBackdropPainter` into a static base layer + a small listening layer; bound the reveal `saveLayer` | Login, OTP verify | `brand_backdrop.dart`, `brand_backdrop_painter.dart`, `brand_backdrop_ring.dart`, `brand_sheet_scaffold.dart`, `hero_lockup_painter.dart`, `grocery_doodles.dart` | none new — mirrors `BrandBackdropRing`'s own cached-picture pattern | 5 | 3 | 1.67 | Low–medium — visual regression risk if the cached base layer breaks the turning-ring look | Golden test unchanged visual; profile/widget check only the ring layer repaints between frames | no | PB-03 (High) |
| 14 | B1-09 | Unify the shell's arrival page type so `go(Routes.shell)` never replaces the route | Main shell, OTP verify (`returnTo` stacking) | `shell_routes.dart`, `main_shell_page.dart`, `otp_verify_page.dart` | `HeroFadeThroughPage` on every `go(Routes.shell)` caller (D10) | 5 | 3 | 1.67 | Medium — depends on go_router page-type-matching semantics elsewhere | `app_router_test.dart` per caller; widget test: tab state/scroll survives sign-in | ⚠ yes | CC-13 (page-type-drift family) |
| 15 | B1-06 | Replace hard state-cut `switch` with `FadeThroughSwitcher` on the remaining snapping screens | Loyalty rewards, Address list, Assistant history, Assistant chat | `rewards_body.dart`, `address_list_body.dart`, `assistant_history_body.dart`, `assistant_chat_body.dart` | `FadeThroughSwitcher` (D13, D17) | 3 | 2 | 1.50 | Low | Widget pump test confirming a cross-fade frame between states | no | R09-02 |
| 16 | B1-10 | Give the main-shell tab switch a fast incoming fade, explicitly no haptic | Main shell | `main_shell_page.dart`, `shell_nav_item.dart` | D11 | 3 | 2 | 1.50 | Low | Widget test: `FadeTransition` plays on tab change, `Haptics` never called | ⚠ yes | CC-26 (tab switch gets 3 treatments today); R09-02 |
| 17 | B1-11 | Replace pop-from-0/cut-at-0 badges with `ChangeBump`+roll-on-land | Mine (unread badge), Main shell (cart + cart-segment badge) | `mine_unread_badge.dart`, `shell_nav_badge.dart`, `shell_basket_segment.dart` | `ChangeBump`, `RollingNumber` (D13, D16) | 3 | 2 | 1.50 | Low | `bloc_test`/widget test: one bump per cart-qty change, not two | no | CC-06 ("value changed" pop built 3 ways) |
| 18 | B1-18 | Unify disabled-submit feedback (`ShakeX`+`warning`+inline reason) | OTP verify, Address edit Confirm (Login is the reference) | `otp_verify_button.dart`, `select_sheet.dart` | `ShakeX` (D13), `Haptics.warning` (D21) | 3 | 2 | 1.50 | Low | Widget test: tap a disabled submit, assert shake+warning+message | no | none new |
| 19 | BX-04 | Point `CountdownChip`/`HomeCountdownText` at `SecondClockScope` | Offers/marketing collection, Home | `countdown_chip.dart`, `home_countdown_text.dart`, `second_clock.dart`, `second_clock_scope.dart`, `core/widgets/countdown_digits.dart`, `offer_tile.dart`, `offers_list_sliver.dart`, `listing_collection_scaffold.dart`, `checkout_vouchers_page.dart`, `checkout_eta_card.dart` | `SecondClockScope`, `CountdownDigits` (D13, kept) | 3 | 2 | 1.50 | Low | Widget test: N countdown tiles share one timer/tick; timer stops on backgrounding/hidden tab | no | PB-06 (Medium); CC-11 (Major) |
| 20 | BX-11 | Split `FlyToCart`'s target registry out of the launcher/overlay file; name its magic numbers | none directly — shared primitive behind every add-to-cart surface | `core/motion/fly_to_cart.dart` → split into `fly_to_cart.dart` + `fly_to_cart_targets.dart` | `FlyToCart` (D13, kept) — internal refactor only | 3 | 2 | 1.50 | Low | Existing `FlyToCart` tests stay green; new unit test for the target-registry class in isolation | no | CC-33 (Major) |
| 21 | B2-08 | Give every full-screen/modal presentation a real exit gesture, never leave a state with zero back affordance | PDP image viewer (no drag-to-dismiss), Recipe detail (no back while loading/on error) | `pdp_image_viewer_page.dart`, `recipe_detail_page.dart`, `recipe_detail_body.dart` | n/a — a gesture/affordance rule | 3 | 2 | 1.50 | Low for back-affordance; Medium for drag-to-dismiss (must not fight the pager's own horizontal swipe) | Widget test confirming a back control exists in every state; device check for drag-to-dismiss velocity/threshold | ⚠ yes | R09-05, R09-06 |
| 22 | B3-02 | Fix the brand-filter sheet's blocking wait and double-tap race | ProductListingPage (shop) | `listing_toolbar.dart:36-47`, `product_listing_cubit.dart:98-110`, `listing_brand_sheet.dart:29-36` | pending-state pattern for the filter pill — no token yet | 3 | 2 | 1.50 | Low–medium — must not change the cache-then-network read, only the pill/sheet's own state | Widget test: a second tap during the brand read is absorbed/queued, never opens an empty sheet | no | none found — new (A08 shop audit P1/P2, both CONFIRMED) |
| 23 | B1-01 | Unify money/points/count motion on one `RollingNumber`-family primitive | Mine, Wallet, Loyalty points, Loyalty rewards | `mine_wallet_stat.dart`, `mine_points_stat.dart`, `mine_count_stat.dart`, `wallet_balance_amount.dart`, `ledger_balance_card.dart`, `rewards_balance_card.dart` | `RollingNumber` (D13, D20) | 4 | 3 | 1.33 | Low — same data, different tween | Widget/golden check per screen; "never count-up on open" (D20) holds everywhere after the swap | no | CC-05, CC-21; R08-27, R08-28 |
| 24 | B1-08 | Stop entrance cascades replaying on scroll-back / lazy re-mount | Address list, any list still on `StaggerEntrance`/`ScrollReveal` in a lazy builder | `address_row.dart`, `stagger_entrance.dart`, `scroll_reveal.dart` | "first load only" rule (D17) | 4 | 3 | 1.33 | Low–medium — needs a "seen" set per list, not per row | Widget test: scroll past the fold and back, assert no new `AnimationController` starts | no | PB-09, PB-10; CC-02 |
| 25 | B2-07 | Unify add-to-cart parity across every surface: morph + haptic + fly-to-cart | Recipe detail, Orders list (reorder), Product detail | `recipe_ingredient_tile.dart`, `order_actions.dart`, `pdp_rail_tile.dart`/`pdp_cta_stepper.dart` | `ShelfAddControl`/`FlyToCart` (D13, D16) | 4 | 3 | 1.33 | Low–medium — reorder's `FlyToCart` needs a valid on-screen target from a list row | Widget test per surface confirming the same morph+haptic+flight sequence fires | no | CC-19 (direct match, extends its site list) |
| 26 | BX-03 | Home category shelf: gate the ambient wash/glide with rest + a reduced-motion pause | Home (category shelf) | `home_category_grid.dart:43,72-84,138`, `home_category_tile.dart:90-103`, `home_category_aurora_painter.dart:68-88` | OnScreen/AmbientLoop rest pattern (D14, D19); reduced-motion pause (§9 (decision summary) §23, WCAG 2.2.2) | 4 | 3 | 1.33 | Low–medium | Widget test: wash pauses for a rest window, stops under `MotionGuard.reduced`/off-screen/hidden-tab; a11y check it can be paused | ⚠ yes | PB-02 (Medium); §9 (decision summary) §23 |
| 27 | BX-05 | Stop loading/parsing the full 2.2 MB catalogue before the first frame just to count favourites | app-wide (cold start), Mine (favourites count) | `lib/main.dart:13,19`, `service_locator.dart` (`_initCore`), `hero_repository.dart:71-74`, `account_local_data_source.dart:27` | n/a — bootstrap/data-loading change | 4 | 3 | 1.33 | Medium — touches app-startup sequencing; must not break other catalogue consumers that need the full load later | Startup-timing benchmark before/after; widget test that favourites count resolves without the full parse | no | PB-14 (Medium) |
| 28 | B1-02 | Gate every ambient decorative loop (`LightSweep`/`FloatLoop`/`GlowPulse`/`BrandBackdrop`/mascot idle) with `ambientBudget`+`OnScreen` | Mine, Loyalty points, Loyalty rewards, Login, Assistant buddy layer | `light_sweep.dart`, `float_loop.dart`, `glow_pulse.dart`, `brand_backdrop*.dart`, `hero_lockup.dart`, `hero_waving_mark.dart`, `assistant_mascot.dart`, `assistant_buddy_launcher.dart` | `AmbientLoop` engine, `OnScreen` gate (D14, D15, D19) | 5 | 4 | 1.25 | Medium — must not gate the *real*-progress loaders that are exempt | Widget tests: pause on offscreen/hidden-tab/reduced-motion; scripted 5s-`ambientBudget` timer test | ⚠ yes | PB-01, PB-04, PB-05, PB-18, PB-24; CC-04; R06-35, R07-03, R08-09 |
| 29 | B1-16 | Standardise press-feedback language (`PressScale` vs. ripple vs. highlight-only vs. none) | Mine, Settings, Main shell segments, Address list | `mine_menu_cell.dart`, `settings_tile.dart`, `shell_basket_segment.dart`, `address_row_tile.dart` | `PressScale` convention (D22) — needs a ruling first | 3 | 3 | 1.00 | Low | Widget tests per row type | ⚠ yes | CC-10 (`HomePressable` verbatim copy of `PressScale`) |
| 30 | B2-04 | Give every significant completion a genuine, visible success moment instead of racing navigation or omitting it | Order review, Order tracking, Checkout, Product detail | `order_review_page.dart`, `tracking_status_header.dart`, `checkout_page_listeners.dart`, `pdp_cart_cta.dart` | `PopScale`/check pattern (D13), Haptics taxonomy (D21) | 3 | 3 | 1.00 | Low — additive, each site is missing/racing a moment rather than replacing one | Widget test asserting the check/haptic renders before any navigation starts | ⚠ yes | R07-33, R08-23 |
| 31 | B2-05 | Size-transition late-arriving content into a live layout instead of snapping it in | Home, Checkout, Customer-service hub, Pro membership, Orders + Order invoice | per-screen insertion points — see Appendix A's "Perf risk"/"State-change" entries | `SizeFadeSwitcher`/`CollapseReveal` (D13) | 3 | 3 | 1.00 | Low — mechanical per site, no new primitive needed | Widget test per site confirming a height/opacity tween instead of an instant layout jump | no | R10-22 |
| 32 | B3-01 | Give known list/grid-shaped first loads a shaped skeleton instead of the spinner-style disc | Brands, Categories (tree), Notifications, Recipes | `brands_body.dart:40`, `categories_body.dart:42`, `notifications_body.dart:34`, `recipes_body.dart:47`, `core/widgets/list_skeleton.dart` | skeleton-vs-`AppLoader` rule (D18) | 3 | 3 | 1.00 | Low — a shaped skeleton already exists in core; each site is a like-for-like swap | Widget test per screen: known-shape content shows a skeleton, not a disc, on first load | no | PB-08 (matches D18) |
| 33 | B3-05 | Give a failed busy-overlay action a drawn "couldn't finish" mark | App-wide — 13 `BusyOverlay` sites (account, address, auth, cart, checkout, orders×3, Pro) | `core/widgets/busy_overlay.dart:37-40`, `busy_overlay_layer.dart`, `loader_done_mark.dart` | a failure counterpart to `LoaderDoneMark` (D13) | 3 | 3 | 1.00 | Low — additive; no site currently shows anything on failure | Widget test: a failed cubit call under `BusyOverlay` shows the new mark before the overlay leaves | ⚠ yes | none found — new, verifier-only finding |
| 34 | B3-06 | Replace the flat grey image placeholder with a brand or dominant-colour placeholder | App-wide — every `HeroNetworkImage`/`HeroImage` use | `hero_network_image.dart:122-123`, `hero_image.dart:18` | new placeholder asset + treatment, no token yet | 3 | 3 | 1.00 | Low — visual only, no logic change | Golden test: placeholder renders before the network image resolves (card, banner, brand logo) | no | PB-12, PB-13 |
| 35 | BX-10 | Give arithmetic-borrowed tokens their own names instead of dividing/reusing an unrelated token's value | Home (arrow button, strip badge, min-order bar, day-part disc, bell ring, add burst, category reveal), Orders (tracking stepper), shared overlays, auth (`hero_mark_icon`) | `home_arrow_button.dart:82-83`, `home_strip_badge.dart:57-58`, `home_min_order_bar.dart:63-64`, `home_day_part_disc.dart:58-59`, `home_bell_ring.dart:28`, `home_add_burst.dart:66`, `home_reveal.dart:49`, `tracking_progress_stepper.dart:37`, `back_to_top_overlay.dart:72`, `category_rail_header_delegate.dart:129`, `hero_mark_icon.dart:27`, `motion.dart` | new named tokens (e.g. `ambientLoop`, `ringOut`, `revealLong`, `scrollGlide`); rename/retire `AppMotion.popup` | 3 | 3 | 1.00 | Low | Grep/lint check that no token is used via arithmetic on another token's value; existing widget tests stay green (same durations) | no | CC-23 (Major) |
| 36 | BX-13 | Wire Phase 5 assets | App-wide (assistant mascot moods, tool/thought glyphs, brand/handoff illustrations, signed-out/offline plates, tour tiles, AI-identity glyph, plus B3-06's placeholder) | `HeroIcons`/`HeroAssets` registries; consuming widgets across `assistant/`, `product_details/`, `marketing/` — exact list deferred to asset_manifest.md | `HeroIcons`/`HeroAssets` (existing system; D1: no Lottie/Rive/GIF) | 3 | 3 | 1.00 | Low | Golden test per new asset once wired; asset-manifest sanity check | no | §9.6 (AI assistant motion spec) §5 (15 assets); B3-06 |
| 37 | B1-19 | About-screen fixes bundle (retire every-visit logo pop, fix "Rate us" fake feedback, unify copy feedback to the inline flip) | About | `about_header.dart`, `about_links_section.dart`, `about_social_chip.dart` | `PopScale.onMount` gated to first-run (D13), `FlipValue` (D13) | 2 | 2 | 1.00 | Low | Widget test: the logo pop plays at most once per install (persisted flag) or is fully static | no | R08-08, R08-26 |
| 38 | BX-12 | Fix the stale `docs/hero_motion_reference.md` and related motion-doc citations | none (docs) | `docs/hero_motion_reference.md`; citation fixes at `hero_slide_fade_transition.dart:8`, `hero_transition_page.dart:10,15`, `navigation.dart:18,49`, `hero_shared_axis_page.dart`, `motion.dart:8-10` | n/a | 2 | 2 | 1.00 | Low | None (docs) — repo-wide grep confirms 0 remaining refs to `MOTION_AND_NAVIGATION.md`, `spin`, `BrandMoment`, `shader_transition.dart`, `splashZoomBegin`/`splashKenBurns`, and the Hero-apk misattribution | no | §0 (baseline) item 2 (still claims no haptics :173-175,:210; a Lottie splash :126; a `spin` token :201; `shader_transition.dart` :185; `BrandMoment` :151; `lib/core/motion` :5); CC-13, CC-27, CC-21 (all Minor) |
| 39 | B1-14 | Overlap the splash intro with the Home prefetch, fix the confetti overrun | Splash | `splash_page.dart`, `splash_player.dart`, `splash_assembly.dart`, `app.dart`/`config/di/app_global_cubits.dart` | matches §9 (decision summary)'s own D23 finding | 4 | 4 | 1.00 | Low–medium — must not race the auth-restore/cart-mirror work already started during splash | Integration test measuring time-to-interactive before/after; widget test asserting confetti never paints past clock completion | ⚠ yes | PB-28, PB-31 |
| 40 | BX-07 | Extract a shared `SizeFadeTransition`, retire `AnimatedAccordion`, move the raw height+fade copies onto `CollapseReveal`/`SizeFadeSwitcher` | Cart, Checkout (bottom bars), Auth/Login, OTP, Account/profile (field errors), Assistant/Support FAQ rows | `collapse_reveal.dart`, `animated_accordion.dart`, `list_item_transition.dart`, `size_fade_switcher.dart`, `home_cart_bar.dart`, `offers_cart_bar.dart`, `catalog_cart_bar.dart`, `login_phone_error.dart`, `otp_code_error.dart`, `profile_field_error.dart` | `CollapseReveal`/`SizeFadeSwitcher` (D13); new `SizeFadeTransition` core piece; new `core/widgets/inline_field_error.dart` | 4 | 4 | 1.00 | Low–medium — mechanical but touches many files; the cart pill's medium-vs-slow mismatch is a deliberate harmonisation | Widget test per migrated site confirming height+fade via the shared primitive; golden test for the new `InlineFieldError` row | ⚠ yes | CC-07 (Major) |
| 41 | B1-07 | Collapse duplicate entrance-cascade systems onto `EntranceCascade`/`EntranceCascadeItem`, tokenise every raw stagger step | Mine, Wallet, Loyalty rewards, Settings, About, Delivery code, Edit profile, Login, OTP verify, Address list, Assistant | `stagger_entrance.dart` (core default), `ledger_row_entrance.dart`, `reward_card.dart`, `auth_cascade_item.dart`, `address_row.dart`, `assistant_entrance.dart` + ~10 call sites | `EntranceCascade`/`EntranceCascadeItem` (D14, D17) | 5 | 5 | 1.00 | Medium — must preserve "first load only"/capped-6/`TickerMode`-await per screen; some screens deliberately exceed the cap | Widget tests per screen: cascade timing + no replay on scroll-back (ties to B1-08) | no | CC-02, CC-03; PB-10, PB-11; R05-36 |
| 42 | B2-02 | Fix page-type drift: a step uses the 100% slide-up instead of `HeroSharedAxisPage`, and shared-axis screens lose a leg from some entries | Checkout, Order tracking + Order review, History coupons, Content, Customer-service hub → topics → chat | `checkout_routes.dart`, `orders_routes.dart`, `coupons_routes.dart`, `marketing_routes.dart`, `support_routes.dart`, `checkout_page_listeners.dart` | `HeroSharedAxisPage` (D8, D9) | 4 | 4 | 1.00 | Medium — go_router page-type/key semantics interact with tab and cubit-cache state | `app_router_test.dart` per route; widget test confirming both transition legs actually play from every real entry point | ⚠ yes | CC-13 (direct match) |
| 43 | B3-03 | Give snack bars a tone (success/warning/error/offline) and an optional action (Undo/View) | App-wide — 72 call sites across cart, checkout, orders, address, account, assistant, Pro, auth, notifications | `core/navigation/hero_snack_bar.dart:10-48`, `screen_failure_listener.dart:16-51` | new snack contract — tone glyph + optional `SnackBarAction`, no token yet | 4 | 4 | 1.00 | Medium — touches the one shared surface every destructive/success flow depends on | Widget test per tone, plus an Undo round-trip on address-delete and cart-clear | ⚠ yes | R08-22, R08-21 |
| 44 | B1-13 | Ship §9.6 (AI assistant motion spec)'s approved motion changes (buddy wake-window+alive defaults+greeting-countdown fix; chat celebration/word-reveal/voice-haptic fixes; tour perch-lean bug+play-once) | Assistant buddy layer, Assistant chat, Assistant tour | per §9.6 (AI assistant motion spec) §1 "New names" + the file:line sites its §2/§3 cite | `AssistantMotion`, `AssistantWordReveal`, `AssistantStepLine`, `BuddyMotionGate`, `EntranceCascadeItem.single`, `FlyToCart.inFlight` | 5 | 5 | 1.00 | Medium–high — behaviour changes need `assistant.md` §4's 22-item approval table signed off first | `bloc_test` for `AssistantBuddyCubit` cadence changes; widget tests for `BuddyMotionGate`'s §3.2 gating table | ⚠ yes | PB-04, PB-07, PB-24; CC-12, CC-32; R06-16, R06-35, R07-03, R07-29, R08-32 |
| 45 | B2-03 | Orchestrate simultaneous state-change motions instead of firing them all on one frame | Checkout, Order tracking, Pro membership, My coupons, Home | `checkout_receipt.dart` family, `tracking_body.dart`, `pro_membership_page.dart` + hero/tab/bag files, `my_coupons_content.dart`, `home_product_tile.dart` | sequencing rule extending D17 (not yet a named primitive) | 4 | 5 | 0.80 | Medium — touches the densest screens in the app; trimming/staggering risks losing a relied-on cue | Widget/golden tests asserting a fixed motion order and that no two "big" motions start on the same frame | ⚠ yes | R08-27, R05-17 |
| 46 | B2-09 | Collapse the three segmented-thumb implementations onto one primitive + token | Cart tab, Checkout (delivery/pickup mode), My coupons | `shell_basket_switch.dart`, `checkout_mode_toggle.dart`/`hero_segmented_control.dart`, `coupons_tab_bar.dart`/`coupons_tab_thumb.dart` | one segmented-control primitive (D14) — needs a ruling first | 3 | 4 | 0.75 | Low–medium — one of the three also drives a `TabBarView`'s own page swipe | Widget tests per screen confirming one shared thumb spring + one haptic policy | ⚠ yes | CC-26 (direct match) |
| 47 | BX-08 | Extract `VerticalSwapTransition`, rebuild the Home ticker and assistant composer hint on `RotatingLine`, delete the two dead rotation constants | Home (announcement ticker, search hint), Assistant (composer hint), Checkout (bar line, reference) | `rotating_line.dart`, `home_announcement_ticker.dart`, `assistant_composer_hint.dart`, `home_search_hint.dart`, `flip_value.dart`, `rolling_glyph.dart`, `assistant_buddy_thought_line.dart`, `app_constants.dart` (`heroAutoAdvance`/`searchHintRotate` removal) | `RotatingLine` (D13, kept); new `VerticalSwapTransition` core piece | 3 | 4 | 0.75 | Low–medium — must preserve `TickerMode`-awareness already correct in one of the three, and fix the covered-route leak in `AssistantComposerHint` | Widget test: `AssistantComposerHint` stops rotating under a covered route (`TickerMode` false); unit test on the shared transition direction | ⚠ yes | CC-08 (Major) |
| 48 | B1-17 | Switch Address-list delete to optimistic (remove at once, reconcile, roll back on failure) | Address list | `address_list_page.dart`, `address_book_cubit.dart` | matches the cart's existing optimistic contract (CLAUDE.md §3.1); no new primitive | 3 | 4 | 0.75 | Medium–high — data-loss risk if rollback isn't airtight | Cubit test: delete → fail → rollback, race with a concurrent load | ⚠ yes | R08-18 |

### Behaviour changes that need approval

20 backlog rows change visible behaviour in a way that needs sign-off before it's built (deduplicates
§9 (decision summary) §24 and §9.6 (AI assistant motion spec) §4's own approval items against the rows that would
actually implement them):

1. **B1-02** — Ambient loops (`LightSweep`/`FloatLoop`/`GlowPulse`/`BrandBackdrop`/mascot idle) rest under `ambientBudget`+`OnScreen`.
2. **B1-09** — Shell arrival always uses `HeroFadeThroughPage`; `go(Routes.shell)` never replaces mid-stack.
3. **B1-10** — Main-shell tab switch: fast incoming fade, explicitly no haptic.
4. **B1-13** — Assistant buddy/chat/tour changes (22 items, §9.6 (AI assistant motion spec) §4).
5. **B1-14** — Splash overlaps the Home prefetch instead of running before it.
6. **B1-16** — One press-feedback language across Mine/Settings/shell/Address (needs a design ruling first).
7. **B1-17** — Address-list delete becomes optimistic (remove-then-reconcile) — highest data-loss risk in the backlog.
8. **B1-20** — RTL-mirroring ruling for the profile completion ring / splash flight direction.
9. **B2-02** — Route legs move onto `HeroSharedAxisPage` on 6 routes (visibly different transitions).
10. **B2-03** — State-change motions on dense screens (Checkout, Order tracking, Pro, My coupons, Home) are sequenced/trimmed instead of firing at once.
11. **B2-04** — Order tracking gets a genuine "delivered" success moment + haptic (the rest of B2-04 is minor, no approval needed).
12. **B2-08** — PDP image viewer gains drag-to-dismiss (the back-affordance fix itself needs no approval).
13. **B2-09** — One segmented-control primitive for Cart tab / Checkout mode / My coupons tabs (needs a design ruling first).
14. **B3-03** — Snack bars gain a tone (success/warning/error/offline) and an optional Undo/View action app-wide.
15. **B3-04** — Locale-swap veil scope extends to cover the connectivity banner (a visible timing/scope change).
16. **B3-05** — Failed busy-overlay actions show a drawn "couldn't finish" mark on 13 screens.
17. **BX-03** — Home category shelf wash/glide gets a rest + pause window (§9 (decision summary) §23's "ambient budget on the shelf" finding, WCAG 2.2.2).
18. **BX-07** — Cart bottom-bar enter/exit duration unified across offers vs. listing (part of the show/hide dedup).
19. **BX-08** — Vertical-ticker direction/travel distance harmonised across the Home ticker, search hint and assistant hint.
20. **BX-09** — Add→stepper pop-switch feel unified (one begin-scale/curve) across the shelf card, quick look and PDP.

### Suggested waves

**Wave 1 — Bugs + cheap wins (score ≥ 1.5, no approval blocking).** `BX-01` (chat-scroll crash),
`B1-03`/`B1-15` (loop/digit bugs), `B2-06` (loader flash), `BX-06` (delete the GIF), `B1-05`/`B1-12`
(haptics + map reduced-motion), `B1-04` (offline contract), `B2-01`/`B1-01` (RollingNumber/press
family), `BX-11` (`FlyToCart` split), `B1-06`/`B1-11`/`B1-18` (switcher/badge/shake cleanups),
`BX-04` (SecondClock), `B2-08`'s back-affordance half. Ship first — cheapest, highest-scoring,
nothing here is gated on a decision (two ⚠ rows in this score band, `B1-10`/`B1-20`, can go out for
approval in parallel without blocking the rest).

**Wave 2 — Primitive consolidation (score ~1.0–1.33, no approval, higher effort).** `B1-07`/`B1-08`
(EntranceCascade merge), `BX-07` (show/hide dedup), `BX-02` (BrandBackdrop raster split), `BX-03`'s
perf half, `BX-05` (catalogue-parse startup fix), `B2-07` (add-to-cart parity), `B3-01` (skeletons),
`B3-06` (image placeholder), `BX-10`/`BX-12` (token renames + doc fixes). Land once Wave 1's tests
prove the shared primitives are solid — several of these are prerequisites for Wave 3's assistant and
add-to-cart work.

**Wave 3 — Behaviour changes needing approval.** Take the 20-item list above for sign-off in one pass
(it mostly restates §9 (decision summary) §24 and `assistant.md` §4, already pending), then build in priority
order: `B1-02` (ambient budget) → `B1-13` (assistant, 22 items) → `B1-09`/`B2-02` (shell/page-type
fixes) → `BX-03`'s pause requirement → `B1-16`/`B2-09`/`BX-09`/`BX-08` (feel-unification rulings) →
`B2-03`/`B2-04` (state-change sequencing, success moments) → `B3-03`/`B3-04`/`B3-05` (snack tone,
veil scope, busy-overlay failure mark) → `B1-14`/`B1-17`/`B1-20`/`B2-08`'s drag-to-dismiss half.

**Wave 4 — Assets + polish.** `BX-13` (wire Phase 5 assets) once asset_manifest.md lands, then
the remaining cosmetic rows (`B1-19`, `B2-05`, `B3-02`) and any doc cleanup left over from Wave 2.

