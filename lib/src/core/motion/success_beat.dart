import 'package:flutter/widgets.dart';

import 'motion.dart';

/// SUCCESS BEAT — how long a finished submit shows its check before the
/// screen moves on (docs/motion §9.4 #19, B2-04): the check draws in
/// ([AppMotion.slow], the busy disc's `LoaderDoneMark`), then holds
/// [AppMotion.successHold]; under reduced motion the check is there at once
/// and only the hold is kept. The page fires `Haptics.done()` when the
/// check appears, awaits [hold], then pops / replaces the route — so the
/// moment is seen instead of racing the navigation.
abstract final class SuccessBeat {
  /// The whole beat for this [context]'s motion setting.
  static Duration of(BuildContext context) => MotionGuard.reduced(context)
      ? AppMotion.successHold
      : AppMotion.slow + AppMotion.successHold;

  /// Waits out the beat. Check `context.mounted` after it.
  static Future<void> hold(BuildContext context) =>
      Future<void>.delayed(of(context));
}
