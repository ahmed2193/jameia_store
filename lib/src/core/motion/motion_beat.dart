import 'motion.dart';

/// The BEATS of a sequenced state change (docs/motion §9.1 #5 "one primary
/// motion per moment", D17 extended, backlog B2-03). When one tap or one
/// server reply changes several blocks of a screen on the same frame, they
/// move one after another instead of all at once:
///
/// 1. [primary] — the control the customer touched (a thumb, a switch, a
///    stepper, the card that was added from) answers at once;
/// 2. [second] — what it changed nearby follows (receipt lines open, the
///    price rolls, a label flips);
/// 3. [third] — the rest lands last (totals, a decorative hero).
///
/// One beat is [AppMotion.medium], the component-change duration, so each
/// motion starts as the one before it settles. Pair with `DeferredValue`
/// (a value that lands on its beat) or a delayed trigger; reduced motion
/// drops the waits (DeferredValue does it itself). Only real changes wait:
/// a first paint shows everything at once.
abstract final class MotionBeat {
  /// The touched control: no wait.
  static const Duration primary = Duration.zero;

  /// One beat after the primary motion started.
  static const Duration second = AppMotion.medium;

  /// Two beats after the primary motion started (2 × [AppMotion.medium]).
  static const Duration third = Duration(milliseconds: 500);

  /// [beat] beats after the primary motion started (0 = [primary]) — for a
  /// moment with more than three parts.
  static Duration at(int beat) => AppMotion.medium * beat;
}
