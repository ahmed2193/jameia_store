# Jameia Motion — Reverse-Engineered Reference

Evidence-cited extraction of Jameia's animation/motion/interaction system from the
decompiled apk (`com.sankuai.sailor.afooddelivery` v3.5.214). This is the source
of truth behind `lib/core/motion/motion.dart`. Each entry is tagged **[FACT]**
(literal value read from an apk artifact) or **[INFERENCE]** (reasoned from
symbols/patterns; exact value not in a readable artifact).

Jameia renders UI through **5 runtimes** — native Compose, MTFlexbox→Litho,
Mach Pro (QuickJS), Recce (Rust→WASM), MRN (React Native). Animation is driven by
**all** of them. What's statically recoverable, and what isn't:

| Source | Readable? | What it grounds |
|---|---|---|
| `resources.arsc` (M3/Material tokens) | ✅ | durations + easing control points |
| Mach `bundle.css.json` (`@keyframes`/`transition`) | ✅ | the REAL in-app screen motion |
| kflexbox template XML | ✅ | carousel/countdown/Lottie params |
| `splash_lottie_default.json` | ✅ | splash curves, exact |
| `*.fsh` GLSL shaders | ✅ | video-effect transitions |
| VAP `vapc` box in promo `.mp4` | ✅ | alpha-video promo specs |
| qbc / DEX string tables | partial | animation asset names, API symbols, durations leak as strings |
| Compose / Litho / QuickJS bytecode logic | ❌ | per-widget easing computed at runtime |

---

## 1. Material 3 motion tokens — `resources.arsc` [FACT]

Jameia ships **Material3 1.4.0**; the full M3 motion system is bundled.

### Durations (`m3_sys_motion_duration_*`, ms)
`50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000`
Material legacy: short1 75 · short2 150 · medium1 200 · medium2 250 · long1 300 · long2 350.

### Component durations
`bottom_sheet_slide 150` · `mtrl_tab_indicator_anim 250` · `design_tab_indicator_anim 300` ·
`fragment_transaction_animation 300` · `m3/mtrl_card_anim 120 (delay 75)` ·
`m3/mtrl_chip_anim 100` · `m3/mtrl/roo_btn_anim 100 (delay 100)` ·
`config_tooltipAnimTime 150` · `show_password 200` · `hide_password 320`.

### Easing control points (`m3_sys_motion_easing_*`, decoded from arsc floats)
| token | cubic-bezier | clone mapping |
|---|---|---|
| standard | (0.2, 0, 0, 1) | — |
| standard_accelerate | (0.3, 0, 1, 1) | — |
| standard_decelerate | (0, 0, 0, 1) | — |
| emphasized_accelerate | (0.3, 0, 0.8, 0.2) | — |
| emphasized_decelerate | (0.1, 0.7, 0.1, 1) | `AppMotion.emphasizedDecelerate` |
| legacy | (0.4, 0, 0.2, 1) | (osg-home CSS transition curve) |
| legacy_accelerate | (0.4, 0, 1, 1) | **`AppMotion.exit`** ✓ |
| legacy_decelerate | (0, 0, 0.2, 1) | **`AppMotion.signature`** ✓ |
| linear | (0, 0, 1, 1) | — |

State-layer opacities (decoded): dragged 0.32 · focus 0.24 · pressed 0.24 · hover 0.16.

---

## 2. Mach Pro CSS keyframes — `bundle.css.json` [FACT] — the REAL in-app motion

These are literal `@keyframes`/`transition` rules in the shipped Mach bundles.
**This is the strongest grounding for Jameia's actual screen feel.**

### Standard modal / overlay system (recurs across nearly every bundle)
| pattern | keyframe | timing |
|---|---|---|
| Scrim fade-in | `opacity 0→1` | **300ms ease-in-out forwards** |
| Scrim color | `transparent → #000000c0` | 300ms ease-in-out |
| Bottom-sheet slide up | `translateY(600/500/440/240dp) → 0` | 300ms ease-in-out forwards |
| Bottom-sheet dismiss | `translateY(0) → 600dp` | 300ms ease-in-out |
| Side panel | `translateX(400dp) ↔ 0` | 300ms ease-in-out |
| Pop-in (icon/success) | `scale(0) → scale(1)` | 300ms ease-in-out |
| Toast | `opacity0+translateY(24dp) → 1+0` | 200ms ease-in-out, delay 0 or 900ms |
| Spinner | `rotateZ 0→360` | **1s linear infinite, delay 90ms** |
| Shimmer/skeleton | `translateX(0→500dp)` | **0.7–0.8s ease-out infinite** (range 0.7–2s) |

