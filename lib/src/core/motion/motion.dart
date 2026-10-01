import 'package:flutter/material.dart';

import 'spring_curve.dart';

export 'spring_curve.dart' show AppSprings, SpringCurve;

/// **core/motion/** — the single MOTION POLICY (durations, curves, springs,
/// scalars and the reduced-motion gate). Feature code reads motion ONLY from
/// here — never raw `Duration(...)` or `Curves.*` — so the whole app shares
/// one motion language and a11y is enforced in one place. The full system is
/// `docs/motion/motion_design_system_2026.md` §9 (token table §9.2).
///
/// One token story, two halves: [AppMotion] holds the time-based tokens and
/// [AppSprings] (re-exported from `spring_curve.dart`) the spatial springs.
/// Opacity and colour never use a spring.
///
/// PROVENANCE. The Material 3 values below match the `m3_sys_motion_*`
/// tokens bundled in the reference delivery apk the motion study decompiled
/// (`com.sankuai.sailor.afooddelivery` v3.5.214 — not a Hero build; Material3
/// 1.4.0 in `resources.arsc`). "Mach CSS" values come from that apk's
/// `bundle.css.json` keyframes (`docs/hero_motion_reference.md` §2). Values
/// tagged [INFERENCE] have no source token and are reasoned choices.
class AppMotion {
  AppMotion._();

  // ── The duration scale (§9.2): microPop · fast · medium · page · slow ──────
  /// Press-in and tiny ticks. [FACT] Mach CSS SKU micro-pop = 100 ms.
  static const Duration microPop = Duration(milliseconds: 100);

  /// Fades, colour, press release, small exits, skeleton → content, image
  /// fade-in, tab fade. m3 `duration_short3` (150 ms).
  static const Duration fast = Duration(milliseconds: 150);

  /// A component changing state, a value roll / flip, a dialog enter, a sheet
  /// or modal exit, an expand. m3 `duration_medium1` (250 ms).
  static const Duration medium = Duration(milliseconds: 250);

  /// A page push / pop, a sheet enter, a carousel slide. m3 `duration_medium2`
  /// (300 ms).
  static const Duration page = Duration(milliseconds: 300);

  /// Fly-to-cart, a large sheet enter, a scroll-to glide, an earned count-up.
  /// The ceiling for functional motion. m3 `duration_medium4` (400 ms).
  static const Duration slow = Duration(milliseconds: 400);

  // ── Rhythm ─────────────────────────────────────────────────────────────────
  /// The only cascade step between list items / stars. [FACT] the reference
  /// home staggered reveal = 0/30/60 ms (`docs/hero_motion_reference.md` §2).
  static const Duration staggerStep = Duration(milliseconds: 30);

  /// Items after this index start with it: a cascade never runs long.
  static const int staggerMaxItems = 6;

  /// A success state (a check on a button) stays this long before the screen
  /// moves on. [INFERENCE].
  static const Duration successHold = Duration(milliseconds: 400);

  /// One caret / recording-dot blink (on + off). [INFERENCE] — the platform
  /// caret rhythm.
  static const Duration blinkPeriod = Duration(milliseconds: 1000);

  /// How long a snack bar stays. [INFERENCE] — Material's own dwell.
  static const Duration snackDwell = Duration(milliseconds: 4000);

  // ── Loaders (the Hero dots: `BrandedDotPainter`, `AppLoader`, `BusyOverlay`)
  /// How long a block loader waits before it appears, so a load that answers
  /// at once never flashes a loader — also under reduced motion. [INFERENCE].
  static const Duration loaderDelay = Duration(milliseconds: 150);

  /// Once shown, the blocking busy overlay stays at least this long, so a
  /// fast reply reads as a deliberate beat, not a flicker. [INFERENCE].
  static const Duration busyMinVisible = Duration(milliseconds: 500);

  /// One full loop of the two loader dots: two swaps, each dot passing in
  /// front once, a short rest side by side after each. [INFERENCE] — the pace
  /// of the reference two-dot loaders (Glovo), ~0.6 s a swap.
  static const Duration loaderOrbit = Duration(milliseconds: 1200);

  /// Skeleton sweep. [INFERENCE] (~m3 `duration_extra_long4`, 1000 ms).
  static const Duration shimmer = Duration(milliseconds: 1100);

  // ── Signals and reveals ────────────────────────────────────────────────────
  /// A single `TintFlash` wash ("changed", "back online"); the heartbeat
  /// attention pulse. [FACT] Mach CSS order_confirm pulse = 600 ms.
  static const Duration breathe = Duration(milliseconds: 600);

  /// A self-drawing check / outline / ready wipe (path length 0 → 1) — only
  /// that. [INFERENCE] — long enough to be seen, short enough not to delay
  /// reading.
  static const Duration drawOn = Duration(milliseconds: 700);

  /// The map camera's reframe or zoom glide (`HeroMapCamera.glideTo`).
  /// [INFERENCE] — [drawOn]'s length: long enough for the tiles to follow; a
  /// shorter glide reads as a jump.
  static const Duration cameraGlide = drawOn;

  /// One celebration burst (subscribe success, reward applied). [INFERENCE].
  static const Duration confetti = Duration(milliseconds: 1400);

  // ── Ambient (decorative loops: see [ambientBudget]) ────────────────────────
  /// Auto-advance dwell of a carousel, a rotating hint / ticker line.
  /// [INFERENCE] — a conventional 3 s dwell; no source token.
  static const Duration carousel = Duration(milliseconds: 3000);

  /// One ambient float cycle (up and back). [INFERENCE] — slow enough to read
  /// as calm, not as loading.
  static const Duration floatLoop = Duration(milliseconds: 3200);

