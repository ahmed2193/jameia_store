import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// **core/motion/haptics.dart** — the single TACTILE-feedback policy
/// (docs/motion §9.5 Haptics map). Feature code routes haptics ONLY through
/// here — preferably through the intent helpers ([Haptics.cartAdd],
/// [Haptics.commit], [Haptics.refuse] …) — so the whole app shares one tactile
/// language and the customer's mute (Settings → Vibration, [Haptics.enabled])
/// lives in one place. Never from a cubit; one haptic per gesture; fire when
/// the visual confirms (tap-up, or the landing of a flight).
///
/// NOTE: haptics are INDEPENDENT of the visual reduced-motion gate
/// ([MotionGuard]) — "remove animations" silences on-screen movement, not touch
/// feedback. Mute haptics via [Haptics.enabled]. On web/desktop the underlying
/// [HapticFeedback] calls are no-ops, so this is safe to call everywhere.
enum HapticKind {
  /// Light confirmation for a primary tap (button / card press).
  tap,

  /// Discrete "click" for a selection change (chip / tab / quantity step).
  selection,

  /// Positive medium thud — order placed / payment success / reward claimed.
  success,

  /// Stronger heavy buzz — error / destructive confirm / warning.
  warning,
}

class Haptics {
  Haptics._();

  /// Global mute: the customer's Settings choice, applied by the app root at
  /// launch and on every change. Defaults on.
  static bool enabled = true;

  /// A refusal buzzes at most once in this window, however fast the taps.
  /// [INFERENCE].
  static const Duration refuseGap = Duration(milliseconds: 500);

  static DateTime? _lastRefusal;

  /// Forgets the last refusal (and unmutes): the throttle reads the real
  /// clock, so tests that refuse one after another reset it between them.
  @visibleForTesting
  static void debugReset() {
    _lastRefusal = null;
    enabled = true;
  }

  /// Fire a haptic of [kind]. Fire-and-forget (the platform call is async and
  /// a no-op on devices/platforms without a vibrator).
  static void fire(HapticKind kind) {
    if (!enabled) return;
    switch (kind) {
      case HapticKind.tap:
        HapticFeedback.lightImpact();
      case HapticKind.selection:
        HapticFeedback.selectionClick();
      case HapticKind.success:
        HapticFeedback.mediumImpact();
      case HapticKind.warning:
        HapticFeedback.heavyImpact();
    }
  }

  // Kind shorthands.
  static void tap() => fire(HapticKind.tap);
  static void selection() => fire(HapticKind.selection);
  static void success() => fire(HapticKind.success);
  static void warning() => fire(HapticKind.warning);

  // ── Intent helpers (§9.5): name what happened, the map picks the kind ──────
  /// Add to cart / "+" / increment: a click. The first add of a session on
  /// Home ([first]) is a success instead.
  static void cartAdd({bool first = false}) =>
      fire(first ? HapticKind.success : HapticKind.selection);

  /// Remove / "−" / delete a line: a light tap.
  static void cartRemove() => fire(HapticKind.tap);

  /// A primary commit button pressed (Add, Save, Continue, Place order).
  static void commit() => fire(HapticKind.tap);

  /// A chip, segment, radio, option row or sort pick; pull-to-refresh armed.
  static void pick() => fire(HapticKind.selection);

  /// A blocked tap, an invalid submit, an action that needs the internet:
  /// a warning, at most once per [refuseGap].
  static void refuse() {
    final now = DateTime.now();
    final last = _lastRefusal;
    if (last != null && now.difference(last) < refuseGap) return;
    _lastRefusal = now;
    fire(HapticKind.warning);
  }

  /// A destructive action confirmed (delete an address, cancel an order, log
  /// out) — on the confirm, never on opening the dialog.
  static void destructive() => fire(HapticKind.warning);

  /// A discard the customer chose outside the cart (a voice recording binned,
  /// an assistant proposal turned down): a light tap, like a cart remove.
  static void discard() => fire(HapticKind.tap);

  /// A real accomplishment: order placed, Pro subscribed, profile saved,
  /// reward earned, language switched. Never for a routine save.
  static void done() => fire(HapticKind.success);
}
