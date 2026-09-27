import 'package:flutter/material.dart';

/// **core/motion/** — the single MOTION POLICY (durations, curves, reduced-motion
/// gate). Feature code reads motion ONLY from here — never raw `Duration(...)`
/// or `Curves.*` — so the whole app shares one motion language and a11y is
/// enforced in one place.
///
/// PROVENANCE (verified against the decompiled Hero apk,
/// `com.sankuai.sailor.afooddelivery` v3.5.214). Hero renders through 5
/// runtimes (Compose/Litho/Mach-QuickJS/Recce-WASM/MRN) whose per-screen easing
/// lives in compiled bytecode and is NOT statically extractable. What IS
/// recoverable and grounds these tokens:
///   • `resources.arsc` bundles the full Material 3 motion system — Hero ships
///     Material3 1.4.0 — as `m3_sys_motion_duration_*` and `m3_sys_motion_easing_*`.
///     The durations/curves below map directly onto those tokens (cited inline).
///   • `assets/splash_lottie_default.json` — the one real Lottie (v5.7.1, fr=50,
///     op=92 ⇒ 1.84s); the Hero-style splash keeps to that ~2 s range.
/// Values tagged [INFERENCE] have no exact apk token and are reasoned choices.
class AppMotion {
  AppMotion._();

  // ── Durations — Material 3 `m3_sys_motion_duration_*` (resources.arsc) ─────
  static const Duration fast = Duration(milliseconds: 150); // m3 duration_150
  static const Duration medium = Duration(milliseconds: 250); // m3 duration_250
  static const Duration page = Duration(milliseconds: 300); // m3 duration_300

  /// Home centered-popup enter (`hero_popup_scaffold` — coupon pop / image-text
  /// / video pop). Maps to `m3_sys_motion_duration_350` — a touch slower than a
  /// page push: ~350ms fade + short bottom-slide. Its own token, not [page].
  static const Duration popup = Duration(milliseconds: 350); // m3 duration_350

  static const Duration slow = Duration(milliseconds: 400); // m3 duration_400
  static const Duration sheetLarge = Duration(
    milliseconds: 500,
  ); // m3 duration_500 (big sheets)

  /// Auto-advancing carousel dwell (gathering rail / banners). A content cadence
  /// (Timer interval), not an M3 motion token; 3000ms is a conventional dwell.
  /// [INFERENCE] — no apk token; tokenised so every carousel shares one rhythm.
  static const Duration carousel = Duration(milliseconds: 3000);
  static const Duration imageFade = Duration(
    milliseconds: 500,
  ); // m3 duration_500 — lazy image fade-in
  static const Duration shimmer = Duration(
    milliseconds: 1100,
  ); // skeleton sweep [INFERENCE] (~m3 _1000)

  /// Value-flip swap (price / free-ship threshold / cart total). Feed a
  /// [FlipValue] (`AnimatedSwitcher` + vertical `SlideTransition`) gated by
  /// `MotionGuard`. 280ms sits between `m3_sys_motion_duration_250` and `_300`.
  /// [INFERENCE] — no exact apk token at 280.
  static const Duration flip = Duration(milliseconds: 280);

  /// Delay between the items of an entrance cascade or a multi-star fill.
  /// [FACT] home_page_main staggered reveal = 0/30/60 ms
  /// (docs/hero_motion_reference.md §2), the step StaggerEntrance uses.
  static const Duration staggerStep = Duration(milliseconds: 30);

  // ── Mach-CSS-grounded tokens (extracted from `bundle.css.json` @keyframes) ──
  // See docs/hero_motion_reference.md §2. These are literal in-app values.
  /// SKU add/remove micro-pop (`scale(0)→scale(1)`). [FACT] shop_global CSS =
  /// 100ms `cubic-bezier(0.42,0,0.58,1)` ([machEaseInOut]). Snappier than [fast].
  static const Duration microPop = Duration(milliseconds: 100);