  /// One `LightSweep` period: the pass plus its rest. [INFERENCE].
  static const Duration sheen = Duration(milliseconds: 3600);

  /// Total run time of any decorative loop before it rests. [INFERENCE] —
  /// under WCAG 2.2.2's five seconds.
  static const Duration ambientBudget = Duration(milliseconds: 5000);

  // ── Curves — Material 3 `m3_sys_motion_easing_*` ───────────────────────────
  /// Default enter / standard curve = m3 `easing_legacy_decelerate` =
  /// `cubic-bezier(0, 0, 0.2, 1)` — fast start, gentle settle. [FACT].
  static const Curve signature = Cubic(0, 0, 0.2, 1);

  /// Every exit / dismiss = m3 `easing_legacy_accelerate` =
  /// `cubic-bezier(0.4, 0, 1, 1)`, the mirror of [signature]. [FACT].
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Large reveals, count-up, draw-on = m3 `easing_emphasized_decelerate`
  /// (`cubic-bezier(0.1, 0.7, 0.1, 1)`; M3 web uses 0.05, not visible). [FACT].
  static const Curve emphasizedDecelerate = Cubic(0.1, 0.7, 0.1, 1);

  /// "Move from A to B while visible" (a thumb, an ambient float). [FACT]
  /// Mach CSS SKU pop = `cubic-bezier(0.42, 0, 0.58, 1)`.
  static const Curve machEaseInOut = Cubic(0.42, 0, 0.58, 1);

  /// Loops, shimmer, marquees, scroll-driven motion.
  static const Curve linear = Curves.linear;

  // ── Scalars ────────────────────────────────────────────────────────────────
  /// A dialog settles in from above 1 (scale 1.1 → 1 + fade). [INFERENCE].
  static const double dialogScaleBegin = 1.1;

  /// The one card / button press depth.
  static const double pressedScale = 0.97;

  /// The press depth of an icon button under 48 dp.
  static const double pressedScaleSmall = 0.92;

  /// Shared-axis page shift, in logical pixels.
  static const double slideShift = 30;

  /// List and cascade item rise, in logical pixels — also how far a line
  /// travels in a vertical swap (`VerticalSwapTransition`: a ticker, a
  /// rotating hint, a flipped label).
  static const double entranceRise = 8;

  // ── Springs used as named tokens ──────────────────────────────────────────
  /// A segmented control's thumb slide (§9.4 #27): the calm spring, run over
  /// its own settle time (`thumbSlide.duration`). Every thumb — the language
  /// switch, checkout's delivery / pickup, the Cart tab's pill, My coupons'
  /// tabs, Pro's plans — slides on this one (`SegmentedThumbTrack`).
  static SpringCurve get thumbSlide => AppSprings.calm;
}

/// Single gate every animation routes through, so the OS accessibility flags
/// degrade motion in ONE place (§9.2 MotionGuard).
///
/// - [reduced]: the customer asked for less motion — Android "Remove
///   animations" (`disableAnimations`) or iOS "Reduce Motion".
/// - [off]: only `disableAnimations`; motion becomes instant.
/// - `reduced && !off` means REPLACE: spatial movement becomes a fast
///   cross-fade, loops stop, loaders keep a slow breathe. Until a primitive
///   implements its replacement, [duration] keeps it instant.
class MotionGuard {
  MotionGuard._();

  /// True when the OS asks for reduced motion: `disableAnimations` (Android
  /// "Remove animations") or iOS `AccessibilityFeatures.reduceMotion`.
  ///
  /// `MediaQueryData` does not carry iOS reduce motion, so it is read from
  /// the view's platform dispatcher: a toggle while a screen is open applies
  /// on that screen's next rebuild.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) || _iosReduceMotion(context);

  /// True only for `disableAnimations`: motion becomes instant.
  static bool off(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static bool _iosReduceMotion(BuildContext context) =>
      View.maybeOf(context)
          ?.platformDispatcher
          .accessibilityFeatures
          .reduceMotion ??
      false;

  /// [d] normally; [Duration.zero] under reduced motion.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// [animated] normally; [instant] under reduced motion.
  static Curve curve(
    BuildContext context,
    Curve animated, {
    Curve instant = Curves.linear,
  }) => reduced(context) ? instant : animated;

  /// Whether a decorative loop may run here: not under reduced motion, not
  /// while a screen reader walks the page (`accessibleNavigation`), and not
  /// while tickers are muted (a hidden tab, a covered route). Off-screen
  /// gating is the caller's (an on-screen gate).
  static bool ambientAllowed(BuildContext context) =>
      !reduced(context) &&
      !MediaQuery.accessibleNavigationOf(context) &&
      TickerMode.valuesOf(context).enabled;

  /// Scrolls [position] to [to] over [duration] with [curve], or JUMPS when
  /// motion is reduced: a scroll animation asserts on a zero duration, so
  /// this never hands one to `animateTo`.
  static Future<void> scrollTo(
    BuildContext context,
    ScrollPosition position,
    double to, {
    Duration duration = AppMotion.page,
    Curve curve = AppMotion.signature,
  }) {
    final run = MotionGuard.duration(context, duration);
    if (run == Duration.zero) {
      position.jumpTo(to);
      return Future<void>.value();
    }
    return position.animateTo(to, duration: run, curve: curve);
  }

  /// [PageController] twin of [scrollTo]: glides to [page], or jumps when
  /// motion is reduced.
  static Future<void> pageTo(
    BuildContext context,
    PageController controller,
    int page, {
    Duration duration = AppMotion.page,
    Curve curve = AppMotion.signature,
  }) {
    final run = MotionGuard.duration(context, duration);
    if (run == Duration.zero) {
      controller.jumpToPage(page);
      return Future<void>.value();
    }
    return controller.animateToPage(page, duration: run, curve: curve);
  }
}