→ Clone: `AppMotion.page` (300) + `signature`/`exit` = the sheet/scrim/pop standard. ✓

### Per-surface specifics
- **home_page_main**: flip-in card `rotateY 270→360` 0.5s; spinner 1s linear delay 90ms;
  **fly-to-corner (add-to-cart)** `{top:50%,left:50%}→{top:0,left:100%}` 2s delay 2s;
  **staggered dropdown** `opacity0+translateY(-20/-110/-250dp)+scaleY0→full` 300ms, **delays 0/30/60ms**;
  shimmer translateX 0→500dp 0.8s.
- **osg_home_main_page**: drawer up `translateY(440/500dp)→0` 300ms; bottom bar `bottom:-80dp→0` 200ms;
  **breathe** `opacity 1→0.4→1` 1.5s infinite delay 0.5s; horizontal sweep `translateX ±750/375/250rpx` 1.6s infinite;
  Material transition `transform/opacity 250ms cubic-bezier(0.4,0,0.2,1)`.
- **shop_global**: SKU **micro-pop** `scale0+op0→scale1+op1` **100ms cubic-bezier(0.42,0,0.58,1)** (out reverse);
  fade in 150ms / out 60ms; **error shake** `translateX 0→-20→20→-20→0` 200ms.
- **order_confirm_global** (richest, 41 keyframes): coupon-card grow `209→319dp` 500ms delay 200ms;
  **shine sweep** `translateX(-100→350dp)` **2000ms delay 1000ms infinite**; **heartbeat** `scale1→1.1` **600ms infinite alternate**;
  slide-settle 500ms; detail fade-up 200ms delay 900ms (staged after reward).
- **kingkong_page**: flip-in 0.5s; fly-to-corner 2s; **wiggle** `rotateZ 0→-18` 0.3s.
- **landingPage**: progress fill `left 0→100%` 0.7s; **zoom-in** `scale1→1.333 + opacity` 0.25s; scrim 200ms.
- **coupon lists** (my/order/history): "claim" reveal = card grow 500ms + shine 2000ms infinite + breathe 600ms.
- **mkt_invite_main**: scale-pop 300ms; sheet slides `translateY(500)→0` 300ms.
- **home_operation_header**: overshoot pop `scale0→scale1.1(50%)→scale1` 0.5s.
- Two named beziers only: `cubic-bezier(0.4,0,0.2,1)` (osg) and `cubic-bezier(0.42,0,0.58,1)` (shop); everything else keyword `ease-in-out`/`ease-out`/`linear`. No `spring`.

### Gundam `myprizescomp` — the LOTTERY motion [FACT]
- Wheel: `rotateZ 0→360` **1s ease-in-out infinite**.
- Prize-tile pulse (3-up): `scale1→0.9→1` 1s infinite, **staggered delays 0/0.33/0.66s** (wave).
- Win reveal: `scale → 2.1` over 1s with hold at 33–66% then fade-out.
- Entry: fade 0.3s + scale-pop `scale0→scale1` 0.3s.
(Other Gundam comps — couponpop, transparentvideopop, imagecomp — have NO CSS motion; they use native Lottie/VAP players configured in `.qbc`.)

---

## 3. kflexbox templates — Litho card params [FACT]

XML+CSS-flexbox; motion delegated to native `Swiper`/`CountDown`/`LottieView`.
- **Carousel auto-advance = 3000ms** (`autoPlay?carouselTime:3000`, `0` disables); `circular` infinite loop.
- Banner indicator dots: active 14×4 / inactive 6×4, colors `#222222cc` / `#2222224c`, gap 6.
  Gathering: active 10×3 / inactive 3×3, `#FFFFFF` / `#000000`, gap 2.