  /// "Heartbeat" attention pulse (`scale(1)→scale(1.1)`, infinite alternate).
  /// [FACT] order_confirm_global CSS = 600ms.
  static const Duration breathe = Duration(milliseconds: 600);

  /// Reward/coupon shine sweep (`translateX(-100→350dp)`, infinite). [FACT]
  /// order_confirm / coupon-list CSS = 2000ms (delay 1000ms). Per-loop length.
  static const Duration shineSweep = Duration(milliseconds: 2000);

  // ── Ambient + reveal tokens (Pro paywall / rewards polish) ────────────────
  /// Idle "float" bob of a hero illustration (up and back, one period).
  /// [INFERENCE] — slow enough to read as calm, not as loading.
  static const Duration floatLoop = Duration(milliseconds: 3200);

  /// Breathing glow behind a hero (opacity .45→.75, scale 1→1.08, and back).
  /// [FACT] jm3eia.store `.animate-pro-glow` = 5s ease-in-out infinite.
  static const Duration glowPulse = Duration(milliseconds: 5000);

  /// Self-drawing outline (arch / underline) — path length 0→1.
  /// [INFERENCE] — long enough to be seen, short enough not to delay reading.
  static const Duration drawOn = Duration(milliseconds: 700);

  /// Number count-up (points, prices) from the old value to the new one.
  /// [INFERENCE].
  static const Duration countUp = Duration(milliseconds: 700);

  /// One-shot celebration burst (subscribe success, reward applied).
  /// [INFERENCE].
  static const Duration confetti = Duration(milliseconds: 1400);

  /// Slow holographic sheen across a member card (one sweep + rest).
  /// [INFERENCE].
  static const Duration sheen = Duration(milliseconds: 3600);

  // ── Loaders (the Hero dots: `BrandedDotPainter`, `AppLoader`, `BusyOverlay`)
  /// One full loop of the two loader dots: two swaps, each dot passing in
  /// front once, a short rest side by side after each. [INFERENCE] — the pace
  /// of the reference two-dot loaders (Glovo), ~0.6 s a swap.
  static const Duration loaderOrbit = Duration(milliseconds: 1200);

  /// How long a block loader waits before it appears, so a load that answers
  /// at once never flashes a loader. [INFERENCE].
  static const Duration loaderDelay = Duration(milliseconds: 150);

  /// Once shown, the blocking busy overlay stays at least this long, so a
  /// fast reply reads as a deliberate beat, not a flicker. [INFERENCE].
  static const Duration busyMinVisible = Duration(milliseconds: 500);

  // ── Splash (Hero brand intro, features/splash) ─────────────────────────────
  // One-shot runs from the launch-screen frame to the hand-off, gated by
  // [MotionGuard]. Hero's own intro is ~2 s of logo motion on the brand
  // colour; ours stay in that range. [INFERENCE] — design choices.
  /// The bag takes off, swoops up and delivers the name under it.
  static const Duration splashWordmark = Duration(milliseconds: 2000);

  /// Groceries drop into the bag before it takes off.
  static const Duration splashBasket = Duration(milliseconds: 2550);

  /// A white disc bursts out of the bag into the full-colour logo on white.
  static const Duration splashBurst = Duration(milliseconds: 2250);

  /// Reduced motion: how long the finished logo stays before the hand-off.
  static const Duration splashReducedHold = Duration(milliseconds: 700);

  /// The launch frame stays still this long after it reached the screen, so
  /// the OS splash's exit cross-fade ends on an identical picture before
  /// anything moves.
  static const Duration splashHandOffHold = Duration(milliseconds: 250);

  /// Longest wait for the engine to report the first rasterized frame before
  /// the intro starts anyway (test bindings never report frame timings).
  static const Duration splashFirstFrameWait = Duration(milliseconds: 600);

  /// A ring of colour spreading from a finger on the splash.
  static const Duration splashTapRipple = Duration(milliseconds: 700);

