# Hero Motion — what the code does today

Short map from the reference study to the shipped code. The system itself (tokens, patterns,
per-screen rules, budgets) is `docs/motion/motion_design_system_2026.md`; what shipped and what
did not is its "Implementation status" section. When this file and the code disagree, the code
wins (`lib/src/core/motion/motion.dart`, `lib/src/core/motion/`, `lib/src/core/navigation/`).

## 1. Provenance

The values under `AppMotion` come from a decompiled reference delivery app
(`com.sankuai.sailor.afooddelivery` v3.5.214, not a Hero build). **[FACT]** = a literal value in
that app (`resources.arsc` Material 3 tokens, Mach `bundle.css.json` keyframes, kflexbox
templates). **[INFERENCE]** = a reasoned choice. The native player engines and the Lottie clips
of that app are NOT used: Hero paints its own splash and brand moments (`CustomPaint`, SVG
plates), and ships no Lottie, GIF, VAP video or GLSL transition.

## 2. Tokens (`AppMotion`, `AppSprings`)

| Token | Value | Grounding |
|---|---|---|
| `microPop` / `fast` / `medium` / `page` / `slow` | 100 / 150 / 250 / 300 / 400 ms | [FACT] Mach SKU pop; M3 duration scale |
| `signature` `Cubic(0,0,0.2,1)` | enter | [FACT] M3 `legacy_decelerate` |
| `exit` `Cubic(0.4,0,1,1)` | leave | [FACT] M3 `legacy_accelerate` |
| `emphasizedDecelerate` `Cubic(0.1,0.7,0.1,1)` | M3 emphasized | [FACT] |
| `machEaseInOut` `Cubic(0.42,0,0.58,1)` | shop pop, loop legs | [FACT] shop_global CSS |
| `linear` | ticks, fills | — |
| `staggerStep` 30 ms, `staggerMaxItems` 6 | list entrance | [FACT] home dropdown 0/30/60 ms |
| `breathe` 600 ms · `sheen` 3600 ms · `floatLoop` 3200 ms · `carousel` 3000 ms | loops, auto-advance | [FACT] order_confirm CSS / kflexbox |
| `ambientBudget` 5 s | max ambient run per appearance | design |
| `successHold` 400 ms · `snackDwell` 4 s · `blinkPeriod` 1 s · `loaderDelay` 150 ms · `busyMinVisible` 500 ms | feedback timing | design |
| `pressedScale` 0.97 · `pressedScaleSmall` 0.92 · `slideShift` 30 dp · `entranceRise` 8 dp | scalars | design |
| `AppSprings.snappy` / `calm` (`thumbSlide` = calm) | spatial springs | design |

Splash timings are feature-local (`SplashMotion`, see `docs/splash.md`). Retired: `standard`,
`decelerate`, `emphasized`, `popup`, `imageFade`, `sheetLarge`, `flip`, `countUp`, `glowPulse`,
`shineSweep`, `spin`.

## 3. Gates and policy

- `MotionGuard.reduced(context)` (Android "Remove animations" or iOS "Reduce Motion"): spatial
  motion becomes a fast cross-fade or an instant settle, loops stop. `MotionGuard.off` = only
  `disableAnimations` (motion is a cut). `MotionGuard.ambientAllowed` = not reduced, no screen
  reader, tickers on. `MotionGuard.scrollTo` / `pageTo` never hand a zero duration to `animateTo`.
- Ambient loops go through `AmbientLoop` (+ `OnScreenGate`, `PlayWhenOnScreen`): whole laps,
  on screen, foreground, stop after `ambientBudget`. `FloatLoop`, `IdleLoop`, `LightSweep`,
  `RotatingLine` are presets over it.
- List entrances: `EntranceCascade` / `EntranceCascadeItem` only (once per scope life).
- Values that change: `RollingNumber` / `RollingNumberText` (money, counts), `FlipValue` (labels,
  time), `CountUpText` only for an earned figure.

## 4. Haptics (`Haptics`)

Intent helpers, one per meaning: `cartAdd({first})`, `cartRemove`, `commit`, `pick`,
`refuse` (throttled 500 ms), `destructive`, `discard`, `done`, plus `tap` / `selection` /
`success` / `warning`. No raw `HapticFeedback` outside it. The customer can mute them
(Settings → Preferences → Vibration; `Haptics.enabled`, stored as `settings.haptics.v1`).
Presses are silent by default (`PressScale`): only a commit or a pick fires.

## 5. Navigation (`core/navigation`)

`HeroTransitionPage` = shared-axis X push (forward). `HeroSlideUpTransitionPage` = modals (PDP,
viewer, assistant chat, search pill, cart preview, Pro paywall). `HeroFadeThroughPage` =
top-level moves (shell, login, order placed → tracking). `HeroCrossFadePage` = login → OTP. All
sit on `HeroPage` / `HeroPageRoute`; reduced = fast fade, off = cut. Back: Android predictive
back (`enableOnBackInvokedCallback`), iOS start-edge swipe, PDP viewer drag-down-to-dismiss
(`HeroBackGestureDetector`). Dialogs: `HeroDialogRoute` (in medium, out fast). Sheets:
`showHeroBottomSheet` (one at a time). Snacks: `showHeroSnackBar` (tones, one Undo / action).

## 6. Signature interactions

| Interaction | Code |
|---|---|
| Add to cart | `CatalogCartGestures` → `Haptics.cartAdd` + `FlyToCart` (≤ 3 flights, topmost on-screen target) + `CountBadge` lands with the flight; `PopSwitcher(cartFrom)` add → stepper |
| Press | `PressScale` (cards, chips, pills) / `PressRow` (rows); no stacked presses |
| Segments | `SegmentedThumbTrack` |
| Loaders | `AppLoader` (Hero dots, waits `loaderDelay`; iOS Reduce Motion → the dots breathe instead of orbiting, motion off → still), `BusyOverlay` (submit; done check, failure ×) |
| Screen states | `HeroStateView` / `FailureView` with `StateArt`; skeletons cross-fade to content |
| Reveal / fold | `CollapseReveal`, `SizeFadeSwitcher`, `FadeThroughSwitcher`, `InlineFieldError` |
| Sequencing | `MotionBeat` (0 / 250 / 500 ms), `DeferredValue`, `AfterArrival` |
| Moments | `ConfettiBurst` (earned only), `SuccessBeat`, `LocaleSwapVeilHost` |

## 7. Not in Hero (reference app only)

VAP alpha-video promos, Lottie clips, the video-effect GLSL transitions, the 11-frame cart
progress PNG sequence, Litho/Compose engines. The reference's Mach keyframe evidence (300 ms
ease-in-out sheets, 100 ms SKU pop, 600 ms heartbeat, 3 s carousel) is folded into the tokens
above; the long per-bundle extraction that used to fill this file is in git history.
