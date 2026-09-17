import 'package:flutter/services.dart';

/// **core/motion/haptics.dart** — the single TACTILE-feedback policy. Jameia fires
/// `performHapticFeedback` pervasively (verified in the apk: Compose
/// `performHapticFeedback`, `android/os/Vibrator`, `isPremiumVibratorEnabled` —
/// see docs/jameia_motion_reference.md §6). Feature code routes haptics ONLY
/// through here so the whole app shares one tactile language and a global mute
/// lives in one place.
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

  /// Global mute. Wire to a user setting if/when one exists; defaults on.
  static bool enabled = true;

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

  // Convenience shorthands.
  static void tap() => fire(HapticKind.tap);
  static void selection() => fire(HapticKind.selection);
  static void success() => fire(HapticKind.success);
  static void warning() => fire(HapticKind.warning);
}
