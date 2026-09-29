import 'package:flutter/widgets.dart';

import '../../../../../core/motion/motion.dart';

/// Whether the assistant's buddy may move right now (docs/motion §9.6 §3):
/// every mascot animation — a wake blink, a look, a hop, a wave, a wink, a
/// mood ease — asks [mayMoveOf] before it starts. Its host says what it
/// knows ([mayMove] `false` while the customer types, scrolls, reads a
/// streaming answer, records a voice message, while a page, sheet or dialog
/// covers it or the app is away); [MotionGuard.ambientAllowed] adds reduced
/// motion, a screen reader and a muted tab or route. Without a gate above,
/// only that guard decides.
///
/// [holding]: another primary motion plays (an add-to-cart flight, a
/// confetti burst): one reaction may wait for it, the rest are dropped.
/// [sensitive]: the buddy is under a covering page (checkout, a busy
/// submit), so whatever it had to say is cut and never replayed.
///
/// Direct manipulation (dragging the launcher) never asks: it follows the
/// finger.
class BuddyMotionGate extends InheritedWidget {
  const BuddyMotionGate({
    super.key,
    required this.mayMove,
    this.holding = false,
    this.sensitive = false,
    required super.child,
  });

  /// Nothing the host knows keeps the buddy still.
  final bool mayMove;

  /// A primary motion is playing elsewhere.
  final bool holding;

  /// A page or a submit is over the buddy.
  final bool sensitive;

  /// The buddy may start a motion here.
  static bool mayMoveOf(BuildContext context) {
    final gate = context.dependOnInheritedWidgetOfExactType<BuddyMotionGate>();
    return MotionGuard.ambientAllowed(context) && (gate?.mayMove ?? true);
  }

  /// A primary motion is playing: a reaction waits (or is dropped).
  static bool holdingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BuddyMotionGate>()?.holding ??
      false;

  @override
  bool updateShouldNotify(BuddyMotionGate oldWidget) =>
      mayMove != oldWidget.mayMove ||
      holding != oldWidget.holding ||
      sensitive != oldWidget.sensitive;
}