  /// The bag's happy hop (and cape flick) when it is tapped on the splash.
  static const Duration splashMarkHop = Duration(milliseconds: 520);

  // ── Curves — Material 3 `m3_sys_motion_easing_*` (resources.arsc) ──────────
  /// Signature enter curve = `m3_sys_motion_easing_legacy_decelerate` =
  /// `cubic-bezier(0, 0, 0.2, 1)` — strong ease-out (fast start, gentle settle).
  /// [FACT] verified in the apk's resources.arsc.
  static const Curve signature = Cubic(0, 0, 0.2, 1);

  /// Used as the shared "standard" enter. NOTE: M3's own
  /// `m3_sys_motion_easing_standard` is `cubic-bezier(0.2, 0, 0, 1)`; we
  /// deliberately alias [standard] to the legacy-decelerate [signature] for a
  /// softer settle across the app. [INFERENCE] — intentional deviation.
  static const Curve standard = signature;

  /// Pop/overshoot curve for badges & chips. NOTE: M3's
  /// `m3_sys_motion_easing_emphasized` is an overshoot-free 2-bezier path and
  /// `..._emphasized_decelerate` is `cubic-bezier(0.1, 0.7, 0.1, 1)`; we use
  /// Flutter's `easeOutBack` because the brand pops want a slight overshoot the
  /// M3 emphasized curve doesn't give. [INFERENCE] — intentional deviation.
  static const Curve emphasized = Curves.easeOutBack;

  /// M3 emphasized-decelerate, faithful to the apk token
  /// (`cubic-bezier(0.1, 0.7, 0.1, 1)`) for callers that want the true M3
  /// emphasized entrance (no overshoot). [FACT].
  static const Curve emphasizedDecelerate = Cubic(0.1, 0.7, 0.1, 1);

  /// The ease-in-out Hero's Mach SKU pop / micro-interactions use literally.
  /// [FACT] shop_global `bundle.css.json` = `cubic-bezier(0.42, 0, 0.58, 1)`.
  /// Pair with [microPop]. (Standard CSS `ease-in-out` control points.)
  static const Curve machEaseInOut = Cubic(0.42, 0, 0.58, 1);

  static const Curve decelerate = Curves.decelerate;

  /// Exit/disappear curve = `m3_sys_motion_easing_legacy_accelerate` =
  /// `cubic-bezier(0.4, 0, 1, 1)` — the mirrored ease-IN paired with
  /// [signature] for the `*_out` half of a transition. [FACT] resources.arsc.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  // ── Scale begin/end pairs ──────────────────────────────────────────────────
  // [INFERENCE] — Hero's dialog/scale anims live in compiled bundles (no
  // `res/anim` ships in this apk); these are conventional Material values.
  /// Dialog appear settles in from above 1.0 (scale 1.1→1.0 + fade). Pair [medium].
  static const double dialogScaleBegin = 1.1;

  /// Chip/badge/FAB pop grows from zero (0→1). Pair [medium] + [emphasized].
  static const double popScaleBegin = 0.0;
  static const double popScaleEnd = 1.0;

  // ── Page slide offsets ─────────────────────────────────────────────────────
  /// Page enter slides up a full screen-height + fades (translate Y 100%→0).
  /// Pair with [page] + [signature]. [INFERENCE] — conventional activity slide.
  static const Offset pageSlideBegin = Offset(0, 1); // 100% from bottom
  static const Offset pageSlideEnd = Offset.zero;
}

/// Single gate every animation routes through, so the OS "remove animations"
/// accessibility flag degrades motion to instant in ONE place.
class MotionGuard {
  MotionGuard._();

  /// True when the user/OS has requested reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [d] normally; [Duration.zero] under reduced motion.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// [animated] normally; [instant] under reduced motion.
  static Curve curve(
    BuildContext context,
    Curve animated, {
    Curve instant = Curves.linear,
  }) => reduced(context) ? instant : animated;
}
