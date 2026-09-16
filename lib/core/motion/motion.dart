import 'package:flutter/material.dart';

/// **core/motion/** — the single MOTION POLICY (durations, curves, reduced-motion
/// gate). Feature code reads motion ONLY from here — never raw `Duration(...)`
/// or `Curves.*` — so the whole app shares one motion language and a11y is
/// enforced in one place.
///
/// PROVENANCE (verified against the decompiled KeeTa apk,
/// `com.sankuai.sailor.afooddelivery` v3.5.214). KeeTa renders through 5
/// runtimes (Compose/Litho/Mach-QuickJS/Recce-WASM/MRN) whose per-screen easing
/// lives in compiled bytecode and is NOT statically extractable. What IS
/// recoverable and grounds these tokens:
///   • `resources.arsc` bundles the full Material 3 motion system — KeeTa ships
///     Material3 1.4.0 — as `m3_sys_motion_duration_*` and `m3_sys_motion_easing_*`.
///     The durations/curves below map directly onto those tokens (cited inline).
///   • `assets/splash_lottie_default.json` — the one real Lottie (v5.7.1, fr=50,
///     op=92 ⇒ 1.84s) grounds the splash timing.
///   • `assets/*.fsh` GLSL shaders ground `core/motion/shader_transition.dart`.
/// Values tagged [INFERENCE] have no exact apk token and are reasoned choices.
class AppMotion {
  AppMotion._();

  // ── Durations — Material 3 `m3_sys_motion_duration_*` (resources.arsc) ─────
  static const Duration fast = Duration(milliseconds: 150); // m3 duration_150
  static const Duration medium = Duration(milliseconds: 250); // m3 duration_250
  static const Duration page = Duration(milliseconds: 300); // m3 duration_300

  /// Home centered-popup enter (`keeta_popup_scaffold` — coupon pop / image-text
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

  // ── Mach-CSS-grounded tokens (extracted from `bundle.css.json` @keyframes) ──
  // See docs/keeta_motion_reference.md §2. These are literal in-app values.
  /// SKU add/remove micro-pop (`scale(0)→scale(1)`). [FACT] shop_global CSS =
  /// 100ms `cubic-bezier(0.42,0,0.58,1)` ([machEaseInOut]). Snappier than [fast].
  static const Duration microPop = Duration(milliseconds: 100);

  /// "Heartbeat" attention pulse (`scale(1)→scale(1.1)`, infinite alternate).
  /// [FACT] order_confirm_global CSS = 600ms.
  static const Duration breathe = Duration(milliseconds: 600);

  /// Reward/coupon shine sweep (`translateX(-100→350dp)`, infinite). [FACT]
  /// order_confirm / coupon-list CSS = 2000ms (delay 1000ms). Per-loop length.
  static const Duration shineSweep = Duration(milliseconds: 2000);

  /// Spinner / lottery-wheel rotation (`rotateZ 0→360`, linear infinite). [FACT]
  /// home_page_main spinner + myprizescomp wheel = 1000ms per revolution.
  static const Duration spin = Duration(milliseconds: 1000);

  // ── Brand-moment nominal durations ─────────────────────────────────────────
  // NOTE: KeeTa's heart / pay-success / refresh / add-on clips are NOT shipped
  // as loose Lottie in this apk — they live inside compiled Mach/Recce/Litho
  // bundles (only `splash_lottie_default.json` ships loose). So these are the
  // NOMINAL one-shot lengths the painter/GIF fallbacks in `BrandMoment` /
  // `BrandedLoader` run to (and the reduced-motion skip timing). [INFERENCE] —
  // typical brand-moment lengths; swap in a real Lottie via the widget's
  // optional `asset:` and these become the fallback only.
  static const Duration lottieHeart = Duration(milliseconds: 2070);
  static const Duration lottiePaySuccess = Duration(milliseconds: 4000);
  static const Duration lottieRefresh = Duration(milliseconds: 1630);
  static const Duration lottieAddOnDone = Duration(milliseconds: 430);
  static const Duration lottieFollowStore = Duration(milliseconds: 2000);
  static const Duration lottieDotLoader = Duration(milliseconds: 1600);

  // ── Splash intro (grounded: splash_lottie_default.json, fr=50 op=92 ⇒ 1.84s) ─
  /// Branded splash fade-in + gentle Ken-Burns zoom-settle length. One-shot,
  /// gated by [MotionGuard] (reduced-motion → instant). 1600ms sits just under
  /// the real splash Lottie's 1.84s so the art settles before navigation.
  static const Duration splashKenBurns = Duration(milliseconds: 1600);

  /// Ken-Burns start scale for the splash art — settles 1.08 → 1.0 (subtle
  /// push-in). [INFERENCE] — a design choice, not encoded in the Lottie.
  static const double splashZoomBegin = 1.08;

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

  /// The ease-in-out KeeTa's Mach SKU pop / micro-interactions use literally.
  /// [FACT] shop_global `bundle.css.json` = `cubic-bezier(0.42, 0, 0.58, 1)`.
  /// Pair with [microPop]. (Standard CSS `ease-in-out` control points.)
  static const Curve machEaseInOut = Cubic(0.42, 0, 0.58, 1);

  static const Curve decelerate = Curves.decelerate;

  /// Exit/disappear curve = `m3_sys_motion_easing_legacy_accelerate` =
  /// `cubic-bezier(0.4, 0, 1, 1)` — the mirrored ease-IN paired with
  /// [signature] for the `*_out` half of a transition. [FACT] resources.arsc.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Alias of [exit] — the paired exit/companion curve.
  static const Curve signatureExit = exit;

  // ── Scale begin/end pairs ──────────────────────────────────────────────────
  // [INFERENCE] — KeeTa's dialog/scale anims live in compiled bundles (no
  // `res/anim` ships in this apk); these are conventional Material values.
  /// Dialog appear settles in from above 1.0 (scale 1.1→1.0 + fade). Pair [medium].
  static const double dialogScaleBegin = 1.1;
  static const double dialogScaleEnd = 1.0;

  /// Chip/badge/FAB pop grows from zero (0→1). Pair [medium] + [emphasized].
  static const double popScaleBegin = 0.0;
  static const double popScaleEnd = 1.0;

  // ── Page slide offsets ─────────────────────────────────────────────────────
  /// Page enter slides up a full screen-height + fades (translate Y 100%→0).
  /// Pair with [page] + [signature]. [INFERENCE] — conventional activity slide.
  static const Offset pageSlideBegin = Offset(0, 1); // 100% from bottom
  static const Offset pageSlideEnd = Offset.zero;

  /// Home centered-popup enter slide — `keeta_popup_scaffold` settles up a short
  /// 12% + fades (paired with [popup] + [signature]). Smaller than a full page
  /// slide because the popup is already centred; it just lifts into place.
  static const Offset popupSlideBegin = Offset(0, 0.12);
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