- **CountDown** `HH:mm:ss`, 1s tick, fires refresh event on finish.
- **LottieView** promo banner: `autoPlay=true loop=true heightFix`, remote `bannerLottieUrl`.
- Easing/slide tween durations are NOT in templates — baked into native Litho components.

---

## 4. Splash Lottie — `splash_lottie_default.json` [FACT] (exact)

`v=5.7.1, fr=50, ip=0, op=92 → 1.84s, 500×1084, 11 layers`. Brand wordmark "jameia" +
kebab mascot; each glyph **slides in from left while a mask wipes it open**, staggered.
- **Slide ease (letters)**: `cubic-bezier(0.45, 0, 0.15, 1)`
- **Slide ease (mascot k1–k3)**: `cubic-bezier(0.51, 0, 0.45, 1)`
- **Fade/reveal ease**: `cubic-bezier(0.167, 0.167, 0.833, 0.833)` (Lottie-default ≈ linear)
- Horizontal stagger ~0.07–0.34s between glyphs; full settle ~1.2s; end 1.84s; brand-yellow backdrop.
→ Clone plays the real Lottie + a Ken-Burns `splashZoomBegin 1.08→1.0` over `splashKenBurns 1600ms`.

---

## 5. Other animation assets [FACT]

### VAP alpha-video (Tencent, `vapc` box; side-by-side RGB|alpha mp4)
8 full-screen promo/onboarding clips in `assets/`:
| file | frames | fps | output | duration |
|---|---|---|---|---|
| 1761230354911 / 1761583711722 | 72 | 20 | 750×1090 | 3.60s |
| 1763806816844 / 1763820709025 | 101 | 20 | 750×1090 | 5.05s |
| 1765462637518 / 1765462795181 | 74 | 15 | 750×1334 | 4.93s |
| 1766390406230 | 152 | 24 | 654×1047 | 6.33s |
| 1766398360415 | 110 | 18 | 654×1047 | 6.11s |

