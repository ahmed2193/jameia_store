import 'package:flutter/material.dart';

/// **core/motion/** — the single MOTION POLICY (durations, curves, reduced-motion
/// gate). Feature code reads motion ONLY from here — never raw `Duration(...)`
/// or `Curves.*` — so the whole app shares one motion language and a11y is
/// enforced in one place. (Mirrors the reference project's `context.motion.*`
/// + `MotionGuard`.)
class AppMotion {
  AppMotion._();

  // ── Durations (1Day-decoded `res/anim`) ───────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250); // dialog / scale
  static const Duration page = Duration(milliseconds: 300); // activity slide
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration sheetLarge = Duration(milliseconds: 500); // big sheets
  static const Duration imageFade = Duration(milliseconds: 500); // lazy image fade-in
  static const Duration shimmer = Duration(milliseconds: 1100); // skeleton sweep

  /// Value-flip swap (price / free-ship threshold / cart total) — 1Day's
  /// vertical flip family (`flip_anim_*`, `checkout_goods_price_flip`,
  /// `freeshipping_anim`). ~250–300ms; 280ms is the in-range token.
  /// [FACT] MOTION_AND_NAVIGATION.md §3C/§6. Feed a `ValueFlip`
  /// (`AnimatedSwitcher` + vertical `SlideTransition`) gated by `MotionGuard`.
  static const Duration flip = Duration(milliseconds: 280);

  // ── Lottie brand-moment nominal durations (decoded (op-ip)/fr) ─────────────
  /// Wishlist heart pop (`like_anim_new.json`, 124f@60). Lottie owns playback;
  /// expose the nominal length for reduced-motion fallbacks / one-shot timing.
  static const Duration lottieHeart = Duration(milliseconds: 2070);

  /// Payment-success check (`pay_success_tick.json`, 120f@30). Nominal one-shot
  /// length — use to time the post-success transition / reduced-motion skip.
  static const Duration lottiePaySuccess = Duration(milliseconds: 4000);

  /// Home pull-to-refresh header (`si_home_refresh_immersive.json`, 39f@24).
  /// One loop length for the branded refresh header.
  static const Duration lottieRefresh = Duration(milliseconds: 1630);

  /// Add-on item done checkmark (`store_info_add_on_item_finish.json`, 13f@30).
  /// Short one-shot tick for the add-on / coupon-apply confirm.
  static const Duration lottieAddOnDone = Duration(milliseconds: 430);

  /// Store-follow brand moment (`shop_logo_follow`, ~2.0s). Nominal one-shot.
  static const Duration lottieFollowStore = Duration(milliseconds: 2000);

  /// Branded dot loader (`progress.json`, ~1.6s, loops). Per-loop length.
  static const Duration lottieDotLoader = Duration(milliseconds: 1600);

  // ── Splash intro ───────────────────────────────────────────────────────────
  /// Branded splash fade-in + gentle Ken-Burns zoom-settle length. One-shot,
  /// gated by [MotionGuard] (reduced-motion → instant). Sits just under the
  /// 1.5–1.8s bootstrap window so the art settles before navigation.
  static const Duration splashKenBurns = Duration(milliseconds: 1600);

  /// Ken-Burns start scale for the splash art — settles 1.08 → 1.0 (subtle push-in).
  static const double splashZoomBegin = 1.08;

  // ── Curves ─────────────────────────────────────────────────────────────────
  /// 1Day's signature enter curve — `anim/interpolator_style2` =
  /// `pathInterpolator(0,0, 0.2,1)` — strong ease-out (fast start, gentle settle).
  static const Curve signature = Cubic(0, 0, 0.2, 1);
  static const Curve standard = signature;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  /// Exit/disappear curve — `anim/interpolator_style1`, the paired companion of
  /// [signature]: the mirrored ease-IN `Cubic(0.4,0,1,1)` used by the `*_out`
  /// / `*_disappear` / `*_slide_out` halves of every 1Day transition pair.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// `anim/interpolator_style1` — the paired exit/companion curve (alias of
  /// [exit]); used by dialog appear + activity exit alongside [signature].
  /// [INFERENCE] style1's exact control points aren't given; ease-in is the
  /// documented role. MOTION_AND_NAVIGATION.md §2.
  static const Curve signatureExit = exit;

  // ── Scale begin/end pairs ──────────────────────────────────────────────────
  /// Dialog appear SETTLES in from above 1.0 — `dialog_anim_appear`
  /// (scale 1.1→1.0 + fade, 250ms). Pair with [medium]. Not grow-from-zero.
  static const double dialogScaleBegin = 1.1;

  /// Dialog appear settle end scale — `dialog_anim_appear` toXScale=1.0.
  static const double dialogScaleEnd = 1.0;

  /// Chip/badge/FAB pop grows from zero — `scale_in` (0→1, 250ms). Pair [medium].
  static const double popScaleBegin = 0.0;

  /// Pop/badge grow end scale — `scale_in` toXScale=1.0.
  static const double popScaleEnd = 1.0;

  // ── Page slide offsets ─────────────────────────────────────────────────────
  /// Page enter slides up a full screen-height + fades — `activity_slide_in`
  /// (translate Y 100%→0, 300ms, ease-out). Pair with [page] + [signature].
  static const Offset pageSlideBegin = Offset(0, 1); // 100% from bottom

  /// Page enter slide end — `activity_slide_in` resting position.
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
  static Curve curve(BuildContext context, Curve animated, {Curve instant = Curves.linear}) =>
      reduced(context) ? instant : animated;
}