### GIF
`new_user_slide.gif` 1500×537, ~36f ≈ 1.44s loop · `fullscreen_gif_default.gif` 750×1626, ~94f.
(`jameia_design_loading*.gif` is NOT in this apk — the clone's brand-loader GIF is a separate asset.)

### Referenced-but-not-shipped Lottie (names in qbc/DEX/decoded bundles)
`pay_process.json` (cashier), `withdraw_{success,fail,progress}` (courier wallet — actually PNGs),
`flowerLottie` (coupon-upgrade petal burst), `TaskFinishLottieJson` (task-complete), `BenefitAnimation`,
`bannerLottieUrl` (+ localized `lottieBgZh`/`lottieBgEn`). The clips live in compiled Mach/Recce bundles
or are fetched remotely — only their identifiers leak. This is why the clone's brand moments use
painter/GIF fallbacks (see `BrandMoment`).

---

## 6. Interaction symbols (qbc / DEX string-mining) [FACT strings → INFERENCE behavior]

- **Cart**: `AddSkuAnimation` (the named fly-to-cart routine) · `exeRedDotAnimate` + `renderCountNumber`
  (badge count pop on qty change) · `ADD_BTN_FOLD_STATUS` + `AddCartBtn` (add button folds into a stepper) ·
  `cart_progress_{0..10}.png` (free-delivery progress bar = 11-frame PNG sequence) · `icon_cart_op_loading.gif`.
  → Clone equivalents: `FlyToCart`, `PopScale` on the shell badge, animated `QtyStepper`.
- **Order tracking**: `tech_progress_node_{motor,car,delivery,pickup,confirm}_{normal,highlight}.png` (timeline
  node state cross-fade) · `weather-animation` · `PROGRESS_BAR_ANMATION_STATUS` (sic) · `map_marker_icon_n_*`
  (24-frame heading-rotated marker). → Clone: `_PulseNode`, `JameiaAssets.carMarkerForHeading`.
- **Animation engines present**: Airbnb Lottie (`com/airbnb/lottie` ×216, `DynamicLottie`) · Jetpack Compose
  animation (×1307: `AnimatedVisibility`, `MotionScheme`, `KeyframesWithSplineSpec`, `SharedTransitionScope`) ·
  Litho `Transition` · RecceLottie (RN pay) · Tencent VAP/Irmo (`IrmoVapVideoView`, `EFFECT_TYPE_VAP`) ·
  a JS `bezier-easing` engine (`easeOutQuad`, `calcBezier`, `newtonRaphsonIterate`).
- **Native interpolators**: `PathInterpolator` ×10, `OvershootInterpolator`, `AnticipateOvershootInterpolator`,
  `AccelerateDecelerateInterpolator`, `fast_out_slow_in`/`mtrl_fast_out_slow_in`/`linear_out_slow_in` (→ res/*.xml).
- **Named anim XML** (arsc): `cashier_slide_{in,out}_{left,right}` · `recce_modal_{fade_in,fade_out,slide_up,slide_down}` ·
  `dialog_{enter,exit}_anim` · `homepage_def_text_anim_{in,out}` · `roo_bottomsheet_slide_{in,out}` ·
  `mtrl_fab_{hide,show}_motion_spec` · `mtrl_extended_fab_change_size_*`.
- **Haptics** [FACT, NOT yet in clone]: `performHapticFeedback` (Compose, `-CdsT49E` mangled), `android/os/Vibrator`
  (×15), `HapticFeedbackConstantsCompat`, `isPremiumVibratorEnabled` → Jameia gives tactile tap feedback,
  richer waveforms on capable devices. **Gap: the clone has no haptics — candidate follow-up.**

---

## 7. GLSL shaders — `*.fsh` [FACT]

11 files (1 vertex + 10 fragment), the Meituan video/UGC-capture effects SDK (not core ordering UI).
**5 progress-driven transitions** (ported subset in `shaders/`): `alpha`→dissolve, `transform`→affine reveal,
`soul_escape` (zoom-ghost), `tremble` (shake+RGB split), `seventies` (VHS glitch). **6 static**: `blurry_h`,
`blurry_v`, `canvas` (letterbox blur), `clone` (grid tile), `multi` (alpha composite). Clone ports
`alpha→dissolve.frag`, `transform→affine_reveal.frag`, `blurry→blur.frag` via `shader_transition.dart`.

---

## 8. Clone mapping summary — grounded vs inferred

| AppMotion token | value | grounding |
|---|---|---|
| fast/medium/page/popup/slow/sheetLarge | 150/250/300/350/400/500 | **[FACT]** `m3_sys_motion_duration_*` |
| signature `Cubic(0,0,0.2,1)` | enter | **[FACT]** `legacy_decelerate` + Mach 300ms ease-in-out |
| exit `Cubic(0.4,0,1,1)` | exit | **[FACT]** `legacy_accelerate` |
| emphasizedDecelerate `Cubic(0.1,0.7,0.1,1)` | M3 emphasized | **[FACT]** `emphasized_decelerate` |
| machEaseInOut `Cubic(0.42,0,0.58,1)` | shop SKU pop | **[FACT]** shop_global CSS |
| microPop 100ms | SKU add/remove | **[FACT]** shop_global CSS |
| breathe 600ms | heartbeat pulse | **[FACT]** order_confirm CSS |
| shineSweep 2000ms | reward shine loop | **[FACT]** order_confirm/coupon CSS |
| spin 1000ms | spinner/wheel | **[FACT]** home/myprizescomp CSS |
| StaggerEntrance step 30ms | dropdown stagger | **[FACT]** home_page_main CSS (0/30/60ms) |
| carousel 3000ms | auto-advance | **[FACT]** kflexbox |
| splash 1.84s + curves | brand intro | **[FACT]** splash Lottie |
| emphasized `easeOutBack` | badge pop overshoot | **[INFERENCE]** intentional (M3 emphasized has no overshoot) |
| flip 280ms | price/value flip | **[INFERENCE]** between m3 250/300 |
| shimmer 1100ms | skeleton sweep | **[INFERENCE]** apk sweep is 0.7–0.8s; 1100 within 0.7–2s range |
| Lottie nominal durations | brand moments | **[INFERENCE]** real clips compiled away; painter/GIF fallback |

**Known gaps (candidate follow-ups):** haptic tap feedback (`performHapticFeedback` is everywhere in
Jameia, absent in the clone); VAP-style full-screen alpha-video promos; the cart free-delivery 11-frame
progress bar (clone has the PNG frames in `JameiaAssets.cartProgress` but no animated stepping yet).
